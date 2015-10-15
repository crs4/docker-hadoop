# docker-hadoop

The purpose of **docker-hadoop**  is to provide a *full, standard, hadoop
cluster* that can be used for development or testing purposes. 

Currently, it provides support for the following Hadoop distributions:

- **Apache Hadoop:**
	- versions **2.*** (aka **YARN**): specifically **2.2.0**, **2.3.0**, **2.4.1**, **2.5.2**, **2.6.0**, **2.7.1**
 

####Supported working modes:

1. **single-container:** all hadoop services run within a single Docker container, exposing all services to the Docker host;
1. **multi-container:** every service runs in a different container; an additional container, the 'client' container, is used to connect to the Hadoop services and interact with them;
1. **multi-host-multi-container**: multiple Docker hosts constitute a Docker cluster and every Hadoop service runs in a different container deployed to one of the Docker cluster nodes. A *client* container is used to access to the dockerized Hadoop cluster.
 

 
## Requirements

To run **docker-hadoop**, your machine(s) must meet the following requirements:

- **docker** (>1.6.0): follow [Docker Supported installation][1] to install Docker on your platform. Please be sure the Docker daemon (on every host) is listening on an host port (e.g., default 2375): this can be obtained by setting the DOCKER\_OPTS env with the paramter `-H tcp://<HOST_IP>:<DOCKER_HOST>` (e.g., `-H tcp://0.0.0.0:2375`);
- **docker-compose** (>1.3.0): see [Install Docker Compose][2];
- **swarm** (>0.4.0): Docker automatically pulls the Docker Swarm image when needed;
- **weave** (>1.1.0): see [Weave installation][3];
- **weave scope** (>0.8.0) (optional): see [Weave Scope Getting Started][4].

Additional software for OS X users is required and available on Homebrew (see [Homebrew Install][5] to install Homebrew): *python 2.7, gnu-sed, coreutils, gnu-getopt*.

## How to use
All required Docker images are available on the DockerHub CRS4 repository and are automatically pulled when needed, but you can also locally build the required images (see [How to build 'docker-hadoop' images]).

As a general strategy to use *docker-hadoop* you have to:

* start `docker-hadoop` image version (e.g., hadoop-2.6.0) in a *single-container*, *multi-container* or *Docker cluster* mode (see below);
* login via ssh the *client container* (or run a new shell attached to the running container), which allows you to interact with the dockerized Hadoop services (i.e., HDFS, ResourceManager).

###### Client container

In order to use the dockerized Hadoop services running in a single container or multiple containers you have to access to the *client container* (which is the only active when you run *docker-hadoop* in *single-container mode*).

There are two different strategies to access to the client container:

1. *ssh login:* the client container runs an SSH server on the port 22 bounded to a port dynamically picked from the available ports of your Docker host. To see the ssh port, type `docker ps`:

        $ docker ps		 
          429e05554172 crs4/docker-hadoop-2.6.0  "/w/w start-container" 3 hours ago   
		               Up 3 hours  0.0.0.0:32775->22/tcp  dockerhadoop-client-1
    
	In the example above the port is 32775 and you can login to the *client container* as follows:
	
	    $ ssh -p 32775 hduser@<DOCKER_HOST_IP>
	
	where `hduser` is the default user (the corresponding password is: `hadoop`) and `DOCKER_HOST_IP` is the ip address of you Docker host.

	
2. *exec new attached shell*: you can execute a new shell attached to the running client container by means of the following command:

        $ docker exec -it 429e05554172 /bin/bash

    where `429e05554172` is the ID the running container obtained by the `docker ps` command above.


After you login via ssh or execute a new bash shell attached to the running container, you can immediately use the hadoop CLI (e.g., `hdfs dfs ...`, `hadoop`, `mapred`, etc.)


### Single Container

In this mode, all Hadoop services run within a single container. You can run the corresponding image:

* *interactive mode*: all Hadoop services will be started within a container and a bash shell will be attached to it in order for you to immediately use Hadoop services (e.g., submitting a job, exploring the HDFS, etc.);
 
* *background mode*: all Hadoop services will be started within a background container and you have to access to that container in order to use Hadoop services (see [client container]).


### Multi Container (single host)

The simplest way to start **docker-hadoop** in multi-container mode is to use the command `start-multi-container-services`. As an esample, considering the `hadoop-2.6.0` Hadoop distribution, you can start the Hadoop services typing:

```
./start-multi-container-services.sh --init-weave hadoop-2.6.0
```

The option `--init-weave` can be omitted if a Weave Network is already running and properly configured such that WeaveDNS uses the *docker-hadoop* domain (default domain is *hadoop.docker.local*).

Finally, you have to access to the *client container* to use Hadoop services via command line interface (CLI).


### Multi Container (multi host): Docker Cluster

In order to start *docker-hadoop* on a Docker cluster you have to provide a configuration file containing the hostnames of the Docker hosts which compose the cluster.

An example of cluster configuration file (e.g., `cluster.config`):

    172.31.2.200
    172.31.2.201
    172.31.2.202

Also, we assume that an admin user (e.g., `ubuntu` in our example) is able to access via ssh without password to every node of the cluster, as for Hadoop cluster configuration (see [HOWTO: Generating SSH Keys Paswordless Login][6]).

To autoconfigure a Swarm cluster over a Weave Network and start Hadoop services, you can use the following command:


    ./start-multi-host-services.sh --init-swarm \
	    --cluster-config cluster.config \
		--admin-user ubuntu \
		hadoop-2.6.0 


If you already have a running Swarm cluster over a Weave network, you can omit the options `--init-swarm`, `cluster-config` and `admin-user`.

