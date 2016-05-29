#!/usr/bin/env python
# coding: utf-8

from sys import stdin, stdout

import logging
logging.getLogger("scapy.runtime").setLevel(logging.ERROR)

from scapy.all import sr
from scapy.all import IP, TCP

for line in stdin:
    distination = line.strip()
    tcp_syn = [
        IP(dst=distination, ttl=ttl)/TCP(dport=80, flags="S")
        for ttl in range(6, 16)
    ]
    ans, unans = sr(tcp_syn, verbose=0, timeout=1, multi=False)

    result = {}
    for ans_tuple in ans:
        packet_send, packet_recv = ans_tuple
        ttl = packet_send[IP].ttl
        route_IP = packet_recv[IP].src
        result[ttl] = route_IP
    for unans_packet in unans:
        result[unans_packet[IP].ttl] = None

    tracepath = []
    for i in range(6, 16):
        tracepath.append(result.get(i, None) or ".")
    path_with_IP = "\t".join(tracepath)
    stdout.write(distination + "\t" + path_with_IP + "\n")
