#!/bin/bash

# Start the DataNode
${HADOOP_HOME}/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start datanode

# Print logs in foreground mode if the first param is not '-d'
if [[ "${1}" != "-d" ]]; then
	tail -f ${HADOOP_HOME}/logs/*datanode-${HOSTNAME}.out
fi