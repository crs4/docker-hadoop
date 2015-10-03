#!/usr/bin/env bash

if [[ -z "$1" ]]; then
    echo "You have to specify the cluster configuration file!!!"
    exit -1
fi

FILENAME=$1
[[ -z "$2" ]] && DOMAIN_OPTS="" || DOMAIN_OPTS="--domain=${2}"

#
WEAVE_BIN=/usr/local/bin/weave
WEAVE_SCOPE_BIN=/usr/local/bin/scope

# Weave Network Domain
WEAVE_NETWORK_DOMAIN="weave.local"

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
echo " ** Destroying WEAVE NetWork ...."
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
    echo -e "\n\n-> host ${host} (ip: ${address}) is leaving the WEAVE network ...."

    ssh_cmd="ssh ${host}"
    ${ssh_cmd} "x=`docker ps -a | grep swarm | cut -d' ' -f1 `; echo '$x'; if [[ -n '${x}' ]]; then docker rm -f '${x}'; fi;"
    ${ssh_cmd} "${WEAVE_BIN} stop"
    ${ssh_cmd} "${WEAVE_SCOPE_BIN} stop"
done
