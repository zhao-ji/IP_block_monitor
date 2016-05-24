#!/usr/bin/env python
# coding: utf-8

from sys import stdin, stdout


def get_rank_number(ip_int, rank_int=4):
    return (
        ip_int % 2 ** (8 * rank_int)
        -
        ip_int % (2 ** (8 * (rank_int - 1)))
    ) / 2 ** (8 * (rank_int - 1))


if __name__ == "__main__":
    for line in stdin:
        base, mask = line.strip("\n").strip("\r").split("/")
        base_int = reduce(
            lambda summary, i: summary * 2 ** 8 + i,
            map(int, base.split(".")),
            0,
        )
        for i in xrange(2 ** (32 - int(mask))):
            ip_int = base_int + i

            ip_split = map(
                lambda j: get_rank_number(ip_int, j),
                range(4, 0, -1),
            )

            ip_str = ".".join(map(str, ip_split))
            stdout.write(ip_str + "\n")
