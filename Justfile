set shell := ["bash", "-c"]
set positional-arguments

@default:
  just --list --unsorted

git_hash := `git rev-parse --short=4 HEAD`
git_branch := `inp=$(git rev-parse --abbrev-ref HEAD); echo "${inp//\//--}"`

docker_image_name := "latch-base"
docker_image_name_cuda := "latch-base-cuda"
docker_image_name_opencl := "latch-base-opencl"

docker_image_name_nextflow := "latch-base-nextflow"
docker_image_version_nextflow := "v1.1.1"

docker_registry := "812206152185.dkr.ecr.us-west-2.amazonaws.com"
docker_image_version := git_hash + "-" + git_branch


docker-build:
  docker build -t {{docker_registry}}/{{docker_image_name}}:{{docker_image_version}} -f Dockerfile .

docker-push:
  docker push {{docker_registry}}/{{docker_image_name}}:{{docker_image_version}}

dbnp: docker-build docker-push

docker-build-cuda:
  docker build -t {{docker_registry}}/{{docker_image_name_cuda}}:{{docker_image_version}} -f Dockerfile.cuda .

docker-push-cuda:
  docker push {{docker_registry}}/{{docker_image_name_cuda}}:{{docker_image_version}}

dbnp-cuda: docker-build-cuda docker-push-cuda

docker-build-opencl:
  docker build -t {{docker_registry}}/{{docker_image_name_opencl}}:{{docker_image_version}} -f Dockerfile.opencl .

docker-push-opencl:
  docker push {{docker_registry}}/{{docker_image_name_opencl}}:{{docker_image_version}}

docker-build-nextflow:
  docker build -t {{docker_registry}}/{{docker_image_name_nextflow}}:{{docker_image_version_nextflow}} --build-arg="nextflow_version={{docker_image_version_nextflow}}" -f Dockerfile.nextflow .

docker-push-nextflow:
  docker push {{docker_registry}}/{{docker_image_name_nextflow}}:{{docker_image_version_nextflow}}

dbnp-nextflow: docker-build-nextflow docker-push-nextflow

dbnp-opencl: docker-build-opencl docker-push-opencl

dbnp-all: dbnp-cuda dbnp-opencl docker-push
