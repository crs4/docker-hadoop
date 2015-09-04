#!/bin/bash

# set the existing ssh keys 
shared_keys_path="/shared/keys"
if [[ -d "${shared_keys_path}" ]]; then
	mkdir -p /root/.ssh
	mkdir -p /home/aen/.ssh
	keys=($(ls ${shared_keys_path}/*.pub))
	for key in "${keys[@]}"
	do
		echo "Copying key ${key} ..."
		cat ${key} >> /root/.ssh/authorized_keys
		cat ${key} >> /home/aen/.ssh/authorized_keys
	done
fi
# start open SSH server
/usr/sbin/sshd -D