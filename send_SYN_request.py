#!/usr/bin/env python
# coding: utf-8

from sys import stdin

import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import send
from scapy.all import IP, TCP

for line in stdin:
    tcp_syn = IP(dst=line.strip())/TCP(
        dport=80, sport=10003, seq=10003, flags="S",
    )
    send([tcp_syn, tcp_syn, tcp_syn, tcp_syn], verbose=0)
