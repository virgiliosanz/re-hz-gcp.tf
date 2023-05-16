#!/bin/bash
#
# Write everything to /tmp/install.log
exec 3>&1 4>&2 1>>/tmp/install.log 2>&1
# Prints commands, prefixing them with a character stored in an environmental variable ($PS4)
set -x

################
# PREREQ 
#
echo "$(date) - PREPARING machine node"

apt-get -y update
apt-get -y upgrade
apt-get -y install vim
apt-get -y install iotop
apt-get -y install iputils-ping
apt-get -y install byobu

apt-get install -y netcat
apt-get install -y dnsutils
export DEBIAN_FRONTEND=noninteractive
export TZ="UTC"
apt-get install -y tzdata
ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata

# cloud instance have no swap anyway
#swapoff -a
#sed -i.bak '/ swap / s/^(.*)$/#1/g' /etc/fstab
echo 'DNSStubListener=no' | tee -a /etc/systemd/resolved.conf
mv /etc/resolv.conf /etc/resolv.conf.orig
ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
service systemd-resolved restart
sysctl -w net.ipv4.ip_local_port_range="40000 65535"
echo "net.ipv4.ip_local_port_range = 40000 65535" >> /etc/sysctl.conf

echo "$(date) - PREPARE done"

################
# RS
#
echo "$(date) - INSTALLING Redis Enterprise"

mkdir /home/ubuntu/install
wget "${RS_release}" -P /home/ubuntu/install
tar xvf /home/ubuntu/install/redislabs*.tar -C /home/ubuntu/install

echo "$(date) - INSTALLING Redis Enterprise - silent installation"

cd /home/ubuntu/install
sudo /home/ubuntu/install/install.sh -y 2>&1 >> /home/ubuntu/install_rs.log
sudo adduser ubuntu redislabs

echo "$(date) - INSTALL done"

################
# NODE
#
node_external_addr=`curl ifconfig.me/ip`
echo "Node ${node_id} : $node_external_addr"
if [ ${node_id} -eq 1 ]; then
    echo "create cluster"
    echo "rladmin cluster create name ${cluster_dns} username ${RS_admin} password '${RS_password}' external_addr $node_external_addr flash_enabled "
    /opt/redislabs/bin/rladmin cluster create name ${cluster_dns} username ${RS_admin} password '${RS_password}' external_addr $node_external_addr flash_enabled 2>&1
else
    echo "joining cluster "
    echo "/opt/redislabs/bin/rladmin cluster join username ${RS_admin} password '${RS_password}' nodes ${node_1_ip} external_addr $node_external_addr flash_enabled replace_node ${node_id}"
    for i in {1..10}
    do
	    /opt/redislabs/bin/rladmin cluster join username ${RS_admin} password '${RS_password}' nodes ${node_1_ip} external_addr $node_external_addr flash_enabled replace_node ${node_id} 2>&1
    	if [ $? -eq 0 ]; then
	        break
    	else
            echo "master node not available, trying again in 30s..." 
	        sleep 30
    	fi
    done
fi
echo "$(date) - DONE creating cluster node"

################
# NODE external_addr - it runs at each reboot to update it
#
echo "${node_id}" > /home/ubuntu/node_index.terraform
cat <<EOF > /home/ubuntu/node_externaladdr.sh
#!/bin/bash
node_external_addr=\$(curl -s ifconfig.me/ip)

# Terraform node_id may not be Redis Enterprise node id
myip=\$(ifconfig | grep 10.26 | cut -d' ' -f10)
rs_node_id=\$(/opt/redislabs/bin/rladmin info node all | grep -1 \$myip | grep node | cut -d':' -f2)
/opt/redislabs/bin/rladmin node \$rs_node_id external_addr set \$node_external_addr
EOF
chown ubuntu /home/ubuntu/node_externaladdr.sh
chmod u+x /home/ubuntu/node_externaladdr.sh
/home/ubuntu/node_externaladdr.sh

echo "$(date) - DONE updating RS external_addr"
