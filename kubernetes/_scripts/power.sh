#!/usr/bin/env bash
# Sleep or wake the cluster by scaling workloads to zero and back.
#
# sleep: records each workload's replica count in an annotation, then scales it to zero.
#        DaemonSets get a nodeSelector that matches no node, which evicts their Pods.
#        The Argo CD application controller goes first so self-heal cannot undo the changes.
# wake:  restores the recorded replica counts and removes the DaemonSet nodeSelector,
#        application controller last; Argo CD then reconciles anything else back to Git.
#
# Usage: power.sh sleep|wake
set -euo pipefail

action="${1:-}"
annotation="eac.mazino2d.dev/replicas-before-sleep"
kinds="deployments.apps,statefulsets.apps,rollouts.argoproj.io"
controller="statefulset.apps/argocd-application-controller"
# Autopilot (GKE Warden) only allows well-known nodeSelector keys, so DaemonSets are pinned to a
# zone that does not exist. Server-side apply keeps the extra field out of Argo CD's diff, so wake
# removes it explicitly; if Git sets the same key, Argo CD self-heal restores it afterwards.
sleep_selector="topology.kubernetes.io/zone"
sleep_zone="sleeping"
# System namespaces are managed (and not billed) by GKE Autopilot.
system_namespaces='^(default|kube-.*|gke-.*|gmp-.*)$'

workload_namespaces() {
  kubectl get namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' |
    grep -vE "$system_namespaces"
}

scale_down() {
  local namespace="$1" workload="$2" replicas
  replicas="$(kubectl -n "$namespace" get "$workload" -o jsonpath='{.spec.replicas}')"
  if [[ -z "$replicas" || "$replicas" == "0" ]]; then
    return
  fi
  kubectl -n "$namespace" annotate --overwrite "$workload" "$annotation=$replicas" >/dev/null
  kubectl -n "$namespace" scale "$workload" --replicas=0
}

sleep_daemonset() {
  local namespace="$1" daemonset="$2"
  kubectl -n "$namespace" patch "$daemonset" --type merge \
    -p "{\"spec\":{\"template\":{\"spec\":{\"nodeSelector\":{\"$sleep_selector\":\"$sleep_zone\"}}}}}"
}

sleep_cluster() {
  scale_down argocd "$controller"

  local namespace workload
  for namespace in $(workload_namespaces | sort | awk '$0 != "argocd"') argocd; do
    for workload in $(kubectl -n "$namespace" get "$kinds" -o name); do
      scale_down "$namespace" "$workload"
    done
    for workload in $(kubectl -n "$namespace" get daemonsets.apps -o name); do
      sleep_daemonset "$namespace" "$workload"
    done
  done
}

sleeping_workloads() {
  # Prints "<namespace> <kind>.<group>/<name> <replicas>" for every sleeping workload.
  kubectl get "$kinds" -A -o json |
    jq -r --arg a "$annotation" '
      .items[]
      | select(.metadata.annotations[$a] != null)
      | "\(.metadata.namespace) \(.kind | ascii_downcase).\(.apiVersion | split("/")[0])/\(.metadata.name) \(.metadata.annotations[$a])"'
}

scale_up() {
  local namespace="$1" workload="$2" replicas="$3"
  kubectl -n "$namespace" scale "$workload" --replicas="$replicas"
  kubectl -n "$namespace" annotate "$workload" "$annotation-" >/dev/null
}

sleeping_daemonsets() {
  # Prints "<namespace> daemonset.apps/<name>" for every DaemonSet carrying the sleep nodeSelector.
  kubectl get daemonsets.apps -A -o json |
    jq -r --arg s "$sleep_selector" --arg z "$sleep_zone" '
      .items[]
      | select(.spec.template.spec.nodeSelector[$s] == $z)
      | "\(.metadata.namespace) daemonset.apps/\(.metadata.name)"'
}

wake_daemonset() {
  local namespace="$1" daemonset="$2"
  # JSON Pointer form of $sleep_selector ("/" escaped as "~1").
  kubectl -n "$namespace" patch "$daemonset" --type json \
    -p '[{"op":"remove","path":"/spec/template/spec/nodeSelector/topology.kubernetes.io~1zone"}]'
}

wake_cluster() {
  local workloads daemonsets namespace workload replicas
  workloads="$(sleeping_workloads)"
  daemonsets="$(sleeping_daemonsets)"

  while read -r namespace workload; do
    [[ -z "$workload" ]] && continue
    wake_daemonset "$namespace" "$workload"
  done <<<"$daemonsets"

  while read -r namespace workload replicas; do
    [[ -z "$workload" || "$workload" == "$controller" ]] && continue
    scale_up "$namespace" "$workload" "$replicas"
  done <<<"$workloads"

  while read -r namespace workload replicas; do
    if [[ "$workload" == "$controller" ]]; then
      scale_up "$namespace" "$workload" "$replicas"
    fi
  done <<<"$workloads"
}

case "$action" in
  sleep) sleep_cluster ;;
  wake) wake_cluster ;;
  *)
    echo "usage: $0 sleep|wake" >&2
    exit 1
    ;;
esac
