#!/bin/bash

# check the number of arguments
if [[ "$#" -ne 3 ]]; then
  echo -e "\n *** Invalid number of arguments: provide TAR.GZ path, HADOOP_VERSION and HADOOP_HOME \n"
  exit -1 
fi

# Set version and destination from args
HADOOP_TARGZ=${1}
HADOOP_VERSION=${2}
HADOOP_HOME=${3}

# Expand hadoop archive and move it to the '${HADOOP_HOME}' folder
cd ${HADOOP_TARGZ}
tar xzvf hadoop-${HADOOP_VERSION}.tar.gz 
mv hadoop-${HADOOP_VERSION} ${HADOOP_HOME}

# restore original path
cd -