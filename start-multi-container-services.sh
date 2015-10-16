#!/bin/bash

# set default DockerHub repository
DOCKERHUB_REPOSITORY="crs4"
# set default image prefix
DOCKERHUB_IMAGE_PREFIX="docker"
# set default hadoop version
HADOOP_VERSION="hadoop-2.7.1"
# init weave net
WEAVE_NET_INIT=false

# print usage
usage() {
    echo "Usage: $0 [-r|--repository <REPOSITORY>] [-p|--prefix <IMAGE_PREFIX>] [--init-weave] [-d] [--external-dns] <HADOOP_DISTRO>"
    exit 1;
}

# parse arguments
OPTS=`getopt -o r:p:d --long "prefix,repository,external-dns,init-weave" -n 'parse-options' -- "$@"`

# check parsing result
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; usage; exit 1 ; fi

# process arguments
eval set -- "$OPTS"
while true; do
  case "$1" in
    -r | --repository ) DOCKERHUB_REPOSITORY="$2"; shift; shift ;;
    -p | --prefix ) DOCKERHUB_IMAGE_PREFIX="$2"; shift; shift ;;
    --init-weave ) WEAVE_NET_INIT=true; shift;;
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

# init weave network if required
if [[ ${WEAVE_NET_INIT} == true ]]; then
	# restore old docker host config
	if [[ -n ${DOCKER_WEAVE_HOST} ]]; then
		DOCKER_HOST=${DOCKER_WEAVE_HOST}
		DOCKER_TLS_VERIFY=${DOCKER_WEAVE_TLS_VERIFY}
	fi
	net-utils/weave-swarm-network-manager.sh launch
	# save current Docker host config
	DOCKER_WEAVE_HOST=${DOCKER_WEAVE_HOST}
	DOCKER_WEAVE_TLS_VERIFY=${DOCKER_TLS_VERIFY}
	# update env to run with weave
	eval $(weave env)
	unset DOCKER_TLS_VERIFY
fi

# buid the docker-compose file
${CURRENT_PATH}/build-compose.sh --external-dns ${DOCKERHUB_REPOSITORY_IMAGE_PREFIX} ${HADOOP_VERSION}

# start compose
docker-compose up -d # no-project name

# print info of running services
echo -e "\n****************************************************************"
echo -e "*** Running Services ... "
echo -e "****************************************************************\n\n"
docker-compose ps