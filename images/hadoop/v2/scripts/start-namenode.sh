#!/bin/bash

# Check whether the NameNode has been already formatted
if [[ ! -d "${HDFS_DATA_DIR}" ]]; then
	${HADOOP_HOME}/bin/hdfs namenode -format
fi

# Start the NameNode
${HADOOP_HOME}/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start namenode

# Init HDFS folders
${HADOOP_ADMIN_SCRIPTS}/init-folders.sh

# Print logs in foreground mode if the first param is not '-d'
if [[ "${1}" != "-d" ]]; then
	tail -f ${HADOOP_HOME}/logs/*namenode-${HOSTNAME}.out
fi