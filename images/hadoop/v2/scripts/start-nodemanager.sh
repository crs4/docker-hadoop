#!/bin/bash

# Start the NodeManager
${HADOOP_HOME}/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start nodemanager

# Log
tail -f ${HADOOP_HOME}/logs/*nodemanager-${HOSTNAME}.out