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
OPTS=`getopt -o d: --long external-dns,nfs-mounts: -n 'parse-options' -- "$@"`

# check parsing result
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; usage; exit 1 ; fi

# process arguments
eval set -- "${OPTS}"
while true; do
  case "$1" in
    --external-dns ) external-dns=true; shift;;
    -d ) background_mode="$1"; shift ;;
    --nfs-mounts ) nfs_enabled="true"; nfs_shared_paths="${2}" shift; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done


#  update the DNS table if needed
if [[ ${external_dns} == true ]]; then
	echo "- Using external DNS ..."
else
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
if [[ $# -gt 1 ]]; then  	
	# init user folders
	init-folders.sh
	# set parameters
	user=${1}
	script=${2}
	shift 2
  	# executes the arguments as bash script
	sudo -u ${user} ${script} $@
else
  	# start open SSH server in foreground mode	
	start-container.sh
fi