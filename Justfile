set shell := ["bash", "-c"]
set positional-arguments

@default:
  just --list --unsorted

git_hash := `git rev-parse --short=4 HEAD`
git_branch := `inp=$(git rev-parse --abbrev-ref HEAD); echo "${inp//\//--}"`

docker_image_name := "latch-base"
docker_image_name_cuda := "latch-base-cuda"
docker_image_name_cuda12 := "latch-base-cuda12"
docker_image_name_opencl := "latch-base-opencl"

nextflow_version := env_var_or_default("NEXTFLOW_VERSION", "25.04.8")
nextflow_latch_version := env_var_or_default("LATCH_NEXTFLOW_VERSION", "v1.1.5")

docker_image_name_nextflow := "latch-base-nextflow" + "/" + nextflow_version

docker_registry := "812206152185.dkr.ecr.us-west-2.amazonaws.com"
docker_image_version := git_hash + "-" + git_branch

platform := "linux/amd64"

@docker-login:
  aws ecr get-login-password --region us-west-2 | \
    docker login --username AWS --password-stdin {{docker_registry}}

docker-build:
  docker build --platform linux/amd64 -t {{docker_registry}}/{{docker_image_name}}:{{docker_image_version}} -f Dockerfile .

docker-push:
  docker push {{docker_registry}}/{{docker_image_name}}:{{docker_image_version}}

dbnp: docker-build docker-push

docker-build-cuda:
  docker build --platform linux/amd64 -t {{docker_registry}}/{{docker_image_name_cuda}}:{{docker_image_version}} -f Dockerfile.cuda .

docker-push-cuda:
  docker push {{docker_registry}}/{{docker_image_name_cuda}}:{{docker_image_version}}

dbnp-cuda: docker-build-cuda docker-push-cuda

docker-build-cuda12:
  docker build --platform={{platform}} -t {{docker_registry}}/{{docker_image_name_cuda12}}:{{docker_image_version}} -f Dockerfile.cuda12 .

docker-push-cuda12:
  docker push {{docker_registry}}/{{docker_image_name_cuda12}}:{{docker_image_version}}

dbnp-cuda12: docker-build-cuda12 docker-push-cuda12

docker-build-opencl:
  docker build --platform linux/amd64 -t {{docker_registry}}/{{docker_image_name_opencl}}:{{docker_image_version}} -f Dockerfile.opencl .

docker-push-opencl:
  docker push {{docker_registry}}/{{docker_image_name_opencl}}:{{docker_image_version}}

dbnp-opencl: docker-build-opencl docker-push-opencl

docker-build-nextflow:
  docker build \
    --platform linux/amd64 \
    -t {{docker_registry}}/{{docker_image_name_nextflow}}:{{nextflow_latch_version}} \
    --build-arg="nextflow_version={{nextflow_version}}" \
    --build-arg="nextflow_latch_version={{nextflow_latch_version}}" \
    -f Dockerfile.nextflow .

docker-push-nextflow:
  docker push {{docker_registry}}/{{docker_image_name_nextflow}}:{{nextflow_latch_version}}

dbnp-nextflow: docker-build-nextflow docker-push-nextflow

dbnp-all: dbnp-cuda dbnp-cuda12 dbnp-opencl docker-push
