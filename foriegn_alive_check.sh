#!/bin/sh

STATION=$1
TODAY_RECORD="scan_log/$(date +%y_%m_%d_$STATION)"
TODAY_LUCKY="scan_log/$(date +%y_%m_%d_block_ip)"
ERROR_LOG="scan_log/log_error"

touch $TODAY_RECORD

# 打开监控 关注syn-ack或rst-ack的返回
(sudo TODAY_RECIEVE_LIST=$TODAY_RECORD python -c '
from os import environ

import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import sniff
from scapy.all import IP, TCP

def store(pkg):
    if pkg.haslayer(TCP):
        r.write("{flags} {address}\n".format(
            flags=pkg[TCP].flags, address=pkg[IP].src))

with open(environ["TODAY_RECIEVE_LIST"], "a") as r:
    sniff(
        store=0, prn=store,
        filter="tcp src port 80 and tcp dst port 10003 and tcp[8:4]==10004 and (tcp[tcpflags]==18 or tcp[tcpflags]==20)",
    )
' &> $ERROR_LOG ) &

# 同IP建立握手
cat $TODAY_LUCKY|sudo python -c '
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
    send([tcp_syn, tcp_syn, tcp_syn], verbose=0)
' &> $ERROR_LOG

# 休息三分钟后杀掉上个后台任务
# http://stackoverflow.com/questions/1624691/linux-kill-background-task
sleep 5m
sudo kill $!

source .fuck_info

scp -P $BEIJING_PORT $TODAY_RECORD $BEIJING_HOST:~/block_scan/$TODAY_RECORD
