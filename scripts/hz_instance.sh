#!/bin/bash
#
# Write everything to /tmp/install.log
exec 3>&1 4>&2 1>>/tmp/install.log 2>&1
# Prints commands, prefixing them with a character stored in an environmental variable ($PS4)
set -x

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

echo "node id: ${node_id}"
echo "node 1 ip: ${node_1_ip}"
echo "HZ Release to install: ${HZ_release}"
echo "Everything at /home/ubuntu/"

# install hazelcast
########### Enterprise
#wget https://repository.hazelcast.com/download/hazelcast-enterprise/hazelcast-enterprise-${HZ_release}.tar.gz
#tar xfz hazelcast-enterprise-${HZ_release}.tar.gz --directory /opt
#ln -s /opt/hazelcast-enterprise-${HZ_release} /opt/hazelcast


########### Open Source
wget https://github.com/hazelcast/hazelcast/releases/download/v${HZ_release}/hazelcast-${HZ_release}.zip
unzip hazelcast-${HZ_release}.zip -d /opt
ln -s /opt/hazelcast-${HZ_release} /opt/hazelcast


mv /opt/hazelcast/config/hazelcast.xml /opt/hazelcast/config/hazelcast.xml.bak
wget https://raw.githubusercontent.com/virgiliosanz/re-hz-gcp.tf/main/misc/hazelcast.xml -O /opt/hazelcast/config/hazelcast.xml


# Change owner of the Hazelcast directories and links
chown -R ubuntu:ubuntu /opt/hazelcast /opt/hazelcast-${HZ_release}

sudo -H -u ubuntu bash -c "/opt/hazelcast/bin/hz start >& /tmp/hz.log &"

if [ "${node_id}" -eq "1" ];
then
  sed -i -E "s/\{ip_hz_1\}/$(hostname -I | awk '{print $1}')/" /opt/hazelcast/config/hazelcast.xml
  sudo -H -u ubuntu bash -c "/opt/hazelcast/management-center/bin/hz-mc start >& /tmp/hz-mc.log &"
else
  sed -i -E "s/\{ip_hz_1\}/${node_1_ip}/" /opt/hazelcast/config/hazelcast.xml
fi
