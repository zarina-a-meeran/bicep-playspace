#!/bin/bash
set -euo pipefail

REPO_URL="https://github.com/zarina-a-meeran/bicep-playspace"

echo "Logging in to Azure using managed identity..."

az login --identity \
    --client-id "7999f9c6-5070-4431-abb0-96fd0404aed4"

echo "Retrieving GitHub PAT from Key Vault..."

GITHUB_PAT=$(az keyvault secret show \
    --vault-name kv-runner-learning-2026 \
    --name github-pat \
    --query value \
    --output tsv)

if [ -z "$GITHUB_PAT" ]; then
    echo "ERROR: Could not retrieve GitHub PAT"
    exit 1
fi

cd /home/runner/actions-runner

echo "Requesting a runner registration token..."

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