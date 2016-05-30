#!/bin/bash

# 开启debug模式 排序按C模式
set -x
export LC_ALL=C

ALEXA_DOWNLOAD_URL="http://s3.amazonaws.com/alexa-static/top-1m.csv.zip"

ERROR_LOG="useless/log_error"

DNS_RECORD="scan_log/$(date +%y_%m_%d_DNS_record)"
SEND_HOST="scan_log/$(date +%y_%m_%d_foreign_ip_list)"
RECV_HOST="scan_log/$(date +%y_%m_%d_syn_ack_list)"
DIFF="scan_log/$(date +%y_%m_%d_diff)"
HOST_LOST="scan_log/$(date +%y_%m_%d_lost)"

pushd /home/nightwish/block_scan

# 获取配置参数
source .fuck_info

# 从alexa下载每日更新的全球前1M域名
wget $ALEXA_DOWNLOAD_URL -e use_proxy=yes -e http_proxy=$PROXY_INSTANCE -O top1m.zip 2> /dev/null
rm useless/top-1m.csv
unzip -d useless top1m.zip
rm top1m.zip

touch $DNS_RECORD $RECV_HOST

# 打开监控 关注域名的返回
(sudo python recieve_DNS_record.py 2> $ERROR_LOG >> $DNS_RECORD)&

# 向GOOGLE DNS服务器查询A记录
cut -d, -f2 useless/top-1m.csv|sudo python send_DNS_request.py &> $ERROR_LOG

# 休息五分钟后把没有解析结果的域名再查一遍
sleep 2m
comm -23 <(cut -d, -f2 useless/top-1m.csv|sort) \
    <(cut -d ' ' -f1 $DNS_RECORD|sort -u) \
    | sudo python send_DNS_request.py &> $ERROR_LOG

# 休息五分钟后杀掉上个后台任务
# http://stackoverflow.com/questions/1624691/linux-kill-background-task
sleep 2m
sudo kill $!

# 找出所有外国IP 移除IPV4中的保留地址
comm -23 <(cat $DNS_RECORD|cut -d ' ' -f3|grep '^[0-9\.]\{7,15\}$'|sort -u) <(zcat china_ip.gz) \
    |grep -v -f reserved_IP_block_regex|sort -u >> $SEND_HOST

# 打开监控 关注syn-ack或rst-ack的返回
(sudo python recieve_ACK_or_RST.py 2> $ERROR_LOG >> $RECV_HOST)&

# 同IP建立握手
cat $SEND_HOST|sudo python send_SYN_request.py &> $ERROR_LOG

# 休息八分钟后杀掉上个后台任务
# http://stackoverflow.com/questions/1624691/linux-kill-background-task
sleep 2m
sudo kill $!

comm -23 <(cat $SEND_HOST) <(cut -d ' ' -f 2 $RECV_HOST|sort -u) > $DIFF

scp -P $HONGKONG_PORT $DIFF $HONGKONG_HOST:~/block_scan/$DIFF
ssh -p $HONGKONG_PORT $HONGKONG_HOST "cd block_scan; bash foriegn_alive_check.sh hongkong"

LC_ALL=C join -1 2 -2 1 \
	<( cat useless/top-1m.csv | sed 's/,/ /g' | LC_ALL=C sort -k 2) \
	<( LC_ALL=C join -1 3 -2 1 \
		<(cat $DNS_RECORD| LC_ALL=C sort -k 3 -u) \
		<(cat $DIFF| LC_ALL=C sort -k 1) \
        | awk '{print $2, $3, $1}' | LC_ALL=C sort -k 1 \
	) | sort -k 2 -n | awk '{print $2, $1, $3, $4}' > $HOST_LOST

popd
