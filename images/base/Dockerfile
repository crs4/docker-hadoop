###############################################################################
# A basic machine with java and other basic services
###############################################################################

# Set Ubuntu as base image
FROM ubuntu:latest

# Set noninteractive mode
#ENV DEBIAN_FRONTEND noninteractive

# Install basic devtools
RUN apt-get update && \
    apt-get install -y -qq build-essential \
                       software-properties-common \
                       python-setuptools \
                       python-all-dev \
                       python-pip \
                       ipython \
                       libssl-dev zip \
                       wget git \ 
                       openssh-server openssh-client \
                       dnsutils nano \
                       nfs-common inotify-tools
# psutil
RUN pip install psutil
                       

# Install Java8 and set JAVA_HOME
# - Java version to be installed
ENV JAVA_VERSION 8
# --> accept license
RUN echo debconf shared/accepted-oracle-license-v1-1 select true | \
    sudo debconf-set-selections && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | \
    sudo debconf-set-selections
# --> install
RUN add-apt-repository ppa:webupd8team/java && \
    apt-get update && \
    apt-get install -y oracle-java${JAVA_VERSION}-installer
# --> set JAVA_HOME
ENV JAVA_HOME /usr/lib/jvm/java-${JAVA_VERSION}-oracle
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> /etc/profile

# add default user
ENV DEFAULT_USER hduser
RUN useradd -m ${DEFAULT_USER} -s /bin/bash && \
    echo "${DEFAULT_USER}:hadoop" | chpasswd && \
    echo "export PATH=${PATH}:/home/${DEFAULT_USER}/.local/bin" >> /home/${DEFAULT_USER}/.profile

# Set the working dir
WORKDIR /home/${DEFAULT_USER}

# add ${DEFAULT_USER} to the admin group
RUN groupadd admin
RUN usermod  -a -G admin ${DEFAULT_USER}

# disable ipv6
RUN echo "net.ipv6.conf.all.disable_ipv6 = 1"     >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.eth0.disable_ipv6 = 1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.ethwe.disable_ipv6 = 1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.lo.disable_ipv6 = 1"      >>  /etc/sysctl.conf

# java_opts for disabling IPv6
#ENV _JAVA_OPTIONS "-Djava.net.preferIPv4Stack=true"

# add script for updating the hostname within /etc/hosts
ADD scripts/update-hostname.sh /usr/bin/update-hostname

# Setup SSH server
RUN mkdir /var/run/sshd
RUN echo 'root:screencast' | chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# passphraseless ssh (required by hadoop)    
RUN mkdir -p /root/.ssh && \
    ssh-keygen -t dsa -P '' -f /root/.ssh/id_dsa && \
    cat /root/.ssh/id_dsa.pub >> /root/.ssh/authorized_keys && \
    echo "NoHostAuthenticationForLocalhost=yes" >> ~/.ssh/config

# set dir permissions
RUN chown -R ${DEFAULT_USER} /opt
    
# Add script for downloading and installing pydoop
ADD scripts/download-pydoop.sh /usr/bin/download-pydoop
ADD scripts/install-pydoop.sh /usr/bin/install-pydoop

# Add script for configuring a local DNS
ADD scripts/update-etc-hosts.sh /usr/bin/update-etc-hosts

# Add script for starting the client
ADD scripts/start-container.sh /usr/bin/

# Set shared NFS folder
ENV SHARING_MOUNT_POINT /sharing

# Add scripts for mounting NFS
ADD scripts/nfs-client.sh /usr/bin/nfs-client
ADD scripts/init-shared-folders.sh /usr/bin/init-shared-folders
    
# Expose the port 22
# EXPOSE 22

# Start the client services
CMD ["/usr/bin/start-container.sh"]
