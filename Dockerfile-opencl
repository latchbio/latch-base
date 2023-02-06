FROM 812206152185.dkr.ecr.us-west-2.amazonaws.com/lytectl:lytectl-8f17-master as lytectl
FROM nvidia/opencl:runtime-ubuntu18.04

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

RUN apt-get install -y software-properties-common &&\
    add-apt-repository -y ppa:deadsnakes/ppa &&\
    apt-get install -y python3.8 python3-pip python3.8-distutils

# Install the AWS cli separately to prevent issues with boto being written over
RUN python3 -m pip install awscli boto3

RUN apt-get update && apt-get install -y curl
# s5 gives better file upload and download performance than awscli.
RUN curl -L https://github.com/peak/s5cmd/releases/download/v2.0.0/s5cmd_2.0.0_Linux-64bit.tar.gz -o s5cmd_2.0.0_Linux-64bit.tar.gz &&\
    tar -xzvf s5cmd_2.0.0_Linux-64bit.tar.gz &&\
    mv s5cmd /bin/ &&\ 
    rm CHANGELOG.md LICENSE README.md

COPY in_container.mk /root/Makefile
COPY flytekit.config /root
