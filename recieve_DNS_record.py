#!/usr/bin/env python
# coding: utf-8

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
