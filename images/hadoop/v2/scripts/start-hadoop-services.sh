#!/bin/bash 


# default values
external_dns=false
background_mode=false
nfs_enabled=false
nfs_shared_paths=""

# print usage
usage() {
    echo "Usage: $0 [--external-dns] [-d] [--nfs-mounts]"
    exit 1;
}

# parse arguments
OPTS=`getopt -o d --long external-dns,nfs-mounts: -n 'parse-options' -- "$@"`

# check parsing result
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; usage; exit 1 ; fi

# process arguments
eval set -- "${OPTS}"
while true; do
  case "$1" in
    --external-dns ) external-dns=true; shift;;
    -d ) background_mode=true; shift ;;
    --nfs-mounts ) nfs_enabled="true"; nfs_shared_paths="${2}" shift; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done


#  update the DNS table if needed
if [[ ${external_dns} == true ]]; then
	echo "Using external DNS ..."
else
	echo "Updating /etc/hosts..."
	update-etc-hosts
fi


# initializes shared folders
init-shared-folders ${nfs_enabled} ${nfs_shared_paths}


# FIXME
# temporarily fix hdfs cache test when
# when namenode is not localhost
sed -ie 's/namenode:/localhost:/g' ${HADOOP_CONF_DIR}/core-site.xml

# Start Hadoop Services
start-namenode.sh -d
start-datanode.sh -d
start-resourcemanager.sh -d
start-nodemanager.sh -d
start-historyserver.sh -d

# check the arguments
if [[ ${background_mode} == true ]]; then
	# start open SSH server in foreground mode
	start-container.sh
elif [[ -n $1 ]]; then
  	# exec a command as default user
	sudo -E -u ${DEFAULT_USER} $@
else
    # enable a shell with the default user
	su -l ${DEFAULT_USER}
fi