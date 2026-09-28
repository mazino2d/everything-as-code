#!/usr/bin/env bash
# Starts a Claude Code Remote Control server inside the repo checkout.
# Expects GH_TOKEN and TF_API_TOKEN in the environment; Claude credentials
# live on the PVC mounted at $HOME (see kubernetes/_docs/claude-agent.md).
set -euo pipefail

log() { echo "[entrypoint] $*"; }

# GitHub: git over HTTPS authenticated by gh, commits authored as mazino2d.
gh auth setup-git
git config --global user.name "${GIT_AUTHOR_NAME:-mazino2d}"
git config --global user.email "${GIT_AUTHOR_EMAIL:-mazino2d@users.noreply.github.com}"
git config --global pull.ff only

if [ ! -d "${WORKSPACE}/.git" ]; then
  log "cloning ${REPO} into ${WORKSPACE}"
  mkdir -p "$(dirname "${WORKSPACE}")"
  gh repo clone "${REPO}" "${WORKSPACE}"
else
  log "fetching ${REPO}"
  git -C "${WORKSPACE}" fetch --prune origin
fi

# Terraform Cloud: plan-only team token.
mkdir -p "${HOME}/.terraform.d"
jq -n --arg t "${TF_API_TOKEN}" '{credentials: {"app.terraform.io": {token: $t}}}' \
  > "${HOME}/.terraform.d/credentials.tfrc.json"
chmod 600 "${HOME}/.terraform.d/credentials.tfrc.json"

# Pre-accept the workspace trust dialog for the checkout.
config="${HOME}/.claude.json"
[ -f "${config}" ] || echo '{}' > "${config}"
tmp="$(mktemp)"
jq --arg p "${WORKSPACE}" '.projects[$p].hasTrustDialogAccepted = true' "${config}" > "${tmp}"
mv "${tmp}" "${config}"

cd "${WORKSPACE}"

# Remote Control needs a full-scope claude.ai login, done once by hand.
until claude auth status >/dev/null 2>&1; do
  log "not signed in; run: kubectl -n platform exec -it ${HOSTNAME} -- claude auth login"
  sleep 60
done

# Server mode expects a TTY; `script` provides one. The leading "y" answers the
# one-time "Enable Remote Control?" confirmation and is ignored afterwards.
while true; do
  log "starting remote-control server"
  { echo y; sleep infinity; } | script -qfec \
    "claude remote-control --name '${SESSION_NAME:-eac-agent}' --permission-mode '${PERMISSION_MODE:-acceptEdits}'" \
    /dev/null || true
  log "remote-control exited; restarting in 10s"
  sleep 10
done
