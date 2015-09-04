#!/bin/bash

# check the number of arguments
if [[ "$#" -ne 4 ]]; then
  echo -e "\n *** Invalid number of arguments: provide TAR.GZ directory, TAR.GZ filename, HADOOP_VERSION and HADOOP_HOME \n"
  exit -1 
fi

# Set version and destination from args
HADOOP_TARGZ_DIR=${1}
HADOOP_TARGZ_FILE=${1}
HADOOP_TARGZ_PATH=${1}/${2}
HADOOP_VERSION=${3}
HADOOP_HOME=${4}

# Download the archive if doesn't exists!
if [[ ! -f "${HADOOP_TARGZ_PATH}" ]]; then
  download-hadoop.sh ${HADOOP_VERSION}
fi

# Expand hadoop archive and move it to the '${HADOOP_HOME}' folder
tar xzvf ${HADOOP_TARGZ_PATH} 
mv hadoop-${HADOOP_VERSION} ${HADOOP_HOME}