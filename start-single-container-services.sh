#!/bin/bash

# check the number of arguments
if [[ "$#" -lt 2 ]]; then
  echo -e "\n *** Invalid number of arguments: provide DOCKERHUB_REPOSITORY and HADOOP_VERSION \n"
  exit -1 
fi

# set repository and hadoop version from arguments
DOCKERHUB_REPOSITORY_PREFIX=${1}
HADOOP_VERSION=${2}
shift 2

# set compose project name
DOCKER_COMPOSE_PROJECT="" #"${HADOOP_VERSION}"

# current path
CURRENT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# working directory
WORKING_DIR="$(pwd)"

# copy public keys
PUBLIC_KEYS_DIR=${WORKING_DIR}/keys
mkdir -p ${PUBLIC_KEYS_DIR}
cp ~/.ssh/*.pub ${PUBLIC_KEYS_DIR}/

# set default DNS for containers
DOCKER_ENVIRONMENT_DNS="172.17.42.1"

# start a new container for running tests and examples
# FIXME: add -d option
docker run -it --rm \
    -v ${WORKING_DIR}:/shared \
    -v ${SHARED_DIRS_BASE}/libraries/system/lib:/usr/local/lib \
    -v ${SHARED_DIRS_BASE}/libraries/system/bin:/usr/local/bin \
    -v ${SHARED_DIRS_BASE}/libraries/root-user/bin:/root/.local/bin \
    -v ${SHARED_DIRS_BASE}/libraries/root-user/lib:/root/.local/lib \
    -v ${SHARED_DIRS_BASE}/libraries/aen-user/bin:/home/aen/.local/bin \
    -v ${SHARED_DIRS_BASE}/libraries/aen-user/lib:/home/aen/.local/lib \
    -v ${SHARED_DIRS_BASE}/hadoop-data:/opt/hadoop/data \
    -v ${SHARED_DIRS_BASE}/hadoop-logs:/opt/hadoop/logs \
    -p 2222:22 \
    -p 8088:8088 \
    -p 19888:19888 \
    -p 50070:50070 \
    --dns=${DOCKER_ENVIRONMENT_DNS} \
    --dns=8.8.8.8 \
    --name "${HADOOP_VERSION}" \
    ${DOCKERHUB_REPOSITORY_PREFIX}-${HADOOP_VERSION} \
    start-hadoop-services $@