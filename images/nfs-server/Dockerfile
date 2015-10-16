###############################################################################
# NFS Server image
###############################################################################

# Set base image
FROM crs4/docker-base

RUN apt-get update -qq && apt-get install -y nfs-kernel-server runit inotify-tools -qq
RUN mkdir -p /exports

RUN mkdir -p /etc/sv/nfs

ADD scripts/nfs.init /etc/sv/nfs/run
ADD scripts/nfs.stop /etc/sv/nfs/finish
ADD scripts/nfs_setup.sh /usr/bin/nfs_setup

# Export shared NFS folder
VOLUME /sharing

EXPOSE 111/udp 2049/tcp

ENTRYPOINT ["/usr/bin/nfs_setup"]