---
date: 2025-04-26
title: DevOps Principles — From Theory to Real Infrastructure
---

Modern DevOps is not a role or a toolset — it is a set of principles that guide how teams build, deliver, and operate software reliably at speed. This post walks through seven foundational principles and why each one matters.

---

## 1. Everything as Code (EaC)

The broadest principle: treat every operational concern — infrastructure, configuration, pipelines, policies, even documentation — as versioned, reviewable source code.

When everything is code, you get three things for free:

- **Auditability**: every change has a commit, an author, and a reason
- **Reproducibility**: the same code produces the same result on any machine, at any time
- **Collaboration**: changes go through pull requests, not chat messages or tickets

EaC is the foundation. Every other principle in this list is a specialisation of it.

---

## 2. GitOps

GitOps is the operational model built on top of EaC. The core rule: **git is the single source of truth, and the live state of any system should always converge toward what is declared in the main branch**.

The workflow is pull-request-driven:

```text
Developer → Pull Request → Automated Checks → Merge → Auto-apply
```

There are two key properties that make GitOps work:

**Declarative desired state**: the repo describes *what* the system should look like, not *how* to get there. A GitOps controller (or CI pipeline) continuously reconciles the live system toward that declaration.

**Automated reconciliation**: changes reach the system through the pipeline, never through direct human access. The git history becomes the audit log. Rolling back is just reverting a commit.

!!! note "GitOps vs. traditional CI/CD"
    Traditional CI/CD pushes changes to the system. GitOps pulls: the system watches the repo and applies changes when it diverges from the declared state. The result is self-healing infrastructure — if someone manually modifies the live system, the next reconciliation loop corrects it.

---

## 3. Infrastructure as Code (IaC)

IaC is how EaC is applied specifically to infrastructure. Instead of clicking through a cloud console or running ad-hoc shell scripts, you write code that *declares* what infrastructure should exist. A tool reconciles the real world to match.

Popular tools and their domains:

| Tool | Primary domain |
|---|---|
| Terraform / OpenTofu | Cloud resources, DNS, SaaS APIs |
| Pulumi | Same as Terraform, but in a general-purpose language |
| Ansible | Server configuration and software installation |
| Crossplane | Kubernetes-native cloud resource management |

The benefits compound over time:

- New environments (staging, dev) are created by copying and parameterising existing code
- Drift between environments is visible as a diff, not a support ticket
- Onboarding is reading code, not tribal knowledge transfer

---

## 4. Declarative over Imperative

Declarative and imperative are two ways of expressing the same intent:

| Imperative | Declarative |
|---|---|
| `kubectl create deployment nginx --image=nginx` | `kubectl apply -f nginx-deployment.yaml` |
| Bash script that provisions resources step by step | Terraform that describes the desired end state |
| Manual runbook for setting up a server | Ansible playbook that enforces configuration |

With an imperative approach, you must handle every case: "if the resource already exists, skip; if it's in the wrong state, fix it." With a declarative approach, you describe the goal and the tool figures out the diff.

Declarative systems are more predictable because the same manifest applied twice produces the same result — they are **idempotent**. This matters in automation: retries are safe.

!!! tip "Where imperative is still useful"
    Declarative tools often have escape hatches for one-off operations — `kubectl exec`, `terraform taint`, a `null_resource` in Terraform. These are appropriate for debugging and incident response. They should not be used for routine changes.

---

## 5. Immutable Infrastructure

Traditional infrastructure is treated like a **pet**: named, cared for, patched in place over years. Problems are fixed by logging in and changing things.

Immutable infrastructure treats servers like **cattle**: when something needs to change, you build a new instance from a known-good base and replace the old one. You never modify a running system.

The practical implications:

- No SSH access for configuration changes — everything goes through the pipeline
- Server images (AMIs, container images) are versioned and tested before deployment
- Rollback means deploying the previous image, not undoing manual changes

The deeper benefit is eliminating **configuration drift** — the slow accumulation of undocumented changes that makes two servers that were once identical behave differently over time. Drift is one of the most common root causes of hard-to-reproduce incidents.

Containers and container images make this pattern accessible at the application layer. Spot and preemptible cloud instances push it to the infrastructure layer: a VM that can be terminated and replaced at any time *must* be designed to be stateless and reproducible.

---

## 6. Shift Left

"Shift left" means moving validation and testing earlier in the development process — closer to when code is written, not after it is deployed.

The name refers to shifting checks leftward on the delivery timeline:

```text
Write → [✓ check here] → PR → Merge → Deploy → Production
```

In practice this means:

- **Linting and static analysis** run on every commit or PR, not in a nightly job
- **Security scanning** happens on the branch, before it reaches main
- **Infrastructure plans** (`terraform plan`) are generated and reviewed as part of the PR, so reviewers see what will change before approving
- **Dry-run validation** (Helm lint, Kustomize build, schema validation) catches broken configs before they are applied to a live cluster

The economics of shift left are straightforward: a bug caught in a PR comment takes minutes to fix. The same bug caught in production takes hours, involves more people, and may have already caused user impact.

Required status checks on the main branch enforce this pattern. Nothing merges unless the checks pass.

---

## 7. Cost-conscious Engineering

Cloud infrastructure costs grow in two ways: planned growth, and unnoticed waste. Cost-conscious engineering means making deliberate tradeoffs between capability and cost, and being explicit about them.

Common patterns:

**Right-size first, scale later.** Start with the smallest instance type that meets the actual requirement. Overprovisioning "just in case" is the norm, but it means paying for idle capacity indefinitely.

**Use spot/preemptible instances for fault-tolerant workloads.** Spot instances can be 60–90% cheaper than on-demand. The constraint — they can be terminated at any time — is only a problem for workloads that do not tolerate interruption. Stateless services, batch jobs, and CI runners are good candidates.

**Prefer managed services only when the operational savings justify the cost.** A managed Kubernetes service (GKE, EKS, AKS) saves significant operational effort. A lightweight distribution (K3S, k0s) on a single VM costs a fraction of the price for workloads that do not need the managed service's features.

**Make costs visible.** Tag resources by team, environment, and purpose. Cost anomalies are much easier to catch when they appear in a dashboard than when they appear on a monthly bill.

!!! note "The tradeoff is real"
    Every cost optimisation trades something. Spot instances trade availability guarantees. K3S trades managed upgrades and multi-master HA. Free-tier DNS trades SLAs. The goal is not minimum cost — it is minimum cost *for your actual requirements*. Name the tradeoff explicitly so it can be revisited when requirements change.

---

## How These Principles Relate

These seven principles are not independent — they reinforce each other:

- **EaC** is the foundation; everything else is built on it
- **GitOps** gives EaC its operational workflow
- **IaC** is the concrete application of EaC to infrastructure
- **Declarative configuration** is what makes IaC and GitOps tractable at scale
- **Immutable infrastructure** eliminates the state that makes declarative configuration hard to reason about
- **Shift left** catches mistakes before they reach the immutable system
- **Cost-conscious engineering** ensures the whole thing remains sustainable

Understanding these relationships helps when deciding which principle to apply to a specific problem — and which tradeoffs to accept.
