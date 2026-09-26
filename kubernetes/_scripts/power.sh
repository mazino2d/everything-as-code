#!/usr/bin/env bash
# Sleep or wake the cluster by scaling workloads to zero and back.
#
# sleep: records each workload's replica count in an annotation, then scales it to zero.
#        The Argo CD application controller goes first so self-heal cannot undo the scaling.
# wake:  restores the recorded replica counts, application controller last; Argo CD then
#        reconciles anything else back to Git.
#
# Usage: power.sh sleep|wake
set -euo pipefail

action="${1:-}"
annotation="eac.mazino2d.dev/replicas-before-sleep"
kinds="deployments.apps,statefulsets.apps,rollouts.argoproj.io"
controller="statefulset.apps/argocd-application-controller"
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

sleep_cluster() {
  scale_down argocd "$controller"

  local namespace workload
  for namespace in $(workload_namespaces | sort | awk '$0 != "argocd"') argocd; do
    for workload in $(kubectl -n "$namespace" get "$kinds" -o name); do
      scale_down "$namespace" "$workload"
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

wake_cluster() {
  local workloads namespace workload replicas
  workloads="$(sleeping_workloads)"

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
