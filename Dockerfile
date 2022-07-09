FROM 812206152185.dkr.ecr.us-west-2.amazonaws.com/lytectl:lytectl-8f17-master as lytectl
FROM python:3.9-slim-buster

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

COPY in_container.mk /root/Makefile
COPY flytekit.config /root/flytekit.config
