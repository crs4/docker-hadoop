#!/usr/bin/env bash

# sets the command
cmd=${1}

# checks if the commands is not empty
if [[ -z ${cmd} ]]; then
    echo -e "\n Usage: ${0} < add | remove >";
    exit -1
fi

# checks ${DOCKER_HOST}
if [[ -z ${DOCKER_HOST} ]]; then
    echo "Error: no DOCKER_HOST found in your environment!!!"
    exit -1
fi

# process ${cmd}
if [[ ${cmd} == "add" ]]; then
    docker_host_ip=$(echo ${DOCKER_HOST:6} | cut -d':' -f 1)
    sudo route -n add 172.17.0.0/16 ${docker_host_ip}
elif [[ ${cmd} == "remove" ]]; then
    docker_host_ip=$(echo ${DOCKER_HOST:6} | cut -d':' -f 1)
    sudo route -n delete 172.17.0.0/16 ${docker_host_ip}
fi