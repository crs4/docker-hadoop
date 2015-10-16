###############################################################################
# Apache Hadoop v2 Image
###############################################################################

# Set hadoop-2.x as base image
FROM crs4/hadoop-apache-base

# Set HADOOP ENV
ENV HADOOP_HOME /opt/hadoop
ENV HADOOP_CONF_DIR ${HADOOP_HOME}/etc/hadoop
ENV HADOOP_DATA_DIR ${HADOOP_HOME}/data
ENV HADOOP_LOG_DIR ${HADOOP_HOME}/logs
ENV HDFS_DATA_DIR ${HADOOP_DATA_DIR}/hdfs
ENV YARN_DATA_DIR ${HADOOP_DATA_DIR}/yarn

RUN echo "export HADOOP_HOME=${HADOOP_HOME}" >> /home/${DEFAULT_USER}/.profile
RUN echo "export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> /home/${DEFAULT_USER}/.profile

# Update $PATH to include ${HADOOP_HOME}/bin
ENV PATH ${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin
RUN echo "export PATH=${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin" >> /etc/profile 
RUN echo "export PATH=${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin:/home/${DEFAULT_USER}/.local/bin" >> /home/${DEFAULT_USER}/.profile

# Copy 'hadoop-admin' scripts
ADD scripts/start-resourcemanager.sh ${HADOOP_ADMIN_SCRIPTS}/start-resourcemanager.sh
ADD scripts/start-nodemanager.sh ${HADOOP_ADMIN_SCRIPTS}/start-nodemanager.sh
ADD scripts/start-namenode.sh ${HADOOP_ADMIN_SCRIPTS}/start-namenode.sh
ADD scripts/start-datanode.sh ${HADOOP_ADMIN_SCRIPTS}/start-datanode.sh
ADD scripts/start-historyserver.sh ${HADOOP_ADMIN_SCRIPTS}/start-historyserver.sh
ADD scripts/init-hdfs-folders.sh ${HADOOP_ADMIN_SCRIPTS}/init-hdfs-folders.sh
ADD scripts/start-hadoop-services.sh ${HADOOP_ADMIN_SCRIPTS}/start-hadoop-services

# Set PATH of the default Apache Hadoop v2 configuration
ENV HADOOP_CUSTOM_CONF_DIR /opt/hadoop-v2-conf-base

# Copy configuration files (hadoop v2)
COPY config/* ${HADOOP_CUSTOM_CONF_DIR}/

# Set the default command
CMD ["start-hadoop-services"]