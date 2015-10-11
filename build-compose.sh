#!/bin/bash

# default values
multi_host=false
external_dns=false


# print usage
usage() {
    echo "Usage: $0 [--multi-host] [--external-dns] REPOSITORY_PREFIX HADOOP_VERSION"
    echo -e "\t - e.g.: $0 --multi-host --external-dns crs4/docker hadoop-2.6.0"
    exit -1
}

if [[ $# -lt 2 ]]; then
    usage
fi

if [[ ${1} == "--multi-host" ]]; then
    multi_host=true
    shift;
fi

if [[ ${1} == "--external-dns" ]]; then
    external_dns=true
    EXTERNAL_DNS_OPTS="--external-dns"
    shift;
fi

DOCKERHUB_REPOSITORY_PREFIX=${1}
HADOOP_VERSION=${2}

# set domain & environment
export DOCKER_DOMAIN="docker"
export DOCKER_ENVIRONMENT="hadoop"
export DOCKER_CONTAINER_DOMAIN="${DOCKER_ENVIRONMENT}.${DOCKER_DOMAIN}.local"

# set default DNS for containers
export DOCKER_ENVIRONMENT_DNS="172.17.42.1"

# set the working dir
export WORKING_DIR="$(pwd)"
export SHARED_DIRS_BASE="${WORKING_DIR}/docker-hadoop"

# Set shared NFS folder
SHARING_MOUNT_POINT=/sharing

# copy public keys
PUBLIC_KEYS_DIR=${WORKING_DIR}/keys
mkdir -p ${PUBLIC_KEYS_DIR}
cp ~/.ssh/*.pub ${PUBLIC_KEYS_DIR}/

# set multihost mode
if [[ ${multi_host} == true ]]; then
    CLIENT_VOLUMES=""
    VOLUMES_FROM=""
    NFS_MOUNTS="/opt/hadoop/logs"
    NFS_PARAMS=" --nfs-mounts ${NFS_MOUNTS}"
else
    NFS_PARAMS=""
read -r -d '' CLIENT_VOLUMES << EOM
  volumes:
    - ${WORKING_DIR}:/shared
    - ${SHARED_DIRS_BASE}/libraries/system/lib:/usr/local/lib
    - ${SHARED_DIRS_BASE}/libraries/system/bin:/usr/local/bin
    - ${SHARED_DIRS_BASE}/libraries/root-user/bin:/root/.local/bin
    - ${SHARED_DIRS_BASE}/libraries/root-user/lib:/root/.local/lib
    - ${SHARED_DIRS_BASE}/libraries/aen-user/bin:/home/aen/.local/bin
    - ${SHARED_DIRS_BASE}/libraries/aen-user/lib:/home/aen/.local/lib
    - ${SHARED_DIRS_BASE}/hadoop-data:/opt/hadoop/data
    - ${SHARED_DIRS_BASE}/hadoop-logs:/opt/hadoop/logs
EOM
read -r -d '' VOLUMES_FROM << EOM
  volumes_from:
    - client
EOM
fi

# build the docker-compose.yml
cat <<END > "${WORKING_DIR}/docker-compose.yml"

# FIXME: add DNS container
nfs:
  image: ${DOCKERHUB_REPOSITORY_PREFIX}-nfs-server
  hostname: nfs
  container_name: nfs
  domainname: ${DOCKER_CONTAINER_DOMAIN}
  privileged: true
  ports:
    - "111"
    - "2049"
  environment:
    - SERVICE_NAME=nfs
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}
  dns: ${DOCKER_ENVIRONMENT_DNS}
  dns_search: ${DOCKER_CONTAINER_DOMAIN}
  command: ${SHARING_MOUNT_POINT}


#dnsdock:
#  image: tonistiigi/dnsdock
#  name: dnsdock
#  container_name: dnsdock
#  volumes:
#    - /var/run/docker.sock:/var/run/docker.sock
#  ports:
#    - "172.17.42.1:53:53/udp"
  
client:
  image: ${DOCKERHUB_REPOSITORY_PREFIX}-${HADOOP_VERSION}
  name: client
  hostname: client
  domainname: ${DOCKER_CONTAINER_DOMAIN}
  privileged: true
  ports:
    - "22"
  environment:
    - SERVICE_NAME=client
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}
  dns: ${DOCKER_ENVIRONMENT_DNS}
  dns_search: ${DOCKER_CONTAINER_DOMAIN}
  command: start-container.sh ${EXTERNAL_DNS_OPTS} ${NFS_PARAMS}
  ${CLIENT_VOLUMES}

namenode:
  image: ${DOCKERHUB_REPOSITORY_PREFIX}-${HADOOP_VERSION}
  name: namenode
  hostname: namenode
  domainname: ${DOCKER_CONTAINER_DOMAIN}
  container_name: namenode
  privileged: true
  ${VOLUMES_FROM}
  ports:
    - "9000:9000"
    - "50070:50070"
  environment:
    - DNSDOCK_ALIAS=namenode
    - SERVICE_NAME=namenode
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}
    - "affinity:container!=*datanode*"
  dns: ${DOCKER_ENVIRONMENT_DNS}
  dns_search: ${DOCKER_CONTAINER_DOMAIN}
  command: start-namenode.sh ${NFS_PARAMS}

datanode:
  image: ${DOCKERHUB_REPOSITORY_PREFIX}-${HADOOP_VERSION}
  name: datanode
  #hostname: datanode
  domainname: ${DOCKER_CONTAINER_DOMAIN}
  #container_name: datanode
  privileged: true
  ${VOLUMES_FROM}
  environment:
    - SERVICE_NAME=datanode
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}
    - "affinity:container!=*namenode*"
    - "affinity:container!=*datanode*"
  dns: ${DOCKER_ENVIRONMENT_DNS}
  dns_search: ${DOCKER_CONTAINER_DOMAIN}
  command: start-datanode.sh ${NFS_PARAMS}
    
resourcemanager:
  image: ${DOCKERHUB_REPOSITORY_PREFIX}-${HADOOP_VERSION}
  name: resourcemanager
  hostname: resourcemanager
  domainname: ${DOCKER_CONTAINER_DOMAIN}
  container_name: resourcemanager
  privileged: true
  ${VOLUMES_FROM}
  ports:
    - "8088:8088"
    - "8021:8021"    
    - "8031:8031"
    - "8033:8033"
  environment:  
    - DNSDOCK_ALIAS=resourcemanager
    - SERVICE_NAME=resourcemanager
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}
    - "affinity:container!=*nodemanager*"
  dns: ${DOCKER_ENVIRONMENT_DNS}
  dns_search: ${DOCKER_CONTAINER_DOMAIN}
  command: start-resourcemanager.sh ${NFS_PARAMS}

nodemanager:
  image: ${DOCKERHUB_REPOSITORY_PREFIX}-${HADOOP_VERSION}
  name: nodemanager
  #hostname: nodemanager
  domainname: ${DOCKER_CONTAINER_DOMAIN}
  #container_name: nodemanager
  privileged: true
  environment:
    - SERVICE_NAME=nodemanager
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}
    - "affinity:container!=*resourcemanager*"
    - "affinity:container!=*nodemanager*"
  ports:
    - "8042:8042"
  dns: ${DOCKER_ENVIRONMENT_DNS}
  dns_search: ${DOCKER_CONTAINER_DOMAIN}
  ${VOLUMES_FROM}
  command: start-nodemanager.sh ${NFS_PARAMS}
    
historyserver:
  image: ${DOCKERHUB_REPOSITORY_PREFIX}-${HADOOP_VERSION}
  name: historyserver  
  hostname: historyserver
  domainname: ${DOCKER_CONTAINER_DOMAIN}
  container_name: historyserver
  privileged: true
  ${VOLUMES_FROM}
  ports:
    - "10020:10020"
    - "19888:19888"
  environment:
    - DNSDOCK_ALIAS=historyserver
    - SERVICE_NAME=historyserver    
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}
  dns: ${DOCKER_ENVIRONMENT_DNS}
  dns_search: ${DOCKER_CONTAINER_DOMAIN}
  command: start-historyserver.sh ${NFS_PARAMS}
END
