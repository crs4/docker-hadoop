#!/usr/bin/env python

import sys
import math
import logging
import optparse
from os import path
from os import makedirs
from xml.dom import minidom
import xml.etree.cElementTree as ET
from psutil import virtual_memory
import multiprocessing

log = logging.getLogger(__name__)
out_hdlr = logging.StreamHandler(sys.stdout)
out_hdlr.setFormatter(logging.Formatter('- %(message)s'))
out_hdlr.setLevel(logging.INFO)
log.addHandler(out_hdlr)
log.setLevel(logging.INFO)


class YarnNodeConfigurator:
    # reserved for HBase. Map: Memory => Reservation
    reserved_hbase = {4: 1, 8: 1, 16: 2, 24: 4, 48: 8, 64: 8, 72: 8, 96: 16,
                      128: 24, 256: 32, 512: 64}
    # reserved for OS + DN + NM,  Map: Memory => Reservation
    reserved_stack = {4: 1, 8: 2, 16: 2, 24: 4, 48: 6, 64: 8, 72: 8, 96: 12,
                      128: 24, 256: 32, 512: 64}
    # minimum ram size in MBytes
    minimum_ram_size = {4: 256, 8: 512, 24: 1024}

    # instance properties
    sys_cores = None
    sys_memory = None
    sys_disks = None

    # path of the actual HDFS_CONF_DIR
    hdfs_conf_dir = "."

    def __init__(self,
                 hdfs_conf_dir=".", namenode="localhost", resourcemanager="localhost",
                 sys_cores=None, sys_memory=None, sys_disks=None):
        self.sys_cores = sys_cores if sys_cores else multiprocessing.cpu_count()
        self.sys_memory = sys_memory if sys_memory else virtual_memory().total / (1024 * 1024 * 1024)
        self.sys_disks = sys_disks if sys_disks else 1
        self.hdfs_conf_dir = hdfs_conf_dir
        self.namenode = namenode
        self.resourcemanager = resourcemanager

    def _find_lower_bound(self, config, param):
        key = value = None
        counter = 1
        for p in sorted(config):
            v = config[p]
            if key == value == None:
                key, value = p, v
            if p > param or counter == len(config):
                break
            key, value = p, v
            if p == param:
                break
            counter += 1
        return key, value

    def container_minimum_memory(self):
        nm, cm = self._find_lower_bound(self.minimum_ram_size, self.sys_memory)
        return cm

    def reserved_stack_memory(self):
        nm, sm = self._find_lower_bound(self.reserved_stack, self.sys_memory)
        return sm

    def reserved_hbase_memory(self):
        nm, hm = self._find_lower_bound(self.reserved_hbase, self.sys_memory)
        return hm

    def configure(self, enable_hbase=False):

        container_minimum_memory = self.container_minimum_memory()
        reserved_stack_memory = self.reserved_stack_memory()
        reserved_hbase_memory = self.reserved_hbase_memory() if enable_hbase else 0

        total_reserved_memory = reserved_stack_memory + reserved_hbase_memory
        total_available_memory = self.sys_memory - total_reserved_memory

        if (total_available_memory < 2):
            total_available_memory = 2
            total_reserved_memory = max(0, total_available_memory - total_reserved_memory)

        # mem in MB
        total_available_memory *= 1024

        # number of containers
        containers = int(min(2 * self.sys_cores,
                             math.ceil(1.8 * float(self.sys_disks)),
                             total_available_memory / container_minimum_memory))

        # computer container RAM
        container_ram = max(container_minimum_memory, (total_available_memory / containers))

        # mapper RAM
        map_memory = container_ram

        # reduce RAM
        reduce_memory = container_ram if containers <= 2 else 2 * container_ram
        # reduce_memory = 2 * container_ram

        # am RAM
        am_memory = max(map_memory, reduce_memory)

        log.info("Number of Core: %s", self.sys_cores)
        log.info("Number of Disks: %s", self.sys_disks)
        log.info("Enabled HBase: %s", enable_hbase)
        log.info("Total System Memory: %s GB", self.sys_memory)
        log.info("Total Reserved Memory: %s GB", total_reserved_memory)
        log.info("Total Available Memory: %s GB", total_available_memory / 1024)
        log.info("Number of Containers: %s", containers)
        log.info("Container RAM: %s MB", container_ram)
        log.info("Container Minimum Memory: %s MB", container_minimum_memory)
        log.info("Total reserved memory: %s GB", total_reserved_memory)
        log.info("Total available memory: %s MB", total_available_memory)

        return YarnNodeConfiguration(self.hdfs_conf_dir, self.namenode,
                                     self.resourcemanager,
                                     containers, container_ram, total_reserved_memory,
                                     map_memory, reduce_memory, am_memory)

    def print_node_info(self):
        log.info("Number of cores: %s", self.sys_cores)
        log.info("Total memory: %s", self.sys_memory)


