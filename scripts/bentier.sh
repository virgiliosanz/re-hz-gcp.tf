#!/bin/bash

echo "$(date) - PREPARING machine" >> /tmp/install.log


apt-get -y update
apt-get -y upgrade 
apt-get -y install vim iotop iputils-ping netcat dnsutils openjdk-17-jdk byobu


export DEBIAN_FRONTEND=noninteractive
export TZ="UTC"
apt-get -y install tzdata
ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

echo "Everything at /home/ubuntu/" >> /tmp/install.log
echo "You need to setup the connection to the redis db you created and the hazelcast cluster" >> /tmp/install.log
echo "${cluster_dns}" >> /tmp/install.log
echo "${RS_admin}" >> /tmp/install.log
echo "${RS_password}" >> /tmp/install.log
echo "Setup Hazelcast" >> /tmp/install.log
echo "HZ node IPs: " >> /tmp/install.log
echo "${hz_node_ips}" >> /tmp/install.log
echo "setup jvm.options: " >> /tmp/install.log
echo "change port to 8080" >> /tmp/install.log
echo "spring.data.redis.url="redis://user:password@example.com:6379"" >> /tmp/install.log
echo "Setup hazelcast" >> /tmp/install.log
echo "Then run:" >> /tmp/install.log
echo "./mvn spring-boot:run" >> /tmp/install.log

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
cp -f /home/ubuntu/jvm.options /home/ubuntu/redis-bentier/src/main/resources

wget https://raw.githubusercontent.com/virgiliosanz/re-hz-gcp.tf/main/misc/hazelcast-client.xml -O /home/ubuntu/hazelcast-client.xml
IPs=""
for IP in ${hz_node_ips}; do
  IPs+="<address>$IP</address>" 
done
sed -i -E "s/\{hz_node_ips\}/$IPs/" /home/ubuntu/hazelcast-client.xml
cp -f /home/ubuntu/hazelcast-client.xml /home/ubuntu/redis-bentier/src/main/resources

wget https://dlcdn.apache.org/maven/maven-3/3.9.1/binaries/apache-maven-3.9.1-bin.tar.gz
tar xvfz apache-maven-3.9.1-bin.tar.gz
mv apache-maven-3.9.1 /home/ubuntu/maven
echo "export PATH=\$PATH:/home/ubuntu/maven/bin/" >> /home/ubuntu/.bashrc
ln -s /home/ubuntu/maven/bin/mvn /home/ubuntu/.local/bin/mvn

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
