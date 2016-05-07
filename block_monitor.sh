#!/bin/sh
# utf8

function tcp_fast_ping {
	fuck=$(sudo hping3 --fast --count 10 --numeric -q --destport 80 --syn $1 3>&1 1>/dev/null 2>&3)
	lost_rate=$(echo $fuck|awk '{print $12}'|cut -d '%' -f 1)
	if [ "$lost_rate" = "100" ]
	then
		TODAY_BLOCK_RESULT=$(date +%y_%m_%d_80_record)
		echo $2 $1 >> "/home/nightwish/block_scan/scan_log/$TODAY_BLOCK_RESULT"
	fi
}

function detect {
	domain=$1

	# 查询DNS 获取网站IP 两次不成就跳过 域名别名跳过 只取点分十进制IP
	ip_list=$(dig @8.8.8.8 +short $domain|grep -o '[.0-9]*')
	if [ -z "$ip_list" ]
	then
		ip_list=$(dig @8.8.8.8 +short $domain|grep -o '[.0-9]*')
	fi
	if [ -z "$ip_list" ]
	then
		return
	fi

	for ip in $ip_list
	do
		tcp_fast_ping $ip $domain
	done
}

function main {
    export -f detect
	export -f tcp_fast_ping
	cat /home/nightwish/block_scan/top-1m.csv|cut -d ',' -f 2|xargs --max-lines=1 --max-procs=120 -I DOMAIN bash -c  'detect DOMAIN'
}

function unit_test {
    export -f detect
	export -f tcp_fast_ping
    cat /home/nightwish/block_scan/top-1m.csv|cut -d ',' -f 2|head -n 10|xargs --max-lines=1 --max-procs=10 -I DOMAIN bash -c  'detect DOMAIN'
}

date
main
date
# unit_test
