#!/bin/bash

export DEBIAN_FRONTEND=noninteractive
export TZ="UTC"

apt-get -y update
apt-get -y upgrade 
apt-get -y install vim iotop iputils-ping netcat dnsutils default-jdk

apt-get -y install tzdata
ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

echo "You need to setup the connection to the redis db you created and the hazelcast cluster"
echo "${cluster_dns}" >> install.log
echo "${RS_admin}" >> install.log
echo "${RS_password}" >> install.log

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
tar xfz redis-bentier.tgz

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
# ./mvnw spring-boot:run

