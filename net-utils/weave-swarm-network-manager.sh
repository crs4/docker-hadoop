#!/usr/bin/env bash

# current path
current_path=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# loads configuration
source ${current_path}/network-config.sh

# host list filename
host_list_filename="./cluster.config"

# admin user
admin_user="${USER}"

# Loads hosts into an array.
declare -a hosts

# number of hosts
number_of_nodes=0


# loads the list of hosts
function load_host_list(){
    let i=0
    while IFS=$'\n' read -r line_data; do
        if [[ -n "${line_data}" ]]; then
            hosts[i]="${line_data}"
        fi
        ((++i))
    done < ${host_list_filename}

    number_of_nodes=${#hosts[@]}
    #echo "Number of nodes: ${number_of_nodes}"
}


# Launches a local weave network
function weave_node_launch(){
    local node_ip_address=${1};
    local node_peer_ip_address_to_connect=${2};
    local number_of_nodes=${3};
    local enable_scope=${4}
    local ssh_credentials=${5}

    local init_peer_count="";
    if [[ -n ${number_of_nodes} ]]; then
        init_peer_count="--init-peer-count ${number_of_nodes}"
    fi

    if [[ -n ${ssh_credentials} ]]; then
        cmd_prefix="ssh ${ssh_credentials}"
    fi

    ${cmd_prefix} ${WEAVE_BIN} launch-router ${init_peer_count} --dns-domain=${WEAVE_NETWORK_DOMAIN}
    ${cmd_prefix} ${WEAVE_BIN} launch-proxy --with-dns \
                  -H tcp://${node_ip_address}:${WEAVE_PROXY_PORT}
                  #-H unix:///var/run/weave.sock
    if [[ ${node_peer_ip_address_to_connect} != "--" ]]; then
        ${cmd_prefix} ${WEAVE_BIN} connect ${node_peer_ip_address_to_connect}
    fi
    if [[ ${enable_scope} == true ]]; then
        ${cmd_prefix} ${WEAVE_SCOPE_BIN} launch
    fi
}


# Stops the local weave network
function weave_node_stop(){
    ${WEAVE_BIN} stop
    ${WEAVE_SCOPE_BIN} stop
}


# Starts a WEAVE Network
function weave_network_launch(){

    local root_node_address="--";

    # create the weave network
    echo -e "\n*** Creating WEAVE NetWork ...."
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
        ssh_credentials="${admin_user}@${host}"
        weave_node_launch \
                            ${address}  \
                            ${root_node_address} \
                            ${number_of_nodes} \
                            true \
                            ${ssh_credentials}

        if [[ ${i} -eq 1 ]]; then
            root_node_address=${address}
        fi
    done
}


# Stops a WEAVE Network
function weave_network_stop(){
    # create the weave network
    echo -e "\n*** Stopping WEAVE Network ...."
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
        echo -e "-> host ${host} (ip: ${address}) is leaving the WEAVE network ...."

        ssh_credentials="ssh ${admin_user}@${host}"
        ${ssh_credentials} "${WEAVE_BIN} stop"
        ${ssh_credentials} "${WEAVE_SCOPE_BIN} stop"
        ${ssh_credentials} "docker ps -a | grep weavescope | cut -d' ' -f1 | while read x; do docker rm -f \${x}; done;"
    done
}


# Starts a SWARM cluster
function swarm_cluster_launch(){
    # create a new token
    echo -e "\n*** Creating a new token..."
    swarm_dicovery_token=$(docker run -it --rm swarm create)
    echo "- Swarm Cluster Token: ${swarm_dicovery_token}"

    # create the SWARM cluster"
    echo -e "\n*** Creating SWARM cluster ...."
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

        echo -e "-> joining host ${host} (ip: ${address}) ...."

        ssh_credentials="ssh ${admin_user}@${host}"

        ## Default Weave proxy port is 12375
        weave_proxy_endpoint="${address}:${WEAVE_PROXY_PORT}"

        ## Next, we restart the slave agents
        docker_client_args=""
        swarm_agent_container=$(${ssh_credentials} docker ${docker_client_args} run \
            -d \
            --restart=always \
            --name=swarm-agent \
            swarm join \
            --addr "${weave_proxy_endpoint}" \
            "token://${swarm_dicovery_token}")
        echo "- SWARM agent container id: ${swarm_agent_container}"
    done

    # we assume the node executing this script as a manager
    swarm_manager_container=$(docker run -d -p ${SWARM_MANAGER_PORT}:2375 swarm manage token://${swarm_dicovery_token})
    echo "- SWARM agent container id: ${swarm_manager_container}"
}


# Stops the SWARM cluter
function swarm_cluster_stop(){
    # create the weave network
    echo -e "\n*** Stopping SWARM Cluster ...."
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
        echo -e "-> host ${host} (ip: ${address}) is leaving the SWARM cluster ...."

        ssh_credentials="ssh ${admin_user}@${host}"
        ${ssh_credentials} "docker ps -a | grep swarm | cut -d' ' -f1 | while read x; do docker rm -f \${x}; done;"
    done
}


# options
network_mode="local"
swarm=false
weave=true


# prints usage
usage() {
    echo -e "\nUsage: $0 --config <CLUSTER_CONFIG> [--weave] [--swarm] [--admin <ADMIN_USER>] < launch | stop | help > <REMOTE_HOST_ADDRESS>"
    echo -e ""
    exit 1;
}

# parses option arguments
OPTS=`getopt -o :h --long weave,swarm,config:,admin: -n 'parse-options' -- "$@"`

# check parsing result
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; usage; exit 1 ; fi

# processes options
eval set -- "${OPTS}"
while true; do
  case "$1" in
    --local ) network_mode="local"; shift ;;
    --weave ) weave=true; shift ;;
    --swarm ) swarm=true; shift ;;
    --config ) network_mode="cluster"; host_list_filename="${2}"; shift; shift ;;
    --admin ) admin_user="${2}"; shift; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done


# sets the main command
cmd=${1}

# sets the address of the remote host
remote_address="--"
if [[ -n ${2} ]]; then
    remote_address=${2}
fi

# prints usage if required
if [[ ${cmd} == "help" ]]; then
    usage
    exit 0
fi


# loads the list of hosts
if [[ ${network_mode} != "local" ]]; then
    if [[ -f ${host_list_filename} ]]; then
        load_host_list
    else
        echo "Config file not found!!!"
    fi
fi


# processes the command
if [[ ${network_mode} == "local" ]]; then
    if [[ ${cmd} == "launch" ]]; then
        weave_node_launch ${DOCKER_HOST_IP} ${remote_address} ""

    elif [[ ${cmd} == "stop" ]]; then
        weave_node_stop
    else
        usage
    fi
elif [[ ${network_mode} == "cluster" ]]; then
    if [[ ${cmd} == "launch" ]]; then
        if [[ ${weave} == true ]]; then
            weave_network_launch
        fi
        if [[ ${swarm} == true ]]; then
            swarm_cluster_launch
        fi

    elif [[ ${cmd} == "stop" ]]; then
        if [[ ${weave} == true ]]; then
            weave_network_stop
        fi
        if [[ ${swarm} == true ]]; then
            swarm_cluster_stop
        fi
    else
        usage
    fi
fi