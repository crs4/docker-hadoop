#!/bin/bash

# check the number of arguments
if [[ "$#" -ne 1 ]]; then
  echo -e "\n *** Invalid number of arguments: provide Apache Hadoop Version (e.g., 2.6.0) \n"
  exit -1 
fi

# Set version and destination from args
HADOOP_VERSION=${1}
HADOOP_VERSION_PARTS=(${HADOOP_VERSION//\./ })

# current path
CURRENT_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# distro archives (temp)
DIST_PATH="${CURRENT_PATH}/../v${HADOOP_VERSION_PARTS[0]}/version/${HADOOP_VERSION}"

# Set archive URL for downloading Hadoop distros
APACHE_HADOOP_ARCHIVE_URL="http://archive.apache.org/dist/hadoop/core/"

# Hadoop archive name
HADOOP_ARCHIVE_TARGZ="hadoop-${HADOOP_VERSION}.tar.gz"

# Hadoop archive URL
HADOOP_ARCHIVE_TARGZ_URL="${APACHE_HADOOP_ARCHIVE_URL}hadoop-${HADOOP_VERSION}/${HADOOP_ARCHIVE_TARGZ}"

# Downloads the hadoop archive for the specified version
if [[ ! -f "${DIST_PATH}/${HADOOP_ARCHIVE_TARGZ}" ]]; then
  mkdir -p ${DIST_PATH}
  wget -P ${DIST_PATH} ${HADOOP_ARCHIVE_TARGZ_URL}
else
  echo -e "\n - Hadoop archive already available @ ${DIST_PATH} !!!\n"
fi