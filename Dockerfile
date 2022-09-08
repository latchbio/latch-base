FROM 812206152185.dkr.ecr.us-west-2.amazonaws.com/lytectl:lytectl-8f17-master as lytectl
FROM python:3.9-slim-bullseye

# Grab custom flytectl from builder image
COPY --from=lytectl /artifacts/flytectl /bin/flytectl
RUN /bin/flytectl --help

WORKDIR /root
ENV VENV /opt/venv
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONPATH /root
ENV LATCH_AUTHENTICATION_ENDPOINT https://nucleus.latch.bio

RUN apt-get update && apt-get install -y libsm6 libxext6 libxrender-dev build-essential procps

# Install the AWS cli separately to prevent issues with boto being written over
RUN pip3 install awscli boto3

RUN apt-get update && apt-get install -y curl
# s5 gives better file upload and download performance than awscli.
RUN curl -L https://github.com/peak/s5cmd/releases/download/v2.0.0/s5cmd_2.0.0_Linux-64bit.tar.gz -o s5cmd_2.0.0_Linux-64bit.tar.gz &&\
    tar -xzvf s5cmd_2.0.0_Linux-64bit.tar.gz &&\
    mv s5cmd /bin/ &&\ 
    rm CHANGELOG.md LICENSE README.md

COPY in_container.mk /root/Makefile
COPY flytekit.config /root/flytekit.config
