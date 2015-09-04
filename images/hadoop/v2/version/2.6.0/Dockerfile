#----------------------------------------------------
# Hadoop 2.6.0 image
#----------------------------------------------------

# Set hadoop-2.x as base image
FROM kikkomep/docker-hadoop-v2

# set hadoop version
ENV HADOOP_VERSION 2.6.0

# set hadoop tar.gz archivename
ENV HADOOP_ARCHIVE_TARGZ hadoop-${HADOOP_VERSION}.tar.gz

# download hadoop distro
COPY ${HADOOP_ARCHIVE_TARGZ} .
RUN ${HADOOP_ADMIN_SCRIPTS}/deploy-hadoop.sh . ${HADOOP_ARCHIVE_TARGZ} ${HADOOP_VERSION} ${HADOOP_HOME}

# Copy configuration files (hadoop v2)
COPY ${HADOOP_CONF_DIR_CUSTOM}/* ${HADOOP_CONF_DIR}/