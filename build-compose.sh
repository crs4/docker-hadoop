#!/bin/bash

# check the number of arguments
if [[ "$#" -ne 2 ]]; then
  echo -e "\n *** Invalid number of arguments: provide DOCKERHUB_REPOSITORY and HADOOP_VERSION \n"
  exit -1 
fi

# set repository and hadoop version from arguments
DOCKERHUB_REPOSITORY=${1}
HADOOP_VERSION=${2}

# set domain & environment
export DOCKER_DOMAIN="docker"
export DOCKER_ENVIRONMENT="hadoop"
export DOCKER_CONTAINER_DOMAIN="${DOCKER_ENVIRONMENT}.${DOCKER_DOMAIN}"

# set default DNS for containers
export DOCKER_ENVIRONMENT_DNS="172.17.42.1"

# set the working dir
export WORKING_DIR="$(pwd)"
export SHARED_DIRS_BASE="${WORKING_DIR}/docker-hadoop"

# build the docker-compose.yml
cat <<END > "${WORKING_DIR}/docker-compose.yml"

# FIXME: add DNS container
dnsdock:
  image: tonistiigi/dnsdock
  name: dnsdock
  container_name: dnsdock
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  ports:
    - "172.17.42.1:53:53/udp"
  
client:
  image: ${DOCKERHUB_REPOSITORY}:${HADOOP_VERSION}
  name: client
  hostname: client
  ports:
    - "2222:22"
  environment:
    - SERVICE_NAME=client
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}
  dns: ${DOCKER_ENVIRONMENT_DNS}
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

namenode:
  image: ${DOCKERHUB_REPOSITORY}:${HADOOP_VERSION}
  name: namenode
  hostname: namenode
  container_name: namenode  
  volumes_from:
    - client
  ports:
    - "9000:9000"
    - "50070:50070"
  environment:
    - DNSDOCK_ALIAS=namenode
    - SERVICE_NAME=namenode
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}    
  dns: ${DOCKER_ENVIRONMENT_DNS}
  command: start-namenode.sh

datanode:
  image: ${DOCKERHUB_REPOSITORY}:${HADOOP_VERSION}
  name: datanode
  hostname: datanode
  container_name: datanode
  volumes_from:
    - client
  environment:
    - SERVICE_NAME=datanode
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}
  dns: ${DOCKER_ENVIRONMENT_DNS}
  command: start-datanode.sh        
    
resourcemanager:
  image: ${DOCKERHUB_REPOSITORY}:${HADOOP_VERSION}
  name: resourcemanager
  hostname: resourcemanager
  container_name: resourcemanager  
  volumes_from:    
    - client 
  ports:
    - "8088:8088"
    - "8021:8021"    
    - "8031:8031"
    - "8033:8033"
  environment:  
    - DNSDOCK_ALIAS=resourcemanager
    - SERVICE_NAME=resourcemanager
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}
  dns: ${DOCKER_ENVIRONMENT_DNS}
  command: start-resourcemanager.sh

nodemanager:
  image: ${DOCKERHUB_REPOSITORY}:${HADOOP_VERSION}
  name: nodemanager
  hostname: nodemanager
  container_name: nodemanager
  environment:
    - SERVICE_NAME=nodemanager
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}
  dns: ${DOCKER_ENVIRONMENT_DNS}
  volumes_from:
    - client 
  command: start-nodemanager.sh 
    
historyserver:
  image: ${DOCKERHUB_REPOSITORY}:${HADOOP_VERSION}
  name: historyserver  
  hostname: historyserver
  container_name: historyserver
  volumes_from:
    - client 
  ports:
    - "10020:10020"
    - "19888:19888"
  environment:
    - DNSDOCK_ALIAS=historyserver
    - SERVICE_NAME=historyserver    
    - SERVICE_REGION=${DOCKER_ENVIRONMENT}
  dns: ${DOCKER_ENVIRONMENT_DNS} 
  command: start-historyserver.sh 
END