#----------------------------------------------------
# Apache Hadoop Base image
#----------------------------------------------------

# Set base image
FROM kikkomep/docker-base

# Set admin-utils
ENV HADOOP_ADMIN_SCRIPTS /opt/admin-utils
RUN mkdir ${HADOOP_ADMIN_SCRIPTS}

# Add script for downloading and deploying the hadoop distro
ADD scripts/download-hadoop.sh ${HADOOP_ADMIN_SCRIPTS}/download-hadoop.sh
ADD scripts/deploy-hadoop.sh ${HADOOP_ADMIN_SCRIPTS}/deploy-hadoop.sh

# Update $PATH to include ${HADOOP_ADMIN_SCRIPTS}
ENV PATH ${PATH}:${HADOOP_ADMIN_SCRIPTS}
RUN echo "export PATH=${PATH}:${HADOOP_ADMIN_SCRIPTS}" >> /etc/profile 