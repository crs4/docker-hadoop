#----------------------------------------------------
# Apache Hadoop Base image
#----------------------------------------------------

# Set base image
FROM kikkomep/docker-hadoop:base

# Set HDFS data path
ENV HDFS_DATA_DIR opt/hadoop/data/hdfs

# Set admin-utils
ENV HADOOP_ADMIN_SCRIPTS /opt/admin-utils
RUN mkdir ${HADOOP_ADMIN_SCRIPTS}

# Add script for downloading and deploying the hadoop distro
ADD scripts/download-hadoop.sh ${HADOOP_ADMIN_SCRIPTS}/download-hadoop.sh
ADD scripts/deploy-hadoop.sh ${HADOOP_ADMIN_SCRIPTS}/deploy-hadoop.sh

# Add script for downloading and installing pydoop
ADD scripts/download-pydoop.sh ${HADOOP_ADMIN_SCRIPTS}/download-pydoop.sh

# Update $PATH to include ${HADOOP_ADMIN_SCRIPTS}
ENV PATH ${PATH}:${HADOOP_ADMIN_SCRIPTS}
RUN echo "export PATH=${PATH}:${HADOOP_ADMIN_SCRIPTS}" >> /etc/profile 