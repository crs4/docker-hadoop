#!/bin/bash

# Check whether the NameNode has been already formatted
if [[ ! -d "${HDFS_DATA_DIR}" ]]; then
	${HADOOP_HOME}/bin/hdfs namenode -format
fi

# Start the NameNode
${HADOOP_HOME}/sbin/hadoop-daemon.sh start namenode

# Init HDFS folders
${HADOOP_ADMIN_SCRIPTS}/init-folders.sh

# Log
tail -f ${HADOOP_HOME}/logs/*namenode-${HOSTNAME}.out