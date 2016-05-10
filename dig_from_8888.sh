#!/bin/sh
# utf8

ALEXA_DOWNLOAD_URL="http://s3.amazonaws.com/alexa-static/top-1m.csv.zip"
TODAY_RECORD="scan_log/$(date +%y_%m_%d_record)"

# 从alexa下载每日更新的全球前1M域名
pushd /home/nightwish/block_scan
wget $ALEXA_DOWNLOAD_URL -O top1m.zip 2> /dev/null
rm top-1m.csv
unzip top1m.zip
touch $TODAY_RECORD

# 打开监控 关注域名的返回
(sudo TODAY_RECORD=$TODAY_RECORD python -c '
from os import environ
import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import sniff
from scapy.all import IP, UDP, DNS, DNSRR

def store(pkg):
    if pkg.haslayer(UDP) and pkg.haslayer(DNS):
        if pkg[IP].src == "8.8.8.8" and pkg[DNSRR]:
			for result in pkg[DNSRR]:
				r.write(
					"{name} {type} {address}\n".format(
						name=result.rrname.rstrip("."),
						type=result.type,
						address=result.rdata,
					)
				)

with open(environ["TODAY_RECORD"], "a") as r:
    sniff(store=0, filter="src host 8.8.8.8 and udp port 53", prn=store)
' &> /dev/null) &

# 向GOOGLE DNS服务器查询A记录
cut -d, -f2 top-1m.csv|head -n 100| sudo python -c '
from sys import stdin
import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import send
from scapy.all import IP, UDP, DNS, DNSQR

for line in stdin:
    dns_query = IP(dst="8.8.8.8")/UDP(dport=53)/DNS(
		rd=1,
		qd=DNSQR(qname=line.strip(), qtype=1),
	)
    send([dns_query, dns_query, dns_query])
' &> /dev/null

# 休息三分钟后杀掉上个后台任务
# http://stackoverflow.com/questions/1624691/linux-kill-background-task
sleep 8m
sudo kill $!

popd
