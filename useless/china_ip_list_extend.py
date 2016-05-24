#!/bin/env python
# coding: utf-8

from socket import inet_aton, inet_ntoa
from struct import pack, unpack
from sys import stdout


def ip_to_int(ip):
    return unpack("!L", inet_aton(ip))[0]


def get_china_ip_range(r):
    base, length = r
    length = int(length)
    if int(length) == 32:
        return ip_to_int(base)
    return int("".join([
        bin(ip_to_int(base))[:length+2],
        "0"*(32-length)
    ]), 2), int("".join([
        bin(ip_to_int(base))[:length+2],
        "1"*(32-length)
    ]), 2)

with open("china_ip_list/china_ip_list.txt") as f:
    china_ip_list = f.read()
china_ip_list = china_ip_list.strip("\n").split("\n")
china_ip_list = map(
    lambda range_str: range_str.split("/"),
    china_ip_list,
)

china_ip_range = map(get_china_ip_range, china_ip_list)
china_ip = filter(lambda item: isinstance(item, int), china_ip_range)
china_ip_fuck = filter(lambda item: not isinstance(item, int), china_ip_range)

for ip in china_ip:
    stdout.write(inet_ntoa(pack("!L", ip)) + "\n")
for tuple_range in china_ip_fuck:
    # record = "{start} {stop}\n".format(
    #     start=inet_ntoa(pack("!L", tuple_range[0])),
    #     stop=inet_ntoa(pack("!L", tuple_range[1])),
    # )
    # stdout.write(record)
    for ip in range(tuple_range[0], tuple_range[1]+1):
        stdout.write(inet_ntoa(pack("!L", ip)) + "\n")
