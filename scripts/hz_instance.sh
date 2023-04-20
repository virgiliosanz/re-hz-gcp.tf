#!/bin/bash

# Generic
apt-get -y update
apt-get -y upgrade
apt-get -y install vim
apt-get -y install iotop
apt-get -y install iputils-ping
apt-get -y install git
apt-get -y install unzip

apt-get install -y netcat
apt-get install -y dnsutils
export DEBIAN_FRONTEND=noninteractive
export TZ="UTC"
apt-get install -y tzdata
ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

# install jdk
sudo apt-get install -y default-jdk 
sudo apt-get install -y maven

# install hazelcast

# Create the hazelcast user/group
groupadd -r hazelcast
useradd -r -g hazelcast -d /opt/hazelcast -s /sbin/nologin hazelcast


########### Enterprise
wget https://repository.hazelcast.com/download/hazelcast-enterprise/hazelcast-enterprise-${HZ_release}.tar.gz
tar xfz hazelcast-enterprise-${HZ_release}.tar.gz --directory /opt


########### Open Source
#wget https://github.com/hazelcast/hazelcast/releases/download/v${HZ_release}/hazelcast-${HZ_release}.zip
#unzip hazelcast-${HZ_release}.zip -d /opt


ln -s /opt/hazelcast-${HZ_release} /opt/hazelcast

# Change owner of the Hazelcast directories and links
chown -R hazelcast:hazelcast /opt/hazelcast /opt/hazelcast-${HZ_release}

# save backup for default config
mv /opt/hazelcast/config/hazelcast.xml /opt/hazelcast/config/hazelcast.xml.bak