class Writer:
    def add_property(self, conf, name, value):
        prop = ET.SubElement(conf, 'property')
        ET.SubElement(prop, 'name').text = name
        ET.SubElement(prop, 'value').text = value

    def write_xml(self, root, fname):
        print "- Writing %s" % fname

        xml = ET.tostring(root, encoding='utf8', method='xml')
        reparsed = minidom.parseString(xml)
        dirname = path.dirname(path.realpath(fname))
        if not path.exists(dirname):
            makedirs(dirname)
        with open(fname, 'w') as f:
            f.write(reparsed.toprettyxml(indent="    "))

    def generate_xml_conf_file(self, fname, props):
        root = ET.Element("configuration")
        for name, value in props.iteritems():
            self.add_property(root, name, value)
        self.write_xml(root, fname)


class YarnNodeConfiguration:
    # node configuration
    containers = None
    ontainer_ram = None
    total_reserved_memory = None
    map_memory = None
    reduce_memory = None
    am_memory = None

    #
    def __init__(self, hdfs_conf_dir, namenode, resourcemanager,
                 containers, container_ram, total_reserved_memory,
                 map_memory, reduce_memory, am_memory):
        self.hdfs_conf_dir = hdfs_conf_dir
        self.namenode = namenode
        self.resourcemanager = resourcemanager
        self.containers = containers
        self.container_ram = container_ram
        self.total_reserved_memory = total_reserved_memory
        self.map_memory = map_memory
        self.reduce_memory = reduce_memory
        self.am_memory = am_memory
        # writer instance
        self.writer = Writer()

    def get_mapreduce_properties(self):
        return (
            ("mapreduce.map.memory.mb", str(self.map_memory)),
            ("mapreduce.map.java.opts", "-Xmx" + str(int(0.8 * self.map_memory)) + "m"),
            ("mapreduce.reduce.memory.mb", str(self.reduce_memory)),
            ("mapreduce.reduce.java.opts", "-Xmx" + str(int(0.8 * self.reduce_memory)) + "m"),
            ("yarn.app.mapreduce.am.resource.mb", str(self.am_memory)),
            ("yarn.app.mapreduce.am.command-opts", "-Xmx" + str(int(0.8 * self.am_memory)) + "m"),
            # ('mapreduce.jobhistory.address', 'historyserver.hadoop.docker.local:10020'),
            # ('mapreduce.jobhistory.webapp.address', 'historyserver.hadoop.docker.local:19888'),
            ("mapreduce.task.io.sort.mb", str(int(0.4 * self.map_memory)))
        )

    def get_yarn_properties(self):
        return (
            ("yarn.scheduler.minimum-allocation-mb", str(self.container_ram)),
            ("yarn.scheduler.maximum-allocation-mb", str(self.containers * self.container_ram)),
            ("yarn.nodemanager.resource.memory-mb", str(self.containers * self.container_ram))
        )

    def generate_core_site(self):
        self.writer.generate_xml_conf_file(path.join(self.hdfs_conf_dir, "core-site.xml"), {
            'fs.defaultFS': 'hdfs://%s:9000' % self.namenode,
            'fs.default.name': 'hdfs://%s:9000' % self.namenode
        })

    def generate_hdfs_site(self):
        self.writer.generate_xml_conf_file(path.join(self.hdfs_conf_dir, "hdfs-site.xml"), {
            'dfs.replication': '1',
            'dfs.namenode.name.dir': 'file:////opt/hadoop/data/hdfs/primary-namenode',
            'dfs.namenode.checkpoint.dir': 'file:////opt/hadoop/data/hdfs/secondary-namenode',
            'dfs.datanode.data.dir': 'file:////opt/hadoop/data/hdfs/datanode',
            'dfs.permissions.supergroup': 'admin',
            'dfs.namenode.fs-limits.min-block-size': '512',
            'dfs.namenode.secondary.http-address': 'localhost:50090'
        })

    def generate_mapred_site(self):
        properties = {
            'mapreduce.jobtracker.address': self.resourcemanager + ':8021',
            'mapreduce.jobtracker.http.address': self.resourcemanager + ':50030',
            'mapreduce.framework.name': 'yarn',
            'mapreduce.jobhistory.intermediate-done-dir': '/tmp/hadoop-mapreduce/intermediate/${user.name}/tasks',
            'mapreduce.jobhistory.done-dir': '/tmp/hadoop-mapreduce/done/${user.name}/tasks',
            'mapreduce.task.tmp.dir': '/tmp/hadoop-mapreduce/cache/${user.name}/tasks'
        }
        properties.update(self.get_mapreduce_properties())
        self.writer.generate_xml_conf_file(path.join(self.hdfs_conf_dir, "mapred-site.xml"), properties)

    def generate_yarn_site(self):
        properties = {
            'yarn.resourcemanager.webapp.address': '0.0.0.0:8088',
            'yarn.resourcemanager.hostname': self.resourcemanager,
            'yarn.nodemanager.aux-services': 'mapreduce_shuffle',
            'yarn.nodemanager.aux-services.mapreduce.shuffle.class': 'org.apache.hadoop.mapred.ShuffleHandler',
            'yarn.log-aggregation-enable': 'true',
            'yarn.dispatcher.exit-on-error': 'true',
            'yarn.nodemanager.local-dirs': '/opt/hadoop/data/yarn/nm-local-dir',
            'yarn.nodemanager.log-dirs': '/opt/hadoop/logs/yarn/containers',
            'yarn.nodemanager.remote-app-log-dir': '/opt/hadoop/logs/yarn/apps',
            'yarn.nodemanager.vmem-pmem-ratio': '2.8'
        }
        properties.update(self.get_yarn_properties())
        self.writer.generate_xml_conf_file(path.join(self.hdfs_conf_dir, "yarn-site.xml"), properties)

    def generate_config_files(self):
        self.generate_core_site()
        self.generate_mapred_site()
        self.generate_yarn_site()
        self.generate_hdfs_site()


