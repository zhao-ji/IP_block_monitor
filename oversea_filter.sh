#!/bin/bash

# my origin data crawl from https://scans.io

TODAY_80_ACK=$(date +%y_%m_%d_80_ack)
TODAY_80_RST=$(date +%y_%m_%d_80_rst)
TODAY_443_ACK=$(date +%y_%m_%d_443_ack)
TODAY_443_RST=$(date +%y_%m_%d_443_rst)
( sudo \
    TODAY_80_ACK=$TODAY_80_ACK TODAY_80_RST=$TODAY_80_RST \
    TODAY_443_ACK=$TODAY_443_ACK TODAY_443_RST=$TODAY_443_RST \
    python -c '
from os import environ
import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import sniff
from scapy.all import IP, TCP

def store_pkg(pkg):
    if pkg.haslayer(IP) and pkg.haslayer(TCP):
        if pkg[TCP].sport == 80 and pkg[TCP].flags == 18 and pkg[TCP].ack == 2:
            ack_80.write(pkg[IP].src+"\n")
        elif pkg[TCP].sport == 80 and pkg[TCP].flags == 20 and pkg[TCP].ack == 2:
            rst_80.write(pkg[IP].src+"\n")
        elif pkg[TCP].sport== 443 and pkg[TCP].flags == 18 and pkg[TCP].ack == 2:
            ack_443.write(pkg[IP].src+"\n")
        elif pkg[TCP].sport == 443 and pkg[TCP].flags == 20 and pkg[TCP].ack == 2:
            rst_443.write(pkg[IP].src+"\n")

with open(environ["TODAY_80_ACK"], "a") as ack_80, \
    open(environ["TODAY_80_RST"], "a") as rst_80, \
    open(environ["TODAY_443_ACK"], "a") as ack_443, \
    open(environ["TODAY_443_RST"], "a") as rst_443:
    sniff(
        store=0, iface="eth1",
        filter="dst host 101.200.190.85 and tcp dst port 55555",
        prn=store_pkg,
    )
' &> /dev/null) &

cat http_80_ip_sorted | sudo python -c '
from sys import stdin
import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import send
from scapy.all import IP, TCP

for line in stdin:
    print line
    tcp_syn = IP(dst=line.strip())/TCP(dport=80, sport=55555, flags="S", seq=1)
    send(tcp_syn)
' &> /dev/null

cat https_443_ip_sorted | sudo python -c '
from sys import stdin
import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import send
from scapy.all import IP, TCP

for line in stdin:
    print line
    tcp_syn = IP(dst=line.strip())/TCP(dport=443, sport=55555, flags="S", seq=1)
    send(tcp_syn)
' &> /dev/null

sleep 8m
sudo kill $!
