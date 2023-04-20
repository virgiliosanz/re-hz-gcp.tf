#!/bin/bash

## commons
export DEBIAN_FRONTEND=noninteractive
export TZ="UTC"

apt-get -y update
apt-get -y upgrade 
apt-get -y install vim iotop iputils-ping netcat dnsutils default-jdk

apt-get -y install tzdata
ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

### Install jmeter
echo "jmeter hostname: ${jmeter_hostname}" >> install.log
echo "app hostname: ${app_hostname}" >> install.log
echo "jmeter download url: ${jmeter_release}" >> install.log
echo "Run jmeter in port: ${jmeter_port}" >> install.log
echo "jmeter in /opt/jmeter" >> install.log

wget ${jmeter_release} -O jmeter.tgz
tar xvfz jmeter.tgz
rm jmeter.tgz
mv jmeter* /opt/jmeter

echo 'export PATH="$PATH:/opt/jmeter/bin"' >> ~/.bashrc
export RMI_HOST_DEF=-Djava.rmi.server.hostname=${jmeter_hostname}
export SERVER_PORT=${jmeter_port} 
/opt/jmeter/bin/jmeter-server 
