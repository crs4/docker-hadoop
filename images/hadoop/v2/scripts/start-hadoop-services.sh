#!/bin/bash 

#  update the DNS table if needed
if [[ "${1}" == "--external-dns" ]]; then
	echo "- Using external DNS ..."	
	shift
else
	# fill DNS table
	current_ip=$(ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')
	echo -e "${current_ip}\t\tnamenode" >> /etc/hosts
	echo -e "${current_ip}\t\tdatanode" >> /etc/hosts
	echo -e "${current_ip}\t\tresourcemanager" >> /etc/hosts
	echo -e "${current_ip}\t\tnodemanager" >> /etc/hosts
	echo -e "${current_ip}\t\thistoryserver" >> /etc/hosts
fi

# Start Hadoop Services
start-namenode.sh -d
start-datanode.sh -d
start-nodemanager.sh -d
start-resourcemanager.sh -d
start-historyserver.sh -d

# check the arguments
if [[ $# -gt 0 ]]; then  	
  	# executes the arguments as bash script
	/bin/bash -c "$@"
else
  	# start open SSH server in foreground mode	
	/usr/sbin/sshd -D
	echo "- SSH server started !"
fi