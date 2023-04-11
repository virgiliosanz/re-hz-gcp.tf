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

# From hazelcast official guide
#wget -qO - https://repository.hazelcast.com/api/gpg/key/public | sudo apt-key add -
#echo "deb https://repository.hazelcast.com/debian stable main" | sudo tee -a /etc/apt/sources.list
#sudo apt update && sudo apt install hazelcast-management-center=5.2.1
# systemctl start hazelcast-management-center

# From github
git clone https://github.com/virgiliosanz/hazelcast-linux-service.git

cd hazelcast-linux-service

# Create the hazelcast user/group
groupadd -r hazelcast
useradd -r -g hazelcast -d /opt/hazelcast -s /sbin/nologin hazelcast

# Install Hazelcast
HAZELCAST_VERSION=5.2.3
wget https://github.com/hazelcast/hazelcast/releases/download/v$HAZELCAST_VERSION/hazelcast-$HAZELCAST_VERSION.zip
unzip hazelcast-$HAZELCAST_VERSION.zip -d /opt
ln -s /opt/hazelcast-$HAZELCAST_VERSION /opt/hazelcast
# Change owner of the Hazelcast directories and links
chown -R hazelcast:hazelcast /opt/hazelcast /opt/hazelcast-$HAZELCAST_VERSION

# Copy service and config files
rsync -r etc/ /etc

# Start and enable service
systemctl start hazelcast.service
systemctl enable hazelcast.service
systemctl daemon-reload

# Starting management console - Enter in dev mode
/opt/hazelcast/management-center/bin/hz-mc start
