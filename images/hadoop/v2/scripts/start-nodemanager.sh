#!/bin/bash

# Start the NodeManager
${HADOOP_HOME}/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start nodemanager

# Print logs in foreground mode if the first param is not '-d'
if [[ "${1}" != "-d" ]]; then
	tail -f ${HADOOP_HOME}/logs/*nodemanager-${HOSTNAME}.out
fi