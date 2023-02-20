set shell := ["bash", "-c"]
set positional-arguments

@default:
  just --list --unsorted

git_hash := `git rev-parse --short=4 HEAD`
git_branch := `inp=$(git rev-parse --abbrev-ref HEAD); echo "${inp//\//--}"`

docker_image_name := "latch-base"
docker_image_name_cuda := "latch-base-cuda"
docker_image_name_opencl := "latch-base-opencl"
docker_image_name_docker := "latch-base-docker"

docker_registry := "812206152185.dkr.ecr.us-west-2.amazonaws.com"
docker_image_version := git_hash + "-" + git_branch


docker-build:
  docker build -t {{docker_registry}}/{{docker_image_name}}:{{docker_image_version}} -f Dockerfile .

docker-push:
  docker push {{docker_registry}}/{{docker_image_name}}:{{docker_image_version}}

dbnp: docker-build docker-push

docker-build-cuda:
  docker build -t {{docker_registry}}/{{docker_image_name_cuda}}:{{docker_image_version}} -f Dockerfile-cuda .

docker-push-cuda:
  docker push {{docker_registry}}/{{docker_image_name_cuda}}:{{docker_image_version}}

dbnp-cuda: docker-build-cuda docker-push-cuda

docker-build-opencl:
  docker build -t {{docker_registry}}/{{docker_image_name_opencl}}:{{docker_image_version}} -f Dockerfile-opencl .

docker-push-opencl:
  docker push {{docker_registry}}/{{docker_image_name_opencl}}:{{docker_image_version}}

dbnp-opencl: docker-build-opencl docker-push-opencl

docker-build-docker:
  docker build --build-arg latch_base_tag={{docker_image_version}} -t {{docker_registry}}/{{docker_image_name_docker}}:{{docker_image_version}} -f Dockerfile-docker .

docker-push-docker:
  docker push {{docker_registry}}/{{docker_image_name_docker}}:{{docker_image_version}}

dbnp-docker: docker-build docker-build-docker docker-push-docker

dbnp-all: dbnp-cuda dbnp-opencl dbnp-docker docker-push
