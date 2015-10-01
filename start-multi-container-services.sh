#!/bin/bash

# check the number of arguments
if [[ "$#" -ne 2 ]]; then
  echo -e "\n *** Invalid number of arguments: provide DOCKERHUB_REPOSITORY and HADOOP_VERSION \n"
  exit -1 
fi

# set repository and hadoop version from arguments
DOCKERHUB_REPOSITORY_PREFIX=${1}
HADOOP_VERSION=${2}

# set compose project name
DOCKER_COMPOSE_PROJECT="" #"${HADOOP_VERSION}"

# current path
CURRENT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# buid the docker-compose file
${CURRENT_PATH}/build-compose.sh --external-dns ${DOCKERHUB_REPOSITORY_PREFIX} ${HADOOP_VERSION}

# start compose
docker-compose up -d # no-project name