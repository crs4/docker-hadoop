#!/bin/bash

# set default DockerHub repository
DOCKERHUB_REPOSITORY="crs4"
# set default image prefix
DOCKERHUB_IMAGE_PREFIX="hadoop"
# set default hadoop version
HADOOP_VERSION="apache-2.7.1"
# init swarm cluster flag
INIT_SWARM_CLUSTER=false
# cluster config file
CLUSTER_CONFIG_FILE="cluster.config"
# swarm cluster admin user
CLUSTER_ADMIN_USER=${USER}

# print usage
usage() {
    echo "Usage: $0 [-r|--repository <REPOSITORY>] [-p|--prefix <IMAGE_PREFIX>] [--init-swarm] [-d] [--external-dns] <HADOOP_DISTRO>"
    exit 1;
}

# parse arguments
OPTS=`getopt -o r:p:d --long "prefix,repository,init-swarm,admin-user:,cluster-config:,external-dns" -n 'parse-options' -- "$@"`

# check parsing result
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; usage; exit 1 ; fi

# process arguments
eval set -- "$OPTS"
while true; do
  case "$1" in
    -r | --repository ) DOCKERHUB_REPOSITORY="$2"; shift; shift ;;
    -p | --prefix ) DOCKERHUB_IMAGE_PREFIX="$2"; shift; shift ;;
    --cluster-config ) CLUSTER_CONFIG_FILE="$2"; shift; shift ;;	
    --admin-user ) CLUSTER_ADMIN_USER="$2"; shift; shift ;;	
    -d ) IS_DAEMON=true; shift;;
    --init-swarm ) INIT_SWARM_CLUSTER=true; shift;;
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

# init swarm cluster if required
if [[ ${INIT_SWARM_CLUSTER} == true ]]; then
	# restore old docker host config
	if [[ -n ${DOCKER_SWARM_HOST} ]]; then
		DOCKER_HOST=${DOCKER_SWARM_HOST}
	fi
	# loads default network config
	source net-utils/network-config.sh
	# launches the swarm cluster
	net-utils/weave-swarm-network-manager.sh \
		--swarm --config ${CLUSTER_CONFIG_FILE} \
		--admin ${CLUSTER_ADMIN_USER} launch	
	# save current Docker host config
	DOCKER_SWARM_HOST=${DOCKER_HOST}
	# update env to run with swarm manager	
	DOCKER_HOST="tcp://${DOCKER_HOST_IP}:${SWARM_MANAGER_PORT}"
fi


# buid the docker-compose file
${CURRENT_PATH}/build-compose.sh --multi-host --external-dns ${DOCKERHUB_REPOSITORY_IMAGE_PREFIX} ${HADOOP_VERSION}

# start compose
docker-compose up -d nfs # start nfs first
docker-compose up -d client # start nfs first
docker-compose up -d # no-project name

# print info of running services
echo -e "\n****************************************************************"
echo -e "*** Running Services ... "
echo -e "****************************************************************\n\n"
docker-compose ps