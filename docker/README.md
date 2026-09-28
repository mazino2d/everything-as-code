# Container images

Each subdirectory with a `Dockerfile` is an image, built by
`.github/workflows/docker-build.yml`:

```
docker/<name>/Dockerfile  →  ghcr.io/mazino2d/<name>
```

- **Pull requests** touching `docker/<name>/` build the image without pushing.
- **Pushes to `main`** build and push `sha-<short-sha>` and `latest`.
- **Manual runs** (`workflow_dispatch`) rebuild all images, or the space-separated names given in `images`.
- Changing the workflow itself rebuilds every image.

The build context is the image directory. Builds target `linux/amd64` unless
`docker/<name>/.platforms` lists others (e.g. `linux/amd64,linux/arm64`).

Adding an image needs no workflow change: create `docker/<name>/Dockerfile`.
Reference it from Kubernetes with an immutable tag, e.g.
`ghcr.io/mazino2d/<name>:sha-abc1234`.

| Image | Purpose |
|-------|---------|
| `claude-agent` | Claude Code Remote Control agent with `gh`, `kubectl`, `terraform` (`kubernetes/_docs/claude-agent.md`) |
