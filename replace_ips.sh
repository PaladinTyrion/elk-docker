#!/bin/bash
# author: paladintyrion

# if [ $# -lt 2 ]; then
#   echo "Usage: ./replace_ips.sh es_9200_replace_ips kafka_9092_replace_ips"
# fi
#
# if [ -z "$1" ]; then
#   echo "没有输入es_9200_replace_ips"
#   exit
# fi
#
# if [ -z "$2" ]; then
#   echo "没有输入kafka_9092_replace_ips"
#   exit
# fi
#
# es_ips=$1
# echo "需要替换的es_ip地址为:" $es_ips
# kafka_ips=$2
# echo "需要替换的kafka_ip地址为:" $kafka_ips
#
# # #testfile
# test_file="/Users/paladintyrion/test/testfile"
# echo "仅测试使用:" $test_file

#### start

kafka_input_file="/etc/logstash/conf.d/00-kafka-input.conf"
# echo "需要替换的kafka_input_file为:" $kafka_input_file
es_out_file="/etc/logstash/conf.d/30-output.conf"
# echo "需要替换的es_out_file为:" $es_out_file
es_conf_file="/etc/elasticsearch/elasticsearch.yml"
# echo "需要替换的es_conf_file为:" $es_conf_file
host_name=`hostname`

if [ ! -z "$ES_IPS" ]; then
  es_ips="$ES_IPS"
fi

if [ ! -z "$KAFKA_IPS" ]; then
  kafka_ips="$KAFKA_IPS"
fi

if [ ! -z "$GROUP_ID" ]; then
  group_id="$GROUP_ID"
fi

##### replace starts
oldIFS="$IFS"
IFS=","

# deal with es_ip
es_arr=()
es_tcp_arr=()
for es_ip in $es_ips;
do
  es_arr=("${es_arr[@]}" "\"${es_ip}:9200\"")
  es_tcp_arr=("${es_tcp_arr[@]}" "\"${es_ip}:9300\"")
done
es_ips_res="[${es_arr[*]// /,}]"
es_tcp_ips_res="[${es_tcp_arr[*]// /,}]"
es_cluster_expect="${#es_arr[@]}"
es_cluster_min="$[${#es_arr[@]}/2+1]"

# deal with kafka_ip
kafka_arr=()
for kafka_ip in $kafka_ips;
do
  kafka_arr=("${kafka_arr[@]}" "${kafka_ip}:9092")
done
kafka_ips_res="\"${kafka_arr[*]// /,}\""

IFS="$oldIFS"
##### replace ends


##### modify the all configure
if [ ${#kafka_arr[@]} -gt 0 ]; then
  # replace logstash kafka input
  sed -i -e "s/bootstrap_servers =>.*$/bootstrap_servers => $kafka_ips_res/g" $kafka_input_file
fi

if [ ${#es_arr[@]} -gt 0 ]; then
  # replace logstash elasticsearch output
  sed -i -e "s/hosts =>.*$/hosts => $es_ips_res/g" $es_out_file
  # replace elasticsearch configure *.yml unicast.hosts
  sed -i -e "s/^discovery.zen.ping.unicast.hosts:.*$/discovery.zen.ping.unicast.hosts: $es_tcp_ips_res/g" $es_conf_file
  # replace elasticsearch configure *.yml min runs
  sed -i -e "s/^gateway.recover_after_nodes:.*$/gateway.recover_after_nodes: $es_cluster_min/g" $es_conf_file
  sed -i -e "s/^discovery.zen.minimum_master_nodes:.*$/discovery.zen.minimum_master_nodes: $es_cluster_min/g" $es_conf_file
  # replace elasticsearch configure *.yml expected nodes
  sed -i -e "s/^gateway.expected_nodes:.*$/gateway.expected_nodes: $es_cluster_expect/g" $es_conf_file
fi

# control other param of logstash configure
# kafka-input
sed -i -e "s/client_id =>.*$/client_id => \"${group_id}-${host_name}\"/g" $kafka_input_file
sed -i -e "s/group_id =>.*$/group_id => \"$group_id\"/g" $kafka_input_file
