#!/bin/bash

## commons
export DEBIAN_FRONTEND=noninteractive
export TZ="UTC"

apt-get -y update
apt-get -y upgrade 
apt-get -y install vim iotop iputils-ping netcat dnsutils default-jdk byobu

apt-get -y install tzdata
ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

### Install jmeter
echo "jmeter hostname: ${jmeter_hostname}" >> /tmp//tmp/install.log
echo "bentier hostname: ${bentier_hostname}" >> /tmp//tmp/install.log
echo "jmeter download url: ${jmeter_release}" >> /tmp//tmp/install.log
echo "Run jmeter in port: ${jmeter_port}" >> /tmp//tmp/install.log
echo "jmeter in /opt/jmeter" >> /tmp//tmp/install.log
echo "Everything at /home/ubuntu/" >> /tmp/install.log

wget ${jmeter_release} -O jmeter.tgz
tar xvfz jmeter.tgz
rm jmeter.tgz
mv *jmeter* /opt/jmeter

chown -R ubuntu:ubuntu /opt/jmeter

echo 'export PATH="$PATH:/opt/jmeter/bin"' >> /home/ubuntu/.bashrc

export RMI_HOST_DEF=-Djava.rmi.server.hostname=${jmeter_hostname}
export SERVER_PORT=${jmeter_port} 
sudo -H -u ubuntu -c "/opt/jmeter/bin/jmeter-server  >& /tmp/jmeter.log &"
