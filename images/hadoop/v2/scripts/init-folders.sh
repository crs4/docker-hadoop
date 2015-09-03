#!/bin/bash

# HDFS Folders
hdfs dfs -mkdir -p /user/root
hdfs dfs -mkdir -p /user/${UNPRIV_USER}
hdfs dfs -chown ${UNPRIV_USER} /user/${UNPRIV_USER}
hdfs dfs -mkdir -p /tmp
hdfs dfs -chmod 0777 /tmp