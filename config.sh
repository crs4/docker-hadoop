#!/usr/bin/env bash

# default user infos
export DEFAULT_USER="hduser"
export DEFAULT_USER_GROUP="hduser"
export DEFAULT_USER_PASSWORD="hadoop"

# compose project name
DOCKER_COMPOSE_PROJECT="" #"${HADOOP_VERSION}"

# set the working dir
export WORKING_DIR="$(pwd)"
export SHARED_DIRS_BASE="${WORKING_DIR}/../docker-hadoop-sharing"

# Set shared NFS folder
SHARING_MOUNT_POINT=/sharing

# set domain & environment
export DOCKER_DOMAIN="docker"
export DOCKER_ENVIRONMENT="hadoop"
export DOCKER_CONTAINER_DOMAIN="${DOCKER_ENVIRONMENT}.${DOCKER_DOMAIN}.local"

# set default DNS for containers
export DOCKER_ENVIRONMENT_DNS="172.17.42.1"