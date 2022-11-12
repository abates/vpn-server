#!/bin/bash

IMAGE="abates314/vpn-server"

case $1 in
  local)
    docker build --build-arg TARGETARCH=amd64 --tag $IMAGE .
    ;;
  remote)
    echo "Building Docker images"
    docker buildx build --push --platform linux/arm,linux/386,linux/amd64 -t $IMAGE .
    #docker buildx build --push --platform linux/x86_64 -t $IMAGE .
    ;;
esac
