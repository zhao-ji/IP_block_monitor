#!/bin/sh

STATION=$1

TODAY_DIFF="scan_log/$(date +%y_%m_%d_diff)"
TODAY_RECIEVE="scan_log/$(date +%y_%m_%d_recieve)"
TODAY_RECORD="scan_log/$(date +%y_%m_%d_$STATION)"

ERROR_LOG="scan_log/log_error"

touch $TODAY_RECIEVE

# 打开监控 关注syn-ack或rst-ack的返回
(sudo python recieve_ACK_or_RST.py 2> $ERROR_LOG >> $TODAY_RECIEVE)&

# 同IP建立握手
cat $TODAY_DIFF|grep '^[0-9\.]\{7,15\}$'|sudo python send_SYN_request.py &> $ERROR_LOG

# 休息三分钟后杀掉上个后台任务
# http://stackoverflow.com/questions/1624691/linux-kill-background-task
sleep 3m
sudo kill $!

cut -d ' ' -f 2 $TODAY_RECIEVE|grep '^[0-9\.]\{7,15\}$'|sort -V -u > $TODAY_RECORD

source .fuck_info

scp -P $BEIJING_PORT $TODAY_RECORD $BEIJING_HOST:~/block_scan/$TODAY_RECORD
