#!/bin/bash

# Generic
apt-get -y update
apt-get -y upgrade
apt-get -y install vim
apt-get -y install iotop
apt-get -y install iputils-ping
apt-get -y install git
apt-get -y install unzip
apt-get -y install byobu

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

echo "node id: ${node_id}" >> /tmp/install.log
echo "node 1 ip: ${node_1_ip}" >> /tmp/install.log
echo "HZ Release to install: ${HZ_release}" >> /tmp/install.log
echo "Everything at /home/ubuntu/" >> /tmp/install.log

# install hazelcast
########### Enterprise
#wget https://repository.hazelcast.com/download/hazelcast-enterprise/hazelcast-enterprise-${HZ_release}.tar.gz
#tar xfz hazelcast-enterprise-${HZ_release}.tar.gz --directory /opt
#ln -s /opt/hazelcast-enterprise-${HZ_release} /opt/hazelcast


########### Open Source
HZ_DEST_PATH=/opt/hazelcast
wget https://github.com/hazelcast/hazelcast/releases/download/v${HZ_release}/hazelcast-${HZ_release}.zip
unzip hazelcast-${HZ_release}.zip -d /opt
ln -s /opt/hazelcast-${HZ_release} ${HZ_DEST_PATH}


mv ${HZ_DEST_PATH}/config/hazelcast.xml ${HZ_DEST_PATH}/config/hazelcast.xml.bak
wget https://raw.githubusercontent.com/virgiliosanz/re-hz-gcp.tf/main/misc/hazelcast.xml -O ${HZ_DEST_PATH}/config/hazelcast.xml
sed -i -E "s/{ip_hz_1}/${node_id}/" ${HZ_DEST_PATH}/config/hazelcast.xml


# Change owner of the Hazelcast directories and links
chown -R ubuntu:ubuntu ${HZ_DEST_PATH} /opt/hazelcast-${HZ_release}

sudo -H -u ubuntu bash -c "${HZ_DEST_PATH}/bin/hz start >& /tmp/hz.log &"

if [ "${node_id}" -eq "1" ];
then
  sudo -H -u ubuntu bash -c "${HZ_DEST_PATH}/management-center/bin/hz-mc start >& /tmp/hz-mc.log &"
fi
