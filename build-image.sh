#!/bin/bash

# current path
CURRENT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# images path
IMAGES_PATH="${CURRENT_PATH}/images"

# the docker repository
DOCKERHUB_REPOSITORY="crs4"

# the dockerhub image prefix
DOCKERHUB_IMAGE_PREFIX="docker"

# print usage
usage() {
    echo -e "\nUsage: $0 [-r|--repository <crs4>] [-p|--prefix <docker>] HADOOP_DISTRO";
    echo -e "       e.g.: $0 -r crs4 -p docker hadoop-2.7.1";
    exit 1;
}

# parse arguments
OPTS=`getopt -o r:p: --long "repository:,prefix:" -n 'parse-options' -- "$@"`

# check parsing result
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; usage; exit 1 ; fi

# process arguments
eval set -- "$OPTS"
while true; do
  case "$1" in
    -r | --repository ) DOCKERHUB_REPOSITORY="$2"; shift; shift ;;
    -p | --prefix ) DOCKERHUB_IMAGE_PREFIX="$2"; shift; shift ;;
    --help ) usage; exit 0; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done


# image to build
HADOOP_DISTRO=${1}

# check whether the name has been provided
if [[ -z "$HADOOP_DISTRO" ]]; then
	usage
	exit -1
fi

# image prefix
DOCKERHUB_REPOSITORY_IMAGE_PREFIX="${DOCKERHUB_REPOSITORY}/${DOCKERHUB_IMAGE_PREFIX}-"

# fixes image repository
function update_image_prefix(){
	local dockerfile_path=${1}/Dockerfile;
    local current_full_image_name=$(grep -m 1 FROM ${dockerfile_path} | awk '{print $2}')
    local image_prefix_pattern=$(echo "${current_full_image_name}" | cut -d'-' -f1 | sed -e 's/[]\/$*.^|[]/\\&/g' )
    local image_name=$(echo ${current_full_image_name} | sed -e "s/${image_prefix_pattern}-//")
    local new_full_image_name="${DOCKERHUB_REPOSITORY_IMAGE_PREFIX}${image_name}"
    local new_image_name_pattern=$(echo ${new_full_image_name} | sed -e 's/[]\/$*.^|[]/\\&/g')

    # Uncomment to debug
#    echo "Prefix: ${image_prefix_pattern}"
#    echo "Current Full name: ${current_full_image_name}"
#    echo "Local name: ${image_name}"
#    echo "Full name: ${new_full_image_name}"

    # the line number to replace
	from_line=$(grep -n FROM ${dockerfile_path} | awk '{print $1}' | cut -f1 -d:)
    # replace the line ${from_line}
	sed -i "${from_line}s/.*/FROM ${new_image_name_pattern}/" ${dockerfile_path}
}


# detect distro and version
DISTRO=${HADOOP_DISTRO%-*}
VERSION=${HADOOP_DISTRO#*-}
VERSION_PARTS=(${VERSION//\./ })
echo -e "\n - DISTRO:  ${DISTRO}"
echo -e " - VERSION: ${VERSION}"

# docker build command prefix
DOCKER_BUILD_CMD="docker build -t ${DOCKERHUB_REPOSITORY_IMAGE_PREFIX}"

# build the base image
echo -e "\n - Building the base image..."
${DOCKER_BUILD_CMD}base ${IMAGES_PATH}/base

# build the base image
echo -e "\n - Building the nfs-server image..."
update_image_prefix ${IMAGES_PATH}/nfs-server nfs-server
${DOCKER_BUILD_CMD}nfs-server ${IMAGES_PATH}/nfs-server


# build the selected hadoop distro
if [[ -d "${IMAGES_PATH}/${DISTRO}" ]]; then

	# distro base image
	echo -e "\n - Building the '${DISTRO}' base image..."
	update_image_prefix ${IMAGES_PATH}/${DISTRO}
	${DOCKER_BUILD_CMD}${DISTRO}-base ${IMAGES_PATH}/${DISTRO}

	# distro version base image
	if [[ -d "${IMAGES_PATH}/${DISTRO}/v${VERSION_PARTS[0]}/version/${VERSION}" ]]; then
		
		# build the base image for the distro
		echo -e "\n - Building the image for the '${DISTRO}' distro v${VERSION_PARTS[0]} ..."
		update_image_prefix ${IMAGES_PATH}/${DISTRO}/v${VERSION_PARTS[0]}
		${DOCKER_BUILD_CMD}${DISTRO}-v${VERSION_PARTS[0]} ${IMAGES_PATH}/${DISTRO}/v${VERSION_PARTS[0]}
		
		# download dist version
		hadoop_archive_path="${IMAGES_PATH}/${DISTRO}/v${VERSION_PARTS[0]}/version/${VERSION}"
		${IMAGES_PATH}/${DISTRO}/scripts/download-hadoop.sh ${VERSION} ${hadoop_archive_path}
		
		# build the version image	
		echo -e "\n - Building the '${DISTRO}-${VERSION}' image..."
		update_image_prefix ${IMAGES_PATH}/${DISTRO}/v${VERSION_PARTS[0]}/version/${VERSION}
		${DOCKER_BUILD_CMD}${DISTRO}-${VERSION} ${IMAGES_PATH}/${DISTRO}/v${VERSION_PARTS[0]}/version/${VERSION}
			
	else
		echo -e "\n *** WARNING: version ${VERSION} of the '${DISTRO}' distro not supported !!! \n"
		exit -1
	fi
else
	echo -e "\n *** WARNING: distro '${DISTRO}' not supported !!! \n"
	exit -1
fi

# Then you can push images

