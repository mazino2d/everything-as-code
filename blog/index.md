# Everything as Code

A personal learning journal for DevOps — each post explains a principle or concept, grounded in real infrastructure.

---

## Mental Models for DevOps

| # | Title | Topics |
| - | ----- | ------ |
| 01 | [The Three Ways](posts/devops/01-devops-principles.md) | Flow, Feedback, Continual Learning |
| 02 | [DORA Metrics](posts/devops/02-dora-metrics.md) | Deployment Frequency, Lead Time, Change Failure Rate, MTTR |
| 03 | [Observability](posts/devops/03-observability.md) | Monitoring vs Observability, Logs, Metrics, Traces, Cardinality |
| 04 | [Blameless Postmortem](posts/devops/04-blameless-postmortem.md) | Blame Culture, Swiss Cheese Model, Contributing Factors, Just Culture |

---

## Kubernetes: From Zero to Production

Posts covering Kubernetes from first principles to production tooling.

| Chapter | Posts | Topics |
| ------- | ----- | ------ |
| [1 · Container Fundamentals](posts/kubernetes/01-docker-image-container.md) | 3 | Docker, Why K8s, Local Lab |
| [2 · Core Objects](posts/kubernetes/04-kubernetes-pods.md) | 5 | Pod, Deployment, StatefulSet, DaemonSet, Job |
| [3 · Networking](posts/kubernetes/09-kubernetes-service.md) | 2 | Service, Ingress |
| [4 · Storage](posts/kubernetes/11-kubernetes-configmap-secret.md) | 3 | ConfigMap & Secret, Volumes, PV & PVC |
| [5 · Resource Management](posts/kubernetes/14-kubernetes-resource-limits.md) | 3 | Limits, Labels, Scheduling |
| [6 · Ecosystem](posts/kubernetes/17-kubernetes-helm.md) | 3 | Helm, Kustomize, Argo CD |

---

## Terraform: Managing Infrastructure as Code

11 posts on how Terraform thinks, how state works, and how to structure IaC at scale.

| Chapter | Posts | Topics |
| ------- | ----- | ------ |
| [1 · The Mental Model](posts/terraform/01-terraform-state-plan-apply.md) | 3 | State/Plan/Apply, Providers, HCL |
| [2 · State](posts/terraform/04-terraform-state.md) | 3 | State, Remote Backends, Drift & Import |
| [3 · Modules](posts/terraform/07-terraform-modules.md) | 2 | Modules, Module Design |
| [4 · Workflow](posts/terraform/09-terraform-workflow.md) | 3 | GitOps Workflow, Environments, Secrets |
