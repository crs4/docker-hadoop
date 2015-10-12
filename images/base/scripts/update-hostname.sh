#!/usr/bin/env bash

ok=-1
while [[ ${ok} != 0 ]]; do
    sleep 1
    hostname
    ok=$?
done


cp /etc/hosts /tmp/hosts
sed -i "s/$(/bin/hostname --ip-address).*/$(/bin/hostname --ip-address)\t$(/bin/hostname) $(/bin/hostname -s)/" /tmp/hosts
cat /tmp/hosts > /etc/hosts
