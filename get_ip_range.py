#!/bin/env python
# utf8

from socket import inet_aton
from struct import unpack


def ip_to_int(ip):
    return unpack("!L", inet_aton(ip))[0]

with open("world_ip_list.txt") as f:
    world_ip_list = f.read()

world_ip_list = world_ip_list.strip("\n").split("\n")
world_ip_list = map(
    lambda ip_range_str: ip_range_str.split(" "),
    world_ip_list)

world_ip_range = []
for ip_range in world_ip_list:
    ip_range = map(ip_to_int, ip_range)
    world_ip_range.append(ip_range)
world_ip_range.sort(key=lambda r: r[0])

with open("china_ip_list.txt") as f:
    china_ip_list = f.read()
china_ip_list = china_ip_list.strip("\n").split("\n")
china_ip_list = map(
    lambda range_str: range_str.split("/"),
    china_ip_list)

china_ip_range = []
for ip_range in china_ip_list:
    base, length = ip_range
    length = int(length)
    ip_start = int("".join([bin(ip_to_int(base))[:-length], "0"*length]), 2)
    ip_stop = int("".join([bin(ip_to_int(base))[:-length], "1"*length]), 2)
    china_ip_range.append([ip_start, ip_stop])
china_ip_range.sort(key=lambda r: r[0])

valid_range = []
for ip_type in world_ip_range:
    china_ip_list_in_this_range = filter(
        lambda ip_range:
        ip_range[0] >= ip_type[0] and ip_range[1] <= ip_type[1],
        china_ip_range
    )
    yes_start, yes_stop = ip_type
    valid_range.append([yes_start, yes_stop])
    for ip_china in china_ip_list_in_this_range:
        no_start, no_stop = ip_china
        if no_stop < yes_stop:
            valid_range[-1][1] = no_start
            valid_range.append([no_stop, yes_stop])

for r in valid_range:
    print r
