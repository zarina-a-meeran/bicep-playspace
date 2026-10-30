FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install required tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    jq \
    ca-certificates \
    tar \
    unzip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Bicep
RUN az bicep install

# Create runner user
RUN useradd -m -s /bin/bash runner

# Download the latest stable GitHub Actions runner
RUN mkdir -p /home/runner/actions-runner \
    && cd /home/runner/actions-runner \
    && RUNNER_VERSION=$(curl -fsSL \
       https://api.github.com/repos/actions/runner/releases/latest \
       | jq -r '.tag_name | ltrimstr("v")') \
    && curl -fL \
       "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz" \
       -o runner.tar.gz \
    && tar xzf runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh \
    && chown -R runner:runner /home/runner

WORKDIR /home/runner/actions-runner

USER runner

# Startup script registers and starts the runner
COPY --chown=runner:runner start.sh /home/runner/start.sh

ENTRYPOINT ["/home/runner/start.sh"]