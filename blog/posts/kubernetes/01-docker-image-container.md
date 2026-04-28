---
date: 2025-04-26
title: Docker Recap — Images, Containers & Packaging Apps Right
---

Before Kubernetes makes sense, containers must make sense. This post covers Docker fundamentals — specifically the mental model around images, layers, and what "packaging an app correctly" actually means.

---

## Containers vs Virtual Machines

A virtual machine emulates an entire computer: its own kernel, OS, drivers, and userland. A container shares the host kernel and isolates only the process and its dependencies.

```text
VM:        [App] [Libs] [OS] [Kernel] │ [App] [Libs] [OS] [Kernel]
           ─────────────────────────  │ ─────────────────────────
                  Hypervisor                  Hypervisor

Container: [App] [Libs] │ [App] [Libs] │ [App] [Libs]
           ─────────────────────────────────────────
                       Shared Kernel (host)
```

Containers start in milliseconds, use megabytes instead of gigabytes, and pack dozens onto a single machine. The tradeoff: they share the kernel, so kernel-level isolation is weaker than a VM.

---

## Images and Layers

A Docker image is a read-only stack of filesystem layers. Each instruction in a `Dockerfile` adds a layer.

```dockerfile
FROM ubuntu:22.04        # base layer (100MB)
RUN apt-get install ...  # new layer (deps added)
COPY app /app            # new layer (your code)
CMD ["./app"]            # metadata, no new layer
```

Layers are **content-addressed** and **cached**. If the base layer hasn't changed, Docker reuses it from cache on the next build. This makes rebuilds fast — as long as you order instructions from least to most frequently changed.

!!! tip "Layer cache strategy"
    Put `COPY requirements.txt` and `RUN pip install` *before* `COPY . .`. Dependencies change less often than application code. Breaking the cache at the dependency layer forces a full reinstall on every code change.

A running container adds a thin **writable layer** on top of the image layers. When the container is deleted, that layer is gone. This is why stateful data must live in volumes, not the container filesystem.

---

## What Makes a Good Dockerfile

**Use a small base image.** `ubuntu:22.04` is 78MB; `python:3.12-slim` is 48MB; `python:3.12-alpine` is 22MB; `gcr.io/distroless/python3` has no shell at all. Smaller images mean faster pulls, smaller attack surface, and less to patch.

**Use multi-stage builds** to separate the build environment from the runtime environment:

```dockerfile
# Stage 1: build
FROM golang:1.22 AS builder
WORKDIR /app
COPY . .
RUN go build -o server .

# Stage 2: runtime (no compiler, no source code)
FROM gcr.io/distroless/static
COPY --from=builder /app/server /server
ENTRYPOINT ["/server"]
```

The final image contains only the compiled binary — not the Go toolchain or source code.

**Run as a non-root user.** Most base images run as root by default. This is a security risk: a container escape with root privileges is far more damaging than one with a regular user.

```dockerfile
RUN adduser --disabled-password appuser
USER appuser
```

**Be explicit with tags.** `FROM python:latest` will silently upgrade when the image is rebuilt. Pin to a specific version: `FROM python:3.12.3-slim`.

---

## The Container Lifecycle

```text
docker build  →  Image (stored in registry)
docker pull   →  Image (local)
docker run    →  Container (running process)
docker stop   →  Container (stopped)
docker rm     →  Container (deleted)
```

Key commands for day-to-day work:

```bash
docker build -t myapp:1.0 .          # build image from current directory
docker run -p 8080:8080 myapp:1.0    # run, map host port 8080 to container 8080
docker logs <container-id>           # tail container logs
docker exec -it <id> sh              # open a shell inside a running container
docker images                        # list local images
docker ps -a                         # list all containers (including stopped)
```

---

## What Containers Don't Solve

A single container on a single machine is manageable. The problems appear at scale:

- Which machine should this container run on?
- What happens when the container crashes?
- How do you update 50 containers with zero downtime?
- How do running containers find each other?

These are orchestration problems. That is what Kubernetes is for.
