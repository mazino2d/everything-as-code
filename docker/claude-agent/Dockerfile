FROM debian:bookworm-slim

ARG TARGETARCH=amd64
ARG CLAUDE_CODE_VERSION=stable
ARG KUBECTL_VERSION=v1.34.1
ARG HELM_VERSION=v3.19.0
ARG KUSTOMIZE_VERSION=v5.8.1
ARG TERRAFORM_VERSION=1.14.8

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash ca-certificates curl git gnupg jq make unzip bsdutils procps \
  && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    -o /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=${TARGETARCH} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends gh \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" -o /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl \
  && curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-${TARGETARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin --strip-components=1 "linux-${TARGETARCH}/helm" \
  && curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_${TARGETARCH}.tar.gz" \
    | tar -xz -C /usr/local/bin kustomize \
  && curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TARGETARCH}.zip" -o /tmp/terraform.zip \
  && unzip -q /tmp/terraform.zip terraform -d /usr/local/bin \
  && rm /tmp/terraform.zip

# The native installer writes into $HOME, which is a PVC at runtime, so copy
# the self-contained binary onto the image PATH.
RUN curl -fsSL https://claude.ai/install.sh | bash -s "${CLAUDE_CODE_VERSION}" \
  && cp -L /root/.local/bin/claude /usr/local/bin/claude \
  && rm -rf /root/.local /root/.claude /root/.claude.json

RUN useradd --create-home --uid 1000 --shell /bin/bash agent

COPY managed-settings.json /etc/claude-code/managed-settings.json
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENV DISABLE_AUTOUPDATER=1 \
    HOME=/home/agent \
    WORKSPACE=/home/agent/workspace/everything-as-code \
    REPO=mazino2d/everything-as-code

USER agent
WORKDIR /home/agent

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
