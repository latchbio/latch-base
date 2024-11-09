# syntax = docker/dockerfile:1.4.1

FROM 812206152185.dkr.ecr.us-west-2.amazonaws.com/lytectl:lytectl-8f17-master as lytectl
FROM python:3.11-slim-bookworm

shell [ \
    "/usr/bin/env", "bash", \
    "-o", "errexit", \
    "-o", "pipefail", \
    "-o", "nounset", \
    "-o", "verbose", \
    "-o", "errtrace", \
    "-O", "inherit_errexit", \
    "-O", "shift_verbose", \
    "-c" \
]

# Grab custom flytectl from builder image
COPY --from=lytectl /artifacts/flytectl /bin/flytectl
RUN /bin/flytectl --help

WORKDIR /root
ENV VENV /opt/venv
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONPATH /root
ENV LATCH_AUTHENTICATION_ENDPOINT https://nucleus.latch.bio

RUN apt-get update && apt-get install -y libsm6 libxext6 libxrender-dev build-essential procps rsync openssh-server

# Install the AWS cli separately to prevent issues with boto being written over
RUN pip3 install awscli boto3
ENV AWS_USE_DUALSTACK_ENDPOINT true

RUN apt-get update && apt-get install -y curl
# s5 gives better file upload and download performance than awscli.
RUN curl -L https://github.com/peak/s5cmd/releases/download/v2.0.0/s5cmd_2.0.0_Linux-64bit.tar.gz -o s5cmd_2.0.0_Linux-64bit.tar.gz &&\
    tar -xzvf s5cmd_2.0.0_Linux-64bit.tar.gz &&\
    mv s5cmd /bin/ &&\
    rm CHANGELOG.md LICENSE README.md

COPY in_container.mk /root/Makefile
COPY flytekit.config /root/flytekit.config

# Docker support

run <<'DOCKER'
    apt-get update
    apt-get install --no-install-recommends -y ca-certificates

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    arch=$(dpkg --print-architecture)
    codename=$(. /etc/os-release && echo "$VERSION_CODENAME")

    echo \
        "deb [arch=$(echo $arch) signed-by=/etc/apt/keyrings/docker.asc] \
            https://download.docker.com/linux/debian \
            $(echo $codename) \
            stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install --no-install-recommends -y \
        docker-ce=5:26.1.0-1~debian.12~bookworm \
        docker-ce-cli=5:26.1.0-1~debian.12~bookworm \
        containerd.io
DOCKER

# wrapper script to ensure that docker is running
RUN mv /usr/bin/docker /usr/bin/_docker
COPY scripts/docker.sh /usr/bin/docker
RUN chmod u+x /usr/bin/docker
