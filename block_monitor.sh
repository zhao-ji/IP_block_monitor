#!/bin/sh

ALEXA_DOWNLOAD_URL="http://s3.amazonaws.com/alexa-static/top-1m.csv.zip"
ERROR_LOG="scan_log/log_error"

TODAY_RECORD="scan_log/$(date +%y_%m_%d_DNS_record)"
TODAY_SEND_LIST="scan_log/$(date +%y_%m_%d_foreign_ip_list)"
TODAY_RECIEVE_LIST="scan_log/$(date +%y_%m_%d_syn_ack_list)"
TODAY_DIFF="scan_log/$(date +%y_%m_%d_diff)"

pushd /home/nightwish/block_scan

# 从alexa下载每日更新的全球前1M域名
rm top1m.zip top-1m.csv
wget $ALEXA_DOWNLOAD_URL -O top1m.zip 2> /dev/null
unzip top1m.zip
rm top1m.zip

touch $TODAY_RECORD $TODAY_RECIEVE_LIST

# 打开监控 关注域名的返回
(sudo TODAY_RECORD=$TODAY_RECORD python -c '
from os import environ

import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import sniff
from scapy.all import IP, UDP, DNS, DNSQR, DNSRR

def store(pkg):
    if pkg.haslayer(DNS) and pkg.haslayer(DNSRR):
        for i in range(pkg[DNS].ancount):
            if pkg[DNSRR][i].type == 1:
                record = "{domain} {name} {address}\n".format(
                    domain=pkg[DNSQR].qname.rstrip("."),
                    name=pkg[DNSRR][i].rrname.rstrip("."),
                    address=pkg[DNSRR][i].rdata,
                )
                r.write(record)

with open(environ["TODAY_RECORD"], "a") as r:
    sniff(store=0, filter="src host 8.8.8.8 and udp port 53 and udp port 10002", prn=store)
' &> $ERROR_LOG ) &

# 向GOOGLE DNS服务器查询A记录
cut -d, -f2 top-1m.csv|sudo python -c '
from sys import stdin

import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import send
from scapy.all import IP, UDP, DNS, DNSQR

for line in stdin:
    dns_query = IP(dst="8.8.8.8")/UDP(sport=10002, dport=53)/DNS(
        rd=1,
        qd=DNSQR(qname=line.strip(), qtype=1),
    )
    send([dns_query, dns_query, dns_query])
' &> $ERROR_LOG

# 休息三分钟后杀掉上个后台任务
# http://stackoverflow.com/questions/1624691/linux-kill-background-task
sleep 3m
sudo kill $!

# 找出所有外国IP 移除IPV4中的保留地址
comm -23 <(cat $TODAY_RECORD|cut -d ' ' -f 3|grep '^[0-9\.]\{7,15\}$'|sort -u) <(gzip -cd china_ip.gz) \
    |grep -v -f reserved_address_block_regex|sort -u >> $TODAY_SEND_LIST

# 打开监控 关注syn-ack或rst-ack的返回
(sudo TODAY_RECIEVE_LIST=$TODAY_RECIEVE_LIST python -c '
from os import environ

import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import sniff
from scapy.all import IP, TCP

def store(pkg):
    if pkg.haslayer(TCP):
        record = "{flags} {address}\n".format(
            flags=pkg[TCP].flags,
            address=pkg[IP].src,
        )
        r.write(record)

with open(environ["TODAY_RECIEVE_LIST"], "a") as r:
    filter_string = (
        "tcp src port 80 and tcp dst port 10003 and tcp[8:4]==10004 "
        "and (tcp[tcpflags]==18 or tcp[tcpflags]==20)"
    )
    sniff(store=0, prn=store, filter=filter_string)
' &> $ERROR_LOG ) &

# 同IP建立握手
cat $TODAY_SEND_LIST|sudo python -c '
from sys import stdin

import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import send
from scapy.all import IP, TCP

for line in stdin:
    tcp_syn = IP(dst=line.strip())/TCP(
        dport=80, sport=10003,
        seq=10003, flags="S",
    )
    send([tcp_syn, tcp_syn, tcp_syn, tcp_syn], verbose=0)
' &> $ERROR_LOG

# 休息八分钟后杀掉上个后台任务
# http://stackoverflow.com/questions/1624691/linux-kill-background-task
sleep 8m
sudo kill $!

comm -23 <(cat $TODAY_SEND_LIST) <(cut -d ' ' -f 2 $TODAY_RECIEVE_LIST|sort -u) > $TODAY_DIFF

source .fuck_info
scp -P $HONGKONG_PORT $TODAY_DIFF $HONGKONG_HOST:~/block_scan/$TODAY_DIFF
ssh -p $HONGKONG_PORT $HONGKONG_HOST "cd block_scan; bash foriegn_alive_check.sh hongkong"
# scp -P $SEATTLE_PORT $TODAY_DIFF $SEATTLE_HOST:~/block_scan/$TODAY_DIFF
# ssh -p $SEATTLE_PORT $SEATTLE_HOST "cd block_scan; bash foriegn_alive_check.sh hongkong"

popd
