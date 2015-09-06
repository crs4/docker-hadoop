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
start-resourcemanager.sh -d
start-nodemanager.sh -d
start-historyserver.sh -d

# check the arguments
if [[ $# -eq 2 ]]; then  	
	# init user folders
	init-folders.sh
  	# executes the arguments as bash script
	sudo -u ${1} ${2}
else
  	# start open SSH server in foreground mode	
	start-container.sh
fi