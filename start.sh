#!/bin/bash
set -euo pipefail

# GitHub repository
REPO_URL="https://github.com/zarina-a-meeran/bicep-playspace"

# Check that the GitHub access token is available
if [ -z "${GITHUB_PAT:-}" ]; then
    echo "ERROR: GITHUB_PAT environment variable is missing"
    exit 1
fi

cd /home/runner/actions-runner

echo "Requesting a runner registration token..."

# Request a short-lived registration token from GitHub
RUNNER_TOKEN=$(curl -fsSL -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer ${GITHUB_PAT}" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/zarina-a-meeran/bicep-playspace/actions/runners/registration-token" \
    | jq -r '.token')

if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" = "null" ]; then
    echo "ERROR: Could not obtain runner registration token"
    exit 1
fi

echo "Registering runner with GitHub..."

./config.sh \
    --url "$REPO_URL" \
    --token "$RUNNER_TOKEN" \
    --name "aca-runner-$(hostname)" \
    --labels "aca,linux,x64" \
    --work "_work" \
    --unattended \
    --ephemeral

unset RUNNER_TOKEN
unset GITHUB_PAT

echo "Starting GitHub Actions runner..."

exec ./run.sh