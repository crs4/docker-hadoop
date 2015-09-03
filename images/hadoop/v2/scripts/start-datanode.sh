#!/bin/bash

# Start the DataNode
${HADOOP_HOME}/sbin/hadoop-daemon.sh start datanode

# Log
tail -f ${HADOOP_HOME}/logs/*datanode-${HOSTNAME}.out