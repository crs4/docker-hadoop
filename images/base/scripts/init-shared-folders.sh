#!/bin/bash

nfs_enabled=${1}
nfs_shared_paths=${2}

if [[ ${nfs_enabled} == true ]]; then
    echo "Mounting...."
    /usr/bin/nfs-client "${SHARING_MOUNT_POINT}:${SHARING_MOUNT_POINT}"

    mounts=(${nfs_shared_paths//,/ })

    for mnt in "${mounts[@]}"; do
        echo "Exporting ${mnt} (user: ${DEFAULT_USER})... "
        mkdir -p "${SHARING_MOUNT_POINT}${mnt}"
        chown -R ${DEFAULT_USER}:${DEFAULT_USER} "${SHARING_MOUNT_POINT}${mnt}"
        ln -s "${SHARING_MOUNT_POINT}${mnt}" ${mnt}
	    chown -R ${DEFAULT_USER}:${DEFAULT_USER} ${mnt}
    done

    # user folder on the sharing mount point
    USER_HOME="${SHARING_MOUNT_POINT}/home/${DEFAULT_USER}"
    mkdir -p ${USER_HOME}
    chown -R ${DEFAULT_USER}:${DEFAULT_USER} ${USER_HOME}

    echo "export SHARING_MOUNT_POINT=${SHARING_MOUNT_POINT}" >> /home/${DEFAULT_USER}/.profile
    echo "export PATH=$PATH:${USER_HOME}/.local/bin" >> /home/${DEFAULT_USER}/.profile
    echo "export PYTHONPATH=${USER_HOME}" >> /home/${DEFAULT_USER}/.profile
    echo "export PYTHONUSERBASE=${USER_HOME}/.local" >> /home/${DEFAULT_USER}/.profile
fi
