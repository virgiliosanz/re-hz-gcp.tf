#!/bin/bash

echo "$(date) - PREPARING machine" >> /tmp/install.log


apt-get -y update
apt-get -y upgrade 
apt-get -y install vim iotop iputils-ping netcat dnsutils openjdk-17-jdk maven byobu


export DEBIAN_FRONTEND=noninteractive
export TZ="UTC"
apt-get -y install tzdata
ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

echo "You need to setup the connection to the redis db you created and the hazelcast cluster" >> /tmp/install.log
echo "${cluster_dns}" >> /tmp/install.log
echo "${RS_admin}" >> /tmp/install.log
echo "${RS_password}" >> /tmp/install.log
echo "Everything at /home/ubuntu/" >> /tmp/install.log

## redis-benchmark and redis-cli
wget -O redis-stack.tar.gz https://packages.redis.io/redis-stack/redis-stack-server-6.2.6-v6.bionic.x86_64.tar.gz
tar xfz redis-stack.tar.gz
mv redis-stack-* redis-stack
mkdir -p /home/ubuntu/.local/bin
ln -s /home/ubuntu/install/redis-stack/bin/redis-benchmark /home/ubuntu/.local/bin/redis-benchmark
ln -s /home/ubuntu/install/redis-stack/bin/redis-cli /home/ubuntu/.local/bin/redis-cli

# for "sudo su - ubuntu"
chown -R ubuntu:ubuntu /home/ubuntu/install
chown -R ubuntu:ubuntu /home/ubuntu/.local

# installing app
wget https://github.com/virgiliosanz/re-hz-gcp.tf/raw/main/misc/redis-bentier.tgz
tar xfz redis-bentier.tgz
mv redis-bentier /home/ubuntu/

wget https://raw.githubusercontent.com/virgiliosanz/re-hz-gcp.tf/main/misc/jvm.options -O /home/ubuntu/jvm.options

chown -R ubuntu:ubuntu /home/ubuntu

# For: spring boot jvm.options
# 
# Option 1:
#
# spring.data.redis.host=16
# spring.data.redis.port=3000
# spring.data.redis.password=
# spring.data.redis.username=
#
# Option 1:
#
# spring.data.redis.url="redis://user:password@example.com:6379"
#
# Then:
# mvn -N io.takari:maven:wrapper
# ./mvnw spring-boot:run
echo "setup jvm.options: " >> /tmp/install.log
echo "spring.data.redis.url="redis://user:password@example.com:6379"" >> /tmp/install.log
echo "Setup hazelcast" >> /tmp/install.log
echo "Then run:" >> /tmp/install.log
echo "mvn -N io.takari:maven:wrapper" >> /tmp/install.log
echo "./mvnw spring-boot:run" >> /tmp/install.log
