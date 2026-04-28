---
date: 2025-04-26
title: Docker Recap — Images, Containers & Packaging Apps Right
---

Before Kubernetes makes sense, containers must make sense. This post focuses on the core mental models behind Docker — what a container actually is, how images work, and what it means to package an application correctly.

---

## The Problem Docker Solves

The classic "works on my machine" problem comes from environment mismatch: different OS versions, different library versions, different runtime configs between dev, staging, and production.

Docker solves this by packaging the application together with everything it needs to run — libraries, config, runtime — into a single portable unit. That unit behaves identically regardless of where it runs.

---

## Containers vs Virtual Machines

A **virtual machine** emulates an entire computer. It has its own kernel, its own OS, its own drivers. The hypervisor sits between the hardware and each VM, translating instructions. This gives strong isolation — each VM is a completely separate machine — but it's heavy. A VM takes minutes to boot and consumes gigabytes of memory.

A **container** takes a different approach. Instead of emulating hardware, it uses Linux kernel features (`namespaces` and `cgroups`) to isolate a process directly on the host. Containers share the host kernel; they just can't see each other's filesystems, networks, or process trees.

| | Virtual Machine | Container |
|---|---|---|
| **Kernel** | Each VM has its own | Shared with host |
| **Isolation** | Full OS boundary | Namespaces + cgroups |
| **Startup** | Minutes | Milliseconds |
| **Footprint** | Gigabytes | Megabytes |

The tradeoff for that efficiency: shared kernel means weaker isolation. A kernel exploit can potentially break out of a container; it cannot break out of a properly configured VM.

---

## Images and Layers

A Docker **image** is a read-only, portable snapshot of a filesystem — the app, its dependencies, config files, everything except the kernel. It is built from a `Dockerfile`, a series of instructions that each produce a filesystem layer.

Layers are **content-addressed** and **cached**. If a layer hasn't changed since the last build, Docker reuses it from cache. This is why layer ordering matters: put stable things (base OS, dependencies) at the top of the `Dockerfile` and frequently-changing things (application code) at the bottom. A cache miss at layer N forces every subsequent layer to rebuild from scratch.

A running **container** is an image plus a thin writable layer on top. Anything written inside the container (logs, temp files, database state) goes into that writable layer. When the container is deleted, the writable layer is gone too. Persistent data must be stored in volumes — external storage mounted into the container — not on the container filesystem.

The key mental model: **image is a template, container is an instance**. The same image can spawn many containers simultaneously. Containers are ephemeral by design.

---

## The Registry

Images are distributed via a **registry** — a content-addressed store of image layers. Docker Hub is the public default. Private registries (GCR, ECR, GHCR) are common in production.

When you run `docker pull`, Docker fetches only the layers it doesn't already have locally. When you `docker push`, it uploads only the layers the registry doesn't already have. This delta transfer makes image distribution efficient.

Image names encode the registry, repository, and tag: `registry/repository:tag`. The tag is mutable — `latest` can point to different images at different times. For reproducibility, pin to an immutable digest: `image@sha256:abc123...`.

---

## What Makes a Good Image

The goal when building an image is to make it **small, reproducible, and least-privileged**.

**Small base image.** The base image is the starting layer. A full Ubuntu image is ~78MB before your app is even added. Slim and Alpine variants strip out package managers, shells, and other tooling you don't need at runtime — bringing the base down to 20–50MB. Distroless images go further: no shell, no package manager, only the runtime libraries the app actually needs. Smaller images pull faster, have a smaller attack surface, and are cheaper to scan.

**Multi-stage builds.** Build tools (compilers, test runners, build-time dependencies) should never end up in the final image. A multi-stage build uses one image to build the artifact and a separate, minimal image for the final output. Only the compiled binary or built assets get copied across — the toolchain stays behind. The result is an image that contains exactly what's needed to run the app, nothing more.

**Non-root user.** Container processes run as root by default. If an attacker exploits the running process, they have root inside the container. While container root is not the same as host root, it significantly raises the blast radius of a container escape. The fix is simple: create a dedicated user in the image and switch to it before the entrypoint.

**Pinned tags.** `FROM python:latest` is a moving target. The next build might pull a different version, silently changing behavior. Pin to a specific version tag, or better, to an immutable digest. This makes builds reproducible and prevents surprise upgrades.

---

## The Container Lifecycle

```text
Dockerfile  →  docker build  →  Image
Image       →  docker push   →  Registry
Registry    →  docker pull   →  Local image
Local image →  docker run    →  Container (running process)
Container   →  docker stop   →  Container (stopped)
Container   →  docker rm     →  Container (deleted)
```

The image persists on disk until explicitly removed. The container is transient — it runs, stops, and gets deleted. Its writable layer disappears with it. This cycle is intentional: containers should be stateless and replaceable.

---

## What Containers Don't Solve

A single container on a single machine is manageable. The problems appear at scale:

- Which machine should this container run on?
- What happens when the container crashes?
- How do you roll out an update to 50 containers with zero downtime?
- How do running containers discover and talk to each other?

These are orchestration problems. That is what Kubernetes is for.
