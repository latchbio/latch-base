#!/usr/bin/env bash
set -o errexit

if (! curl --silent --unix-socket /var/run/docker.sock http/_ping ); then
  dockerd > /var/log/dockerd.log 2>&1 &

  while (! curl --silent --unix-socket /var/run/docker.sock http/_ping ); do
    echo "Waiting for Docker to launch..."
    sleep 1
  done
fi

exec _docker "$@"
