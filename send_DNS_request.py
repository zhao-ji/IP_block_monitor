#!/usr/bin/env python
# coding: utf-8

from sys import stdin

import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import send
from scapy.all import IP, UDP, DNS, DNSQR

for line in stdin:
    dns_query = IP(dst="8.8.8.8")/UDP(sport=10002, dport=53)/DNS(
        rd=1, qd=DNSQR(qname=line.strip(), qtype=1),
    )
    send([dns_query, dns_query, dns_query], verbose=0)
