#!/bin/sh
# utf8

function tcp_fast_ping {
    read ip
	fuck=$(sudo hping3 --fast --count 50 --numeric -q --destport 80 --syn $ip 3>&1 1>/dev/null 2>&3)
	lost_rate=$(echo $fuck|awk '{print $12}'|cut -d '%' -f 1)
	if [ "$lost_rate" = "100" ]
	then
		echo $ip
	# else
	# 	echo $lost_rate
	fi
}

function detect {
while read domain
do
	ip_list=$(dig @8.8.8.8 +short $domain)
	if [ -z "$ip_list" ]
	then
		ip_list=$(dig @8.8.8.8 +short $domain)
	fi
	block_ip=$(echo $ip_list|grep -o '[.0-9]*'|head -n 1|tcp_fast_ping)
	if [ -n "$block_ip" ]
	then
		echo $domain $block_ip
	fi
done
}

function main {
cat top-1m.csv|cut -d ',' -f 2|detect
}

function unit_test {
    echo "twitter.com"|detect
}

main
