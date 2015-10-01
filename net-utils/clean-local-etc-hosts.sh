#!/bin/bash

#
OUTPUT_FILE="/etc/hosts"
if [[ -n ${1} ]]; then
    OUTPUT_FILE=${1}
fi

echo $OUTPUT_FILE


START_TAG="##DOCKER-HADOOP-SERVICES##"
END_TAG="##DOCKER-HADOOP-SERVICE##"


sudo sed -i -f "/${START_TAG}/,/${END_TAG}/d" ${OUTPUT_FILE}
