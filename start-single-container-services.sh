#!/bin/bash

# set default DockerHub repository
DOCKERHUB_REPOSITORY_PREFIX="${USER}/docker"
# set default hadoop version
HADOOP_VERSION="hadoop-2.7.1"
# run as daemon flag
IS_DAEMON=false
# external DNS
USE_EXTERNAL_DNS=false

# print usage
usage() { 
    echo "Usage: $0 [-r <crs4/docker>] [-v | --hadoop-version <develop>] [-d] [--external-dns]"
    exit 1; 
}

# parse arguments
OPTS=`getopt -o r:v:c:d --long "hadoop-version:,command:,external-dns" -n 'parse-options' -- "$@"`

# check parsing result
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; usage; exit 1 ; fi

# process arguments
eval set -- "$OPTS"
while true; do
  case "$1" in
    -r ) DOCKERHUB_REPOSITORY_PREFIX="$2"; shift; shift ;;
    -v | --hadoop-version ) HADOOP_VERSION="$2"; shift; shift ;;
    -c | --command ) COMMAND="$2"; shift; shift;;
    -d ) IS_DAEMON=true; shift;;
    --external-dns ) USE_EXTERNAL_DNS=true; shift;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

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

# set the base path of the shared directories
SHARED_DIRS_BASE=${WORKING_DIR}/docker-hadoop

# starts DNS service if required
if [[ ${USE_EXTERNAL_DNS} == true ]]; then
    docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 172.17.42.1:53:53/udp \
               --name dnsdock tonistiigi/dnsdock
fi

# start a new container for running tests and examples
docker_mode="-it --rm"
if [[ $IS_DAEMON = true ]]; then docker_mode="-d"; fi;
docker run ${docker_mode} \
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
    --name "${HADOOP_VERSION//.}" \
    -e SERVICE_NAME="${HADOOP_VERSION//.}" \
    -e SERVICE_REGION=hadoop \
    ${DOCKERHUB_REPOSITORY_PREFIX}-${HADOOP_VERSION} \
    start-hadoop-services ${COMMAND}