#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "You have to specify the cluster configuration file!!!"
    exit -1
fi

FILENAME=$1

USER=root
if [[ -n "${2}" ]]; then
    USER=${2}
fi

#
WEAVE_BIN=/usr/local/bin/weave

# Weave Network Domain
WEAVE_NETWORK_DOMAIN="hadoop.docker.local."

# Weave PROXY port
WEAVE_PROXY_PORT=12375

# create a new token
echo "Creating a new token..."
#TOKEN=$(docker run -it --rm swarm create)
swarm_dicovery_token=$(curl -s -XPOST https://discovery-stage.hub.docker.com/v1/clusters)

# Load hosts into an array.
declare -a hosts
let i=0
while IFS=$'\n' read -r line_data; do
    if [[ -n "${line_data}" ]]; then
        hosts[i]="${line_data}"
    fi
    ((++i))
done < $1


# create the weave network
echo " ** Creating WEAVE NetWork ...."
let i=0
while (( ${#hosts[@]} > i ))
do
    host="${hosts[i++]}"
    addr_pattern=[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}
    if [[ ${host} =~ $addr_pattern ]]; then
        address=${BASH_REMATCH[0]}
    else
        address=$(dig +short ${host})
    fi

    echo -e " -> joining host ${host} (ip: ${address}) ...."

    ssh_cmd="ssh ${USER}@${host}"
    WEAVE_LAUNCH_ROUTER="${WEAVE_BIN} launch-router --dns-domain=${WEAVE_NETWORK_DOMAIN}"
    echo ${WEAVE_LAUNCH_ROUTER}
    ${ssh_cmd} ${WEAVE_LAUNCH_ROUTER}

    WEAVE_LAUNCH_PROXY="${WEAVE_BIN} launch-proxy --with-dns -H tcp://${address}:${WEAVE_PROXY_PORT}"
    echo ${WEAVE_LAUNCH_PROXY}
    ${ssh_cmd} ${WEAVE_LAUNCH_PROXY}

    #WEAVE_EXPOSE="${WEAVE_BIN} expose"
    #echo ${WEAVE_EXPOSE}
    #${ssh_cmd} ${WEAVE_EXPOSE}

    if [[ ${i} -gt 1 ]]; then
        WEAVE_CONNECT="${WEAVE_BIN} connect ${ROOT_NODE_ADDRESS}"
        echo ${WEAVE_CONNECT}
        ${ssh_cmd} ${WEAVE_CONNECT}
    else
        ROOT_NODE_ADDRESS=${address}
    fi
done


# create the SWARM cluster"
echo " ** Creating SWARM cluster ...."
let i=0
while (( ${#hosts[@]} > i ))
do
    host="${hosts[i++]}"
    addr_pattern=[0-9]\{1,3\}\(\.[0-9]\{1,3\}\)\{3\}
    if [[ ${host} =~ $addr_pattern ]]; then
        address=${BASH_REMATCH[0]}
    else
        address=$(dig +short ${host})
    fi

    echo -e " -> joining host ${host} (ip: ${address}) ...."

    ssh_cmd="ssh ${USER}@${host}"

    ## Default Weave proxy port is 12375
    weave_proxy_endpoint="${address}:${WEAVE_PROXY_PORT}"

    ## Next, we restart the slave agents
    #docker ${DOCKER_CLIENT_ARGS} rm -f swarm-agent
    docker_client_args=""
    ${ssh_cmd} docker ${docker_client_args} run \
        -d \
        --restart=always \
        --name=swarm-agent \
        swarm join \
        --addr "${weave_proxy_endpoint}" \
        "token://${swarm_dicovery_token}"
done


# we assume the node executing this script as a manager
docker run -d -p 3376:2375 swarm manage token://${swarm_dicovery_token}