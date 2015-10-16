#!/bin/bash

# set default DockerHub repository
DOCKERHUB_REPOSITORY="crs4"
# set default image prefix
DOCKERHUB_IMAGE_PREFIX="docker"
# set default hadoop version
HADOOP_VERSION="hadoop-2.7.1"
# run as daemon flag
IS_DAEMON=false
# external DNS
USE_EXTERNAL_DNS=false

# print usage
usage() { 
    echo "Usage: $0 [-r|--repository <REPOSITORY>] [-p|--prefix <IMAGE_PREFIX>] [-c <COMMAND>][-d] [--external-dns] <HADOOP_DISTRO>"
    exit 1; 
}

# parse arguments
OPTS=`getopt -o r:p:c:d --long "prefix,repository,command:,external-dns" -n 'parse-options' -- "$@"`

# check parsing result
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; usage; exit 1 ; fi

# process arguments
eval set -- "$OPTS"
while true; do
  case "$1" in
    -r | --repository ) DOCKERHUB_REPOSITORY="$2"; shift; shift ;;
    -p | --prefix ) DOCKERHUB_IMAGE_PREFIX="$2"; shift; shift ;;    
    -c | --command ) COMMAND="$2"; shift; shift;;
    -d ) IS_DAEMON=true; shift;;
    --help ) usage; exit 0; shift;;
    --external-dns ) USE_EXTERNAL_DNS=true; shift;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# sets the Hadoop version to use
if [[ -n "${1}" ]]; then
	HADOOP_VERSION=${1}
fi

# image prefix
DOCKERHUB_REPOSITORY_IMAGE_PREFIX="${DOCKERHUB_REPOSITORY}/${DOCKERHUB_IMAGE_PREFIX}-"

# current path
CURRENT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# load base config
source ${CURRENT_PATH}/config.sh

# working directory
WORKING_DIR="$(pwd)"

# copy public keys
PUBLIC_KEYS_DIR=${WORKING_DIR}/keys
mkdir -p ${PUBLIC_KEYS_DIR}
cp ~/.ssh/*.pub ${PUBLIC_KEYS_DIR}/

# set default DNS for containers
DOCKER_ENVIRONMENT_DNS="172.17.42.1"

# starts DNS service if required
if [[ ${USE_EXTERNAL_DNS} == true ]]; then
    docker run -d -v /var/run/docker.sock:/var/run/docker.sock -p 172.17.42.1:53:53/udp \
               --name dnsdock tonistiigi/dnsdock
fi

# start a new container for running tests and examples
docker_mode="-it --rm"
if [[ $IS_DAEMON = true ]]; then docker_mode="-d"; docker_cmd_mode="-d"; fi;
docker run ${docker_mode} \
    -v ${WORKING_DIR}:/shared \
    -v ${SHARED_DIRS_BASE}/libraries/system/lib:/usr/local/lib \
    -v ${SHARED_DIRS_BASE}/libraries/system/bin:/usr/local/bin \
    -v ${SHARED_DIRS_BASE}/libraries/root-user/bin:/root/.local/bin \
    -v ${SHARED_DIRS_BASE}/libraries/root-user/lib:/root/.local/lib \
    -v ${SHARED_DIRS_BASE}/libraries/${DEFAULT_USER}-user/bin:/home/${DEFAULT_USER}/.local/bin \
    -v ${SHARED_DIRS_BASE}/libraries/${DEFAULT_USER}-user/lib:/home/${DEFAULT_USER}/.local/lib \
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
    ${DOCKERHUB_REPOSITORY_IMAGE_PREFIX}${HADOOP_VERSION} \
    start-hadoop-services ${docker_cmd_mode} ${COMMAND}