def parse_cli_options():
    mem = virtual_memory()

    parser = optparse.OptionParser()

    parser.add_option('-c', '--cores', default=multiprocessing.cpu_count(),
                      help='Number of cores on each host')
    parser.add_option('-m', '--memory', default=(mem.total / (1024 * 1024 * 1024)),
                      help='Amount of Memory on each host in GB')
    parser.add_option('-d', '--disks', default=1,
                      help='Number of disks on each host')
    parser.add_option('-k', '--hbase', default=False,
                      help='True if HBase is installed, False is not')
    parser.add_option('--resourcemanager', default="resourcemanager.hadoop.docker.local",
                      help='The hostname of the resourcemanager')
    parser.add_option('--namenode', default="namenode.hadoop.docker.local",
                      help='The hostname of the namenode')
    parser.add_option('--hadoop-conf-dir', default=".",
                      help='The HADOOP_CONF_DIR path')
    (options, args) = parser.parse_args()
    return (options, args)


def main(argv):
    options, args = parse_cli_options()
    configurator = YarnNodeConfigurator(
        hdfs_conf_dir=options.hadoop_conf_dir,
        sys_cores=int(options.cores),
        sys_memory=int(options.memory),
        sys_disks=int(options.disks),
        resourcemanager=options.resourcemanager,
        namenode=options.namenode)

    node_config = configurator.configure(options.hbase)
    node_config.generate_config_files()


main(sys.argv)
