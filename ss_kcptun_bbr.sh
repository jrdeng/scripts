#!/bin/bash

#
# this script is used to configure a VPS to run SS(go) and kcptun with tcp_bbr enabled
#
# NOTE: tcp_bbr needs kernel version >= 4.9.?
# tested OS: Ubuntu 16.04 LTS (x64) (KVM)
#

###### var
CUR_DIR=`pwd`
GO_DIR=~/go
SS_DIR=~/ss
SS_PORT=8388
SS_PASSWORD=666666
KCPTUN_DIR=~/kcptun
KCPTUN_PORT=4000


#
###### BBR
#
echo "" >> /etc/sysctl.conf
echo "# BBR" >> /etc/sysctl.conf
echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
sysctl -p


#
###### GO
#

# install golang
apt update
apt install -y golang-go git

# set go env
mkdir $GO_DIR
export GOPATH=$GO_DIR
export PATH=$GOPATH/bin:$PATH

#
###### SS
#

# install SS(go)
go get github.com/shadowsocks/shadowsocks-go/cmd/shadowsocks-server

# configure/scripts
mkdir $SS_DIR
cd $SS_DIR
# config.json
rm -rf config.json
echo "{" >> config.json
echo "    \"server_port\": $SS_PORT," >> config.json
echo "    \"password\": \"$SS_PASSWORD\"" >> config.json
echo "}" >> config.json
# restart.sh
rm -rf restart.sh
echo "#!/bin/bash" >> restart.sh
echo "kill \`pidof shadowsocks-server\`" >> restart.sh
echo "export PATH=$GO_DIR/bin:\$PATH" >> restart.sh
echo "shadowsocks-server start > log.txt &" >> restart.sh
chmod +x restart.sh

# optimize
# refer to: https://shadowsocks.org/en/config/advanced.html
# NOTE: we use bbr but not hybla for 'net.ipv4.tcp_congestion_control'
echo "" >> /etc/security/limits.conf
echo "# SS" >> /etc/security/limits.conf
echo "*    soft nofile 51200" >> /etc/security/limits.conf
echo "*    hard nofile 51200" >> /etc/security/limits.conf
echo "root soft nofile 51200" >> /etc/security/limits.conf
echo "root hard nofile 51200" >> /etc/security/limits.conf
ulimit -n 51200
echo "" >> /etc/sysctl.conf
echo "# SS" >> /etc/sysctl.conf
echo "fs.file-max = 51200" >> /etc/sysctl.conf
echo "net.core.rmem_max = 67108864" >> /etc/sysctl.conf
echo "net.core.wmem_max = 67108864" >> /etc/sysctl.conf
echo "net.core.netdev_max_backlog = 250000" >> /etc/sysctl.conf
echo "net.core.somaxconn = 4096" >> /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" >> /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 0" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout = 30" >> /etc/sysctl.conf
echo "net.ipv4.tcp_keepalive_time = 1200" >> /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range = 10000 65000" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 8192" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_tw_buckets = 5000" >> /etc/sysctl.conf
echo "net.ipv4.tcp_fastopen = 3" >> /etc/sysctl.conf
echo "net.ipv4.tcp_mem = 25600 51200 102400" >> /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 67108864" >> /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 67108864" >> /etc/sysctl.conf
echo "net.ipv4.tcp_mtu_probing = 1" >> /etc/sysctl.conf
#echo "net.ipv4.tcp_congestion_control = hybla" >> /etc/sysctl.conf
sysctl -p

# run SS
shadowsocks-server start > log.txt &


#
###### kcptun
#

# install kcptun
go get -u github.com/xtaci/kcptun/server
# rename
mv $GOPATH/bin/server $GOPATH/bin/kcptun_server

# configure/scripts
mkdir $KCPTUN_DIR
cd $KCPTUN_DIR
# restart.sh
rm -rf restart.sh
echo "#!/bin/bash" >> restart.sh
echo "kill \`pidof kcptun_server\`" >> restart.sh
echo "export PATH=$GO_DIR/bin:\$PATH" >> restart.sh
echo "kcptun_server -t \"127.0.0.1:$SS_PORT\" -l \":$KCPTUN_PORT\" -mode fast2 > /dev/null 2>/dev/null &" >> restart.sh
chmod +x restart.sh

# run kcptun
kcptun_server -t "127.0.0.1:$SS_PORT" -l ":$KCPTUN_PORT" -mode fast2 > /dev/null 2>/dev/null &

# reset dir
cd $CUR_DIR

echo 
echo "DONE!!!"
echo
