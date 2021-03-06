#!/bin/bash

# default values
background_mode=false
nfs_enabled=false
update_hostname=false
update_config=false
nfs_shared_paths=""

# print usage
usage() {
    echo "Usage: $0 [-d] [--nfs-mounts] [--update-hostname] [--update-config]"
    exit 1;
}

# parse arguments
OPTS=`getopt -o :d --long nfs-mounts:,update-hostname,update-config -n 'parse-options' -- "$@"`

# check parsing result
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; usage; exit 1 ; fi

# process arguments
eval set -- "${OPTS}"
while true; do
  case "$1" in
    -d ) background_mode=true; shift ;;
    --nfs-mounts ) nfs_enabled=true; nfs_shared_paths="${2}"; shift; shift ;;
    --update-config ) update_config=true; shift ;;
    --update-hostname ) update_hostname=true; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done


# update config
if [[ ${update_config} == true ]]; then
    hadoop-configurator.py --hadoop-conf-dir=/opt/hadoop/etc/hadoop
fi


# update hostname
if [[ ${update_hostname} == true ]]; then
    update-hostname
fi

# initializes shared folders
init-shared-folders ${nfs_enabled} ${nfs_shared_paths}

# fixes an error message which occurs when $USER is empty
export USER="root"
export HADOOP_IDENT_STRING="root"

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