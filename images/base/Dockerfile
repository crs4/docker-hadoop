#----------------------------------------------------
# A basic java machine with java, basic services and iv6 disabled
#----------------------------------------------------

# Set Ubuntu as base image
FROM ubuntu:latest

# Set noninteractive mode
ENV DEBIAN_FRONTEND noninteractive

# Install basic devtools
RUN apt-get update && \
    apt-get install -y build-essential \
                       software-properties-common \
                       python-setuptools \
                       python-all-dev \
                       python-pip \
                       ipython \
                       libssl-dev zip \
                       wget git \ 
                       openssh-server openssh-client \
                       dnsutils  
                       

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

# add default unprivileged user (Alfred E. Neuman, "What? Me worry?")
ENV UNPRIV_USER aen
RUN useradd -m ${UNPRIV_USER} -s /bin/bash && \
    echo "${UNPRIV_USER}:hadoop" | chpasswd && \
    echo "export PATH=${PATH}:/home/${UNPRIV_USER}/.local/bin" >> /home/${UNPRIV_USER}/.profile

# add aen to the admin group    
RUN groupadd admin
RUN usermod  -a -G admin $UNPRIV_USER
    
# disable ipv6
RUN echo "net.ipv6.conf.all.disable_ipv6=1"     >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.default.disable_ipv6=1" >> /etc/sysctl.conf && \
    echo "net.ipv6.conf.lo.disable_ipv6=1"      >>  /etc/sysctl.conf

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
RUN chown -R aen /opt
    
# add script for starting the client
ADD scripts/start-container.sh /usr/bin/
    
# Expose the port 22
EXPOSE 22

# Start the client services
CMD ["/usr/bin/start-client.sh"]