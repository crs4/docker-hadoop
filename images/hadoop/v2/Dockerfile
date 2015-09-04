#----------------------------------------------------
# Apache Hadoop v2 Image
#----------------------------------------------------

# Set hadoop-2.x as base image
FROM kikkomep/docker-hadoop-base

# Set HADOOP ENV
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_CONF_DIR ${HADOOP_HOME}/etc/hadoop
RUN echo "export HADOOP_HOME=${HADOOP_HOME}" >> /home/${UNPRIV_USER}/.profile
RUN echo "export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> /home/${UNPRIV_USER}/.profile

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

# Set PATH of the default Apache Hadoop v2 configuration
ENV HADOOP_CUSTOM_CONF_DIR /opt/hadoop-v2-conf-base

# Copy configuration files (hadoop v2)
COPY config/* ${HADOOP_CUSTOM_CONF_DIR}/