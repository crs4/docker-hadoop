#!/usr/bin/env bash

remote_docker_host=$1
remote_docker_port=$2

#
OUTPUT_FILE="/etc/hosts"
if [[ -n ${3} ]]; then
    OUTPUT_FILE=${3}
fi

echo $OUTPUT_FILE


docker_cmd="docker -H tcp://${remote_docker_host}:${remote_docker_port} "

echo $docker_cmd
# ResourceManagers
resourcemanager_info=$(${docker_cmd} ps | egrep [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:8088)
if [[ -n ${resourcemanager_info} ]]; then
    resourcemanager_id=$(echo ${resourcemanager_info} | awk '{print $1}')
    resourcemanager_hostname=$(${docker_cmd} inspect --format="{{ .Config.Hostname }}.{{ .Config.Domainname }}" ${resourcemanager_id})
    resourcemanager_ip=$(${docker_cmd} ps | egrep -o  [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:8088 | cut -d':' -f 1)
    if [[ ${resourcemanager_ip} == "0.0.0.0" ]]; then
        resourcemanager_ip=${remote_docker_host}
    fi
fi

# NodeManagers
let i=0
nodemanager_entries=""
nodemanager_infos=$(${docker_cmd} ps | egrep [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:8042)
while (( ${#nodemanager_infos[@]} > i ))
do
    nodemanager_info="${nodemanager_infos[i++]}"

    if [[ -n ${nodemanager_info} ]]; then
        nodemanager_id=$(echo ${nodemanager_info} | awk '{print $1}')
        nodemanager_hostname=$(${docker_cmd} inspect --format="{{ .Config.Hostname }}.{{ .Config.Domainname }}" ${nodemanager_id})
        nodemanager_ip=$(${docker_cmd} ps | egrep -o  [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:8042 | cut -d':' -f 1)
        if [[ ${nodemanager_ip} == "0.0.0.0" ]]; then
            nodemanager_ip=${remote_docker_host}
        fi

        nodemanager_entries=${nodemanager_entries}"${nodemanager_ip}\t${nodemanager_hostname}"
    fi
done


# NameNode
namenode_info=$(${docker_cmd} ps | egrep [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:50070)
if [[ -n ${namenode_info} ]]; then
    namenode_id=$(echo ${namenode_info} | awk '{print $1}')
    namenode_hostname=$(${docker_cmd} inspect --format="{{ .Config.Hostname }}.{{ .Config.Domainname }}" ${namenode_id})
    namenode_ip=$(${docker_cmd} ps | egrep -o  [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:50070 | cut -d':' -f 1)
    if [[ ${namenode_ip} == "0.0.0.0" ]]; then
        namenode_ip=${remote_docker_host}
    fi
fi


# HistoryServer
historyserver_info=$(${docker_cmd} ps | egrep [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:19888)
if [[ -n ${historyserver_info} ]]; then
    historyserver_id=$(echo ${historyserver_info} | awk '{print $1}')
    historyserver_hostname=$(${docker_cmd} inspect --format="{{ .Config.Hostname }}.{{ .Config.Domainname }}" ${historyserver_id})
    historyserver_ip=$(${docker_cmd} ps | egrep -o  [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:19888 | cut -d':' -f 1)
    if [[ ${historyserver_ip} == "0.0.0.0" ]]; then
        historyserver_ip=${remote_docker_host}
    fi
fi


function get_service_entry_by_port(){
    local service_port=$1;
    local service_entries=$2;

    service_info=$(${docker_cmd} ps | egrep [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:${service_port})
    if [[ -n ${service_info} ]]; then
        service_id=$(echo ${service_info} | awk '{print $1}')
        service_hostname=$(${docker_cmd} inspect --format="{{ .Config.Hostname }}.{{ .Config.Domainname }}" ${service_id})
        service_ip=$(${docker_cmd} ps | egrep -o  [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:${service_port} | cut -d':' -f 1)
        if [[ ${service_ip} == "0.0.0.0" ]]; then
            service_ip=${remote_docker_host}
        fi
    fi

    #service_entry="\n${service_ip}\t${service_hostname}";
    service_entries["${service_ip}"]=${service_hostname};
}


START_TAG="##DOCKER-HADOOP-SERVICES##"
END_TAG="##DOCKER-HADOOP-SERVICE##"


read -r -d '' DOCKER_SERVICES << EOM
${START_TAG}
# resourcemanager
${resourcemanager_ip}\t${resourcemanager_hostname}
# nodemanagers
${nodemanager_entries}
# namenode
${namenode_ip}\t${namenode_hostname}
# historyserver
${historyserver_ip}\t${historyserver_hostname}
${END_TAG}
EOM

# set the environment
sudo sed -i -f "/${START_TAG}/,/${END_TAG}/d" ${OUTPUT_FILE}
sudo -- sh -c "echo '${DOCKER_SERVICES}' >> ${OUTPUT_FILE}"
