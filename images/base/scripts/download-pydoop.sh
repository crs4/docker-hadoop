#!/bin/bash

PYDOOP_REPOSITORY="crs4/pydoop"
PYDOOP_BRANCH="develop"

PYDOOP_REPOSITORY="${1}"
PYDOOP_BRANCH="${2}" 

# download pydoop
git clone -b ${PYDOOP_BRANCH} https://github.com/${PYDOOP_REPOSITORY}