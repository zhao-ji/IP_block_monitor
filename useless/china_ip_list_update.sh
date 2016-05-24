git submodule foreach git pull origin master
rm china_ip.gz
python china_ip_list_extend.py|sort -u|gzip>china_ip.gz
