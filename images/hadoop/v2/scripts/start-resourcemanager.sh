#!/bin/bash

# Start the ResourceManager
${HADOOP_HOME}/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR start resourcemanager

# Log
tail -f ${HADOOP_HOME}/logs/*resourcemanager-${HOSTNAME}.out