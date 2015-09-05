#!/bin/bash

# Start the ResourceManager
${HADOOP_HOME}/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start resourcemanager

# Print logs in foreground mode if the first param is not '-d'
if [[ "${1}" != "-d" ]]; then
	tail -f ${HADOOP_HOME}/logs/*resourcemanager-${HOSTNAME}.out
fi