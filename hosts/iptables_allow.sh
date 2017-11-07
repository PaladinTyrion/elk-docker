#!/bin/bash
# author: paladintyrion

if [ $# -eq 0 ]; then
    echo "Usage: ./iptables_allow.sh [5601_allow_ips,[ip1,ip2,ip3,...]]"
fi

if [ -z "$1" ]; then
    echo "没有输入5601_allow_ips"
    exit
fi

# define sth.
ipta_file="/etc/sysconfig/iptables"
del_arr=("REJECT" "COMMIT")

# install latest iptables
yum install -y iptables-services

# if iptables_file not exists, create it
if [ ! -f $ipta_file ];then
    echo "touch $ipta_file"
    touch $ipta_file
fi

# delete the reject rules
if [ ${#del_arr[@]} -ne 0 ];then
    for delcon in "${del_arr[@]}";
    do
        INFO=$(grep "${delcon}" $ipta_file)
        if [ ! -z "$INFO" ]; then
             sed -i -e "/${delcon}/d" $ipta_file
        fi
    done
fi

# add new ACCEPT rules
ips=$1
echo "允许5601的ip地址为:" $ips

echo "#控制端口" >> $ipta_file
oldIFS="$IFS"
#自定义分隔符
IFS=","
for ip in $ips;
do
    echo "-A INPUT -s $ip -p tcp --dport 5601 -j ACCEPT" >> $ipta_file
done
IFS="$oldIFS"
echo "-A INPUT -p tcp --dport 5601 -j DROP" >> $ipta_file
echo "COMMIT" >> $ipta_file

# restart iptables service
service iptables restart
