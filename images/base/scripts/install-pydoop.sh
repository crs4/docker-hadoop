#!/bin/bash

# set the pydoop repository
PYDOOP_REPOSITORY="crs4/pydoop"
# set the pydoop branch
PYDOOP_BRANCH="develop"
# set the pydoop folder
PYDOOP_FOLDER="pydoop"
# set the --hdfs-core-impl
HDFS_BACKEND="native"

# print usage
usage() { 
    echo "Usage: $0 [-r <crs/pydoop>] [-b <develop>] [-d <pydoop destination path>] [--hdfs-impl <native|jpype-bridged>]"
    exit 1; 
}

# parse arguments
OPTS=`getopt -o r:b:d: --long hdfs-impl: -n 'parse-options' -- "$@"`

# check parsing result
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; usage; exit 1 ; fi

# process arguments
eval set -- "$OPTS"
while true; do
  case "$1" in
    -r ) PYDOOP_REPOSITORY="$2"; shift; shift ;;
    -b ) PYDOOP_BRANCH="$2"; shift; shift ;;
    -d ) PYDOOP_FOLDER="$2"; shift; shift ;;
    --hdfs-impl )
        if [[ $2 != "native" && $2 != "jpype-bridged" ]]; then echo "Invalid option: $2"; usage; fi 
        HDFS_BACKEND="$2"; shift; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done


# download pydoop if not
if [[ ! -d "${PYDOOP_FOLDER}" ]]; then
	download-pydoop ${PYDOOP_REPOSITORY} ${PYDOOP_BRANCH} ${PYDOOP_FOLDER}
fi

# install avro
pip install avro --user

# install jpype if required
if [[ $HDFS_BACKEND == "jpype-bridged"  ]]; then 
	# JPype-0.6.1 @ originell/jpype
	cd $HOME
	git clone https://github.com/originell/jpype.git 
	cd jpype 
	python setup.py install --user
	cd ${CURRENT_PATH}
fi

# install pydoop
cd ${PYDOOP_FOLDER}
python setup.py build --hdfs-core-impl $HDFS_BACKEND
python setup.py install --user --skip-build