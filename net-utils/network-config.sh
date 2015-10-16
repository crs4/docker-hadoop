#!/usr/bin/env bash

# Executable paths
export WEAVE_BIN="/usr/local/bin/weave"
export WEAVE_SCOPE_BIN="/usr/local/bin/scope"

# Default WEAVE Proxy Port
export WEAVE_PROXY_PORT=12375

# Default Weave Network Domain
export WEAVE_NETWORK_DOMAIN="hadoop.docker.local."

# Default SWARM Manager Port
export SWARM_MANAGER_PORT="3377"

# Sets DOCKER_HOST Ip and Port
if [[ -n ${DOCKER_HOST} ]]; then
    docker_host_info=($(echo ${DOCKER_HOST} | sed 's/tcp:\/\///' | tr ':' ' '))
    export DOCKER_HOST_IP=${docker_host_info[0]}
    export DOCKER_HOST_PORT=${docker_host_info[1]}
fi
