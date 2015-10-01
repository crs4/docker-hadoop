#!/bin/bash

# fill DNS table
current_ip=$(ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}')
echo -e "${current_ip}\t\tnamenode.hadoop.docker.local" >> /etc/hosts
echo -e "${current_ip}\t\tdatanode.hadoop.docker.local" >> /etc/hosts
echo -e "${current_ip}\t\tresourcemanager.hadoop.docker.local" >> /etc/hosts
echo -e "${current_ip}\t\tnodemanager.hadoop.docker.local" >> /etc/hosts
echo -e "${current_ip}\t\thistoryserver.hadoop.docker.local" >> /etc/hosts