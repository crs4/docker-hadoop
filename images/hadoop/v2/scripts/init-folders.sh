#!/bin/bash

# HDFS Folders
echo -e "Initializing HDFS folders..."
echo -e "  - creating /user/root"
hdfs dfs -mkdir -p /user/root
echo -e "  - creating /user/${UNPRIV_USER}"
hdfs dfs -mkdir -p /user/${UNPRIV_USER}
echo -e "  - setting ownership for /user/${UNPRIV_USER}"
hdfs dfs -chown ${UNPRIV_USER} /user/${UNPRIV_USER}
echo -e "  - creating /tmp"
hdfs dfs -mkdir -p /tmp
echo -e "  - setting permissions for /tmp"
hdfs dfs -chmod 0777 /tmp