As in [Multi container (single host)] above, you have to access to the *client container* to use Hadoop services via command line interface (CLI).
 
## Details

### How to build 'docker-hadoop' images


To build the *docker-hadoop* images you can use the provided script `build-image` with the following syntax:

```
./build-image.sh [options] <HADOOP_DISTRO>
```

 where `HADOOP_DISTRO` is the supported hadoop distribution to dockerized in a Docker image: e.g., `hadoop-2.6.0`.
 
 The available options are:
 
 * `-r | --repository <REPO_NAME>`: the tag repository of the Docker image (e.g., `crs4`, which is the default) ;
 * `-p | --prefix <IMAGE_PREFIX>`: the prefix of the Docker image name (e.g., `docker-`, which is the default).
 
 As an example, the command `./build-image.sh hadoop-2.6.0` produces the image named `crs4/docker-hadoop-2.6.0`.
 
### Update your /etc/hosts 

In order to easily use the Web Console apps of the Hadoop services you have to update your /etc/hosts in such a way that hostnames of the containers running the Hadoop services are correctly resolved. This can be easily done using the `net-utils/service-host-finder.sh` script:

	Usage: net-utils/service-host-finder.sh [options] [service_port/service_protocol[,...]
	       Available options:
		   -h | --host <DOCKER_ADDRESS>   the default value is the current DOCKER_HOST address
		   -p | --port <DOCKER_PORT>      the default value is the current DOCKER_HOST port
		   -u | --user <DOCKER_USER>      the default value is 'docker'
		   --save-hosts                   save host entries on your from your file, e.g., /etc/hosts (default)
		   -o | --output <FILE>           file for saving host entries, e.g. /etc/hosts (default)
		   --public-only                  only public addresses
		   --host-only                    only host addresses
		   --container-only               only container addresses
		   --clean                        remove host entries from your file, e.g., /etc/hosts (default)
		   --help                         print usage

For example, if you want to resolve the hostnames of the containers running Hadoop services to their corresponding Docker hosts, you can digit:

    $ net-utils/service-host-finder.sh --save-hosts --host-only \
	              8088/tcp,8042/tcp,19888/tcp,50070/tcp

which updates your `/etc/hosts` with a new set of entries like the following:

	##DOCKER-HADOOP-SERVICES>>
	10.211.55.7	dockerhadoop-nodemanager-1.hadoop.docker.local
	10.211.55.7	historyserver.hadoop.docker.local
	10.211.55.7	namenode.hadoop.docker.local
	10.211.55.7	resourcemanager.hadoop.docker.local
	>>DOCKER-HADOOP-SERVICES##

Finally, you can access the Web Console apps of the main Hadoop services directly from your browser using the following URLs:

* **ResourceManager** @ [http://resourcemanager.hadoop.docker.local:8088](http://resourcemanager.hadoop.docker.local:8088)
* **History Server** @ [http://historyserver.hadoop.docker.local:19888](http://namenode.hadoop.docker.local:19888)
* **NameNode** @ [http://namenode.hadoop.docker.local:50070](http://namenode.hadoop.docker.local:50070)


### Setup a Weave Network

To setup a Weave network you can follow the [Weave Getting Started Guides][7]. Alternatively you can use the provided script `net-utils/weave-swarm-network-manager.sh`:

    $ net-utils/weave-swarm-network-manager.sh [options] < launch | stop | help >
	  Options:
	  	   --config <CLUSTER_CONFIG> : the cluster config file
		   --weave					 : setup a weave network
           --swarm 					 : setupe a swarm cluster
           --admin <ADMIN_USER>		 : username of the cluster admin 


If `--config <CLUSTER_CONFIG>` is omitted, the weave services are assumed to be local and run only on the Docker host where you launch the `weave-swarm-network-manager.sh` script.

Finally, update your environment to use the weave tools:

    $ eval $(weave env)


### Setup a Swarm Cluster over a Weave Network

There are several strategies to setup a Docker Swarm cluster (see [Docker Swarm][8]). Alternatively you can use `net-utils/weave-swarm-network-manager.sh` script above with the additional option `--swarm`.

## References

- **Docker Supported installation**, [https://docs.docker.com/installation](https://docs.docker.com/installation)
- **Install Docker Compose**, [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/) 
- **Weave Installation**, [https://github.com/weaveworks/weave#installation](https://github.com/weaveworks/weave#installation)
- **Weave Scope**, [https://github.com/weaveworks/scope](https://github.com/weaveworks/scope)
- **Homebrew install**, [http://brew.sh](http://brew.sh)
- **HOWTO: Generating SSH Keys Paswordless Login**, [http://hortonworks.com/kb/generating-ssh-keys-for-passwordless-login/](http://hortonworks.com/kb/generating-ssh-keys-for-passwordless-login/)
- **Weave Getting Started Guides**, [http://weave.works/guides/index.html](http://weave.works/guides/index.html)
- **Docker Swarm**, [https://docs.docker.com/swarm/](https://docs.docker.com/swarm/)


<!-- -->

[1]: https://docs.docker.com/installation "Docker Supported installation"
[2]: https://docs.docker.com/compose/install/ "Install Docker Compose"
[3]: https://github.com/weaveworks/weave#installation "Weave Installation"
[4]: https://github.com/weaveworks/scope "Weave Scope"
[5]: http://brew.sh "Homebrew install"
[6]: http://hortonworks.com/kb/generating-ssh-keys-for-passwordless-login/ "HOWTO: Generating SSH Keys Paswordless Login"
[7]: http://weave.works/guides/index.html "Weave Getting Started Guides"
[8]: https://docs.docker.com/swarm/ "Docker Swarm"
