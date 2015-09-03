#!/bin/bash

PYDOOP_REPOSITORY="crs4/pydoop"
PYDOOP_BRANCH="develop"

if [[ "${1}" -eq "--skip-install" ]]; then  
  if [[ "$#" -eq 3 ]]; then
    PYDOOP_REPOSITORY="${2}"
    PYDOOP_BRANCH="${3}" 
  fi    
else
  if [[ "$#" -eq 2 ]]; then
    PYDOOP_REPOSITORY="${1}"
    PYDOOP_BRANCH="${2}" 
  fi
fi

# download pydoop
git clone -b ${PYDOOP_BRANCH} https://github.com/${PYDOOP_REPOSITORY}

# install pydoop
if [[ "${1}" != "--skip-install" ]]; then
  cd pydoop && \
     python setup.py build && \
     python setup.py install --skip-build
fi