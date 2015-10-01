#!/usr/bin/env bash



weave_bin="/usr/local/bin/weave"

WEAVE_PROXY_PORT=12375
WEAVE_NETWORK_DOMAIN="hadoop.docker.local."

if [[ -n ${DOCKER_HOST} ]]; then
    docker_host_address=$(echo ${DOCKER_HOST} | sed 's/tcp:\/\///' | cut -d':' -f 1)
fi


${weave_bin} launch-router --dns-domain=${WEAVE_NETWORK_DOMAIN}

${weave_bin} launch-proxy --with-dns -H tcp://${docker_host_address}:${WEAVE_PROXY_PORT}


