#!/bin/sh

STATION=$1

DIFF="scan_log/$(date +%y_%m_%d_diff)"
RECIEVE="scan_log/$(date +%y_%m_%d_recieve)"
RECORD="scan_log/$(date +%y_%m_%d_$STATION)"

ERROR_LOG="scan_log/log_error"

touch $RECIEVE

# 打开监控 关注syn-ack或rst-ack的返回
(sudo python recieve_ACK_or_RST.py 2> $ERROR_LOG >> $RECIEVE)&

# 同IP建立握手
cat $DIFF|grep '^[0-9\.]\{7,15\}$'|sudo python send_SYN_request.py &> $ERROR_LOG

# 休息三分钟后杀掉上个后台任务
# http://stackoverflow.com/questions/1624691/linux-kill-background-task
sleep 3m
sudo kill $!

cut -d ' ' -f 2 $RECIEVE|grep '^[0-9\.]\{7,15\}$'|sort -V -u > $RECORD

source .fuck_info

scp -P $BEIJING_PORT $RECORD $BEIJING_HOST:~/block_scan/$RECORD
