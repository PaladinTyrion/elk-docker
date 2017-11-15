#!/bin/bash

# install ifconfig nfs-client
yum install -y net-tools nfs-utils rpcbind
service rpcbind restart
service nfs restart
service nfslock restart

# create dir
mkdir -p /data0/kafka
mkdir -p /data0/elk/elasticsearch
mkdir -p /data0/elk/logstash
mkdir -p /data0/elk/kibana
mkdir -p /data0/logstashconf
chmod -R +x /data0/kafka
chmod -R +x /data0/elk
chmod +x /data0/logstashconf
chmod -R +r /data0/logstashconf

### create groups && users
# create kafka user
id "kafka" >& /dev/null
if [ $? -ne 0 ]
then
    groupadd -r kafka -g 440
    useradd -r -s /sbin/nologin -M -c "Kafka service user" -u 440 -g kafka kafka
fi
# create elasticsearch user
id "elasticsearch" >& /dev/null
if [ $? -ne 0 ]
then
    groupadd -r elasticsearch -g 441
    useradd -r -s /usr/sbin/nologin -M -c "Elasticsearch service user" -u 441 -g elasticsearch elasticsearch
fi
# create logstash user
id "logstash" >& /dev/null
if [ $? -ne 0 ]
then
    groupadd -r logstash -g 442
    useradd -r -s /usr/sbin/nologin -c "Logstash service user" -u 442 -g logstash logstash
fi
# create kibana user
id "kibana" >& /dev/null
if [ $? -ne 0 ]
then
    groupadd -r kibana -g 443
    useradd -r -s /usr/sbin/nologin -c "Kibana service user" -u 443 -g kibana kibana
fi
# chown groups && users
chown -R kafka:kafka /data0/kafka
chown -R elasticsearch:elasticsearch /data0/elk/elasticsearch
chown -R logstash:logstash /data0/elk/logstash
chown -R kibana:kibana /data0/elk/kibana

# get local_ip
local_ip=`/sbin/ifconfig -a | grep inet | grep -v 127.0.0.1 | grep -v inet6 | awk '{print $2}' | tr -d "addr:" | head -n 1`

# kafka mount dir
echo "10.85.92.7:/data2/${local_ip}.kafka /data0/kafka nfs auto,soft,bg,intr,rw,rsize=32768,wsize=32768 0 0" >> /etc/fstab
# elk mount dir
echo "10.85.92.7:/data2/${local_ip}.elk/elasticsearch /data0/elk/elasticsearch nfs auto,soft,bg,intr,rw,rsize=32768,wsize=32768 0 0" >> /etc/fstab
echo "10.85.92.7:/data2/${local_ip}.elk/logstash /data0/elk/logstash nfs auto,soft,bg,intr,rw,rsize=32768,wsize=32768 0 0" >> /etc/fstab
echo "10.85.92.7:/data2/${local_ip}.elk/kibana /data0/elk/kibana nfs auto,soft,bg,intr,rw,rsize=32768,wsize=32768 0 0" >> /etc/fstab
# logstash config
echo "10.85.92.7:/data2/logstashconf /data0/logstashconf nfs auto,soft,bg,intr,rw,rsize=32768,wsize=32768 0 0" >> /etc/fstab

# mount
mount -a
