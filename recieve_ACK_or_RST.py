#!/usr/bin/env python
# coding: utf-8

from sys import stdout

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
        stdout.write(record)

if __name__ == "__main__":
    filter_string = (
        "tcp src port 80 and tcp dst port 10003 and tcp[8:4]==10004 "
        "and (tcp[tcpflags]==18 or tcp[tcpflags]==20)"
    )
    sniff(store=0, prn=store, filter=filter_string)
