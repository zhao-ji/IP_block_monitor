#!/bin/sh

ALEXA_DOWNLOAD_URL="http://s3.amazonaws.com/alexa-static/top-1m.csv.zip"
ERROR_LOG="scan_log/log_error"

TODAY_RECORD="scan_log/$(date +%y_%m_%d_DNS_record)"
TODAY_SEND_LIST="scan_log/$(date +%y_%m_%d_foreign_ip_list)"
TODAY_RECIEVE_LIST="scan_log/$(date +%y_%m_%d_syn_ack_list)"
TODAY_DIFF="scan_log/$(date +%y_%m_%d_diff)"

pushd /home/nightwish/block_scan
source .fuck_info

# 从alexa下载每日更新的全球前1M域名
rm top1m.zip top-1m.csv
wget $ALEXA_DOWNLOAD_URL -e use_proxy=yes -e http_proxy=$PROXY_INSTANCE -O top1m.zip 2> /dev/null
unzip top1m.zip

touch $TODAY_RECORD $TODAY_RECIEVE_LIST

# 打开监控 关注域名的返回
(sudo python recieve_DNS_record.py 2> $ERROR_LOG >> $TODAY_RECORD)&

# 向GOOGLE DNS服务器查询A记录
cut -d, -f2 top-1m.csv|sudo python send_DNS_request.py &> $ERROR_LOG

# 休息五分钟后把没有解析结果的域名再查一遍
sleep 5m
comm -23 <(cut -d, -f2 top-1m.csv|sort) <(cut -d ' ' -f1 $TODAY_RECORD|sort -u)\
    | sudo python send_DNS_request.py &> $ERROR_LOG

# 休息五分钟后杀掉上个后台任务
# http://stackoverflow.com/questions/1624691/linux-kill-background-task
sleep 5m
sudo kill $!

# 找出所有外国IP 移除IPV4中的保留地址
comm -23 <(cat $TODAY_RECORD|cut -d ' ' -f3|grep '^[0-9\.]\{7,15\}$'|sort -u) <(gzip -cd china_ip.gz) \
    |grep -v -f reserved_IP_block_regex|sort -u >> $TODAY_SEND_LIST

# 打开监控 关注syn-ack或rst-ack的返回
(sudo python recieve_ACK_or_RST.py 2> $ERROR_LOG >> $TODAY_RECIEVE_LIST)&

# 同IP建立握手
cat $TODAY_SEND_LIST|sudo python send_SYN_request.py &> $ERROR_LOG

# 休息八分钟后杀掉上个后台任务
# http://stackoverflow.com/questions/1624691/linux-kill-background-task
sleep 8m
sudo kill $!

comm -23 <(cat $TODAY_SEND_LIST) <(cut -d ' ' -f 2 $TODAY_RECIEVE_LIST|sort -u) > $TODAY_DIFF

scp -P $HONGKONG_PORT $TODAY_DIFF $HONGKONG_HOST:~/block_scan/$TODAY_DIFF
ssh -p $HONGKONG_PORT $HONGKONG_HOST "cd block_scan; bash foriegn_alive_check.sh hongkong"
# scp -P $SEATTLE_PORT $TODAY_DIFF $SEATTLE_HOST:~/block_scan/$TODAY_DIFF
# ssh -p $SEATTLE_PORT $SEATTLE_HOST "cd block_scan; bash foriegn_alive_check.sh hongkong"

popd
