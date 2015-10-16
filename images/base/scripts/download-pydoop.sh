#!/bin/bash

# set the pydoop repository
PYDOOP_REPOSITORY="crs4/pydoop"
# set the pydoop branch
PYDOOP_BRANCH="develop"
# set the pydoop folder
PYDOOP_FOLDER="pydoop"

# print usage
usage() { 
    echo "Usage: $0 [-r <crs/pydoop>] [-b <develop>] [-d <pydoop destination path>]"
    exit 1; 
}

# parse arguments
OPTS=`getopt -o r:b:d: -n 'parse-options' -- "$@"`

# check parsing result
if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; usage; exit 1 ; fi

# process arguments
eval set -- "$OPTS"
while true; do
  case "$1" in
    -r ) PYDOOP_REPOSITORY="$2"; shift; shift ;;
    -b ) PYDOOP_BRANCH="$2"; shift; shift ;;
    -d ) PYDOOP_FOLDER="$2"; shift; shift ;;    
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# download pydoop
git clone -b ${PYDOOP_BRANCH} https://github.com/${PYDOOP_REPOSITORY} ${PYDOOP_FOLDER}