set shell := ["bash", "-c"]
set positional-arguments

@default:
  just --list --unsorted

git_hash := `git rev-parse --short=4 HEAD`
git_branch := `inp=$(git rev-parse --abbrev-ref HEAD); echo "${inp//\//--}"`

docker_image_name := "latch-base"
docker_registry := "812206152185.dkr.ecr.us-west-2.amazonaws.com"
docker_image_version := git_hash + "-" + git_branch


docker-build:
  docker build -t {{docker_registry}}/{{docker_image_name}}:{{docker_image_version}} -f Dockerfile ..

docker-push:
  docker push {{docker_registry}}/{{docker_image_name}}:{{docker_image_version}}

dbnp: docker-build docker-push
