#----------------------------------------------------
# Hadoop 2.6.0 image
#----------------------------------------------------

# Set hadoop-2.x as base image
FROM kikkomep/docker-hadoop:hadoop-base

# set hadoop version
ENV HADOOP_VERSION 2.6.0

# Set HADOOP ENV
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_CONF_DIR ${HADOOP_HOME}/etc/hadoop
RUN echo "export HADOOP_HOME=${HADOOP_HOME}" >> /home/${UNPRIV_USER}/.profile
RUN echo "export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> /home/${UNPRIV_USER}/.profile

# download hadoop distro
COPY dist/hadoop-${HADOOP_VERSION}.tar.gz .
RUN deploy-hadoop.sh . ${HADOOP_VERSION} ${HADOOP_HOME}

# Copy configuration files
COPY config/* ${HADOOP_CONF_DIR}/

# Update $PATH to include ${HADOOP_HOME}/bin
ENV PATH ${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin
RUN echo "export PATH=${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin" >> /etc/profile 
RUN echo "export PATH=${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:/home/${UNPRIV_USER}/.local/bin" >> home/${UNPRIV_USER}/.profile

# Copy 'hadoop-admin' scripts
ADD scripts/start-resourcemanager.sh ${HADOOP_ADMIN_SCRIPTS}/start-resourcemanager.sh
ADD scripts/start-nodemanager.sh ${HADOOP_ADMIN_SCRIPTS}/start-nodemanager.sh
ADD scripts/start-namenode.sh ${HADOOP_ADMIN_SCRIPTS}/start-namenode.sh
ADD scripts/start-datanode.sh ${HADOOP_ADMIN_SCRIPTS}/start-datanode.sh
ADD scripts/start-historyserver.sh ${HADOOP_ADMIN_SCRIPTS}/start-historyserver.sh
ADD scripts/init-folders.sh ${HADOOP_ADMIN_SCRIPTS}/init-folders.sh
