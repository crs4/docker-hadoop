#!/bin/bash

# current path
CURRENT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# images path
IMAGES_PATH="${CURRENT_PATH}/images"

# the dockerhub repo to use
DOCKERHUB_REPOSITORY_PREFIX="kikkomep/docker"

# image to build
IMAGE_NAME=${1}

# check whether the name has been provided
if [[ -z "$IMAGE_NAME" ]]; then	
	echo "You have to provide the name of the image to build (e.g., hadoop-2.6.0)"
	exit -1
fi

# detect distro and version
DISTRO=${IMAGE_NAME%-*}
VERSION=${IMAGE_NAME#*-}
VERSION_PARTS=(${VERSION//\./ })
echo -e "\n - DISTRO:  ${DISTRO}"
echo -e " - VERSION: ${VERSION}"

# docker build command prefix
DOCKER_BUILD_CMD="docker build -t ${DOCKERHUB_REPOSITORY_PREFIX}"

# build the base image
echo -e "\n - Building the base image..."
${DOCKER_BUILD_CMD}-base ${IMAGES_PATH}/base

# build the selected hadoop distro
if [[ -d "${IMAGES_PATH}/${DISTRO}" ]]; then
	# distro base image
	echo -e "\n - Building the '${DISTRO}' base image..."
	${DOCKER_BUILD_CMD}-${DISTRO}-base ${IMAGES_PATH}/${DISTRO}	
	# distro version base image
	if [[ -d "${IMAGES_PATH}/${DISTRO}/v${VERSION_PARTS[0]}" ]]; then
		
		# download dist version
		${IMAGES_PATH}/${DISTRO}/scripts/download-hadoop.sh ${VERSION}
		
		# build the version image	
		echo -e "\n - Building the '${DISTRO}-${VERSION}' image..."
		${DOCKER_BUILD_CMD}-${DISTRO}-${VERSION} \
			${IMAGES_PATH}/${DISTRO}/v${VERSION_PARTS[0]}
			
	else
		echo -e "\n *** WARNING: version ${VERSION} of the '${DISTRO}' distro not supported !!! \n"
		exit -1
	fi
else
	echo -e "\n *** WARNING: distro '${DISTRO}' not supported !!! \n"
	exit -1
fi

# Then you can push images