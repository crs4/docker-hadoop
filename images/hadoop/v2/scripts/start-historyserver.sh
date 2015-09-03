#!/bin/bash

# Start the JobHistory server
${HADOOP_HOME}/sbin/mr-jobhistory-daemon.sh start historyserver --config $HADOOP_CONF_DIR

# Log
tail -f ${HADOOP_HOME}/logs/*historyserver-${HOSTNAME}.out