#!/bin/bash

# Start the JobHistory server
${HADOOP_HOME}/sbin/mr-jobhistory-daemon.sh start historyserver --config $HADOOP_CONF_DIR

# Print logs in foreground mode if the first param is not '-d'
if [[ "${1}" != "-d" ]]; then
	tail -f ${HADOOP_HOME}/logs/*historyserver-${HOSTNAME}.out
fi