#!/bin/bash

# default values
background_mode=false
nfs_enabled=false
update_hostname=false
nfs_shared_paths=""

# print usage
usage() {
    echo "Usage: $0 [-d] [--nfs-mounts] [--update-hostname]"
    exit 1;
}

# parse arguments
OPTS=`getopt -o :d --long nfs-mounts:,update-hostname -n 'parse-options' -- "$@"`

# check parsing result
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; usage; exit 1 ; fi

# process arguments
eval set -- "${OPTS}"
while true; do
  case "$1" in
    -d ) background_mode=true; shift ;;
    --nfs-mounts ) nfs_enabled=true; nfs_shared_paths="${2}"; shift; shift ;;
    --update-hostname ) update_hostname=true; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# update hostname
if [[ ${update_hostname} == true ]]; then
    update-hostname
fi

# initializes shared folders
init-shared-folders ${nfs_enabled} ${nfs_shared_paths}

# Check whether the NameNode has been already formatted
init_hdfs_folder=false;
if [[ ! -d "${HDFS_DATA_DIR}" ]]; then
	${HADOOP_HOME}/bin/hdfs namenode -format
	init_hdfs_folder=true;
fi

# Start the NameNode
${HADOOP_HOME}/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR start namenode

# Init HDFS folders
if [[ ${init_hdfs_folder} == true ]]; then
    sleep 3
    ${HADOOP_ADMIN_SCRIPTS}/init-hdfs-folders.sh
fi

# Print logs in foreground mode if the first param is not '-d'
if [[ ${background_mode} == false ]]; then
	tail -f ${HADOOP_HOME}/logs/*namenode-${HOSTNAME}.out
fi