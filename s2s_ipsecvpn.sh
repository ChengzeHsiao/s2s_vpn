#!/bin/bash

# 设置输入参数-按照实际信息填写VPN本端和对端的配置信息
#VPN连接名称，如aws/oracle/op/project等
DEST=$CONNECTION-memverge
#本端VPN服务器公网IP
LEFT=$LEFT-139.196.178.207
#本端子网，多个子网用空格分开
LEFT_SUBNET='{172.16.0.0/12}'
#对端VPN服务器或设备公网IP
RIGHT=$RIGHT-VM-PUBLIC-IP
#对端子网，多个子网用空格分开
RIGHT_SUBNET='{172.16.0.0/12}'
#PSK秘钥-设置秘钥，比如Welcome123!
VPNPSK=Welcome123!
# 结束输入参数设置-下述配置无需修改


# 安装软件，推荐OS使用ubuntu18.04或centos7
set -xe

if [[ -e /etc/apt/sources.list ]]; then
    # relpace all apt source
#    curl -o /etc/apt/sources.list http://mirrors.cloud.tencent.com/repo/ubuntu18_sources.list
# Install
    apt update
    apt install net-tools libreswan -y
elif [[ -d /etc/yum.repos.d ]]; then
    cp -af /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
#    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo
    yum clean all
    yum makecache
    yum install -y net-tools libreswan
else
    echo "not supported distro"
    exit 1
fi

# 设置启动参数配置
cat << EOF > /etc/rc.local
#!/bin/bash

/root/vpn_startup.sh
exit 0
EOF

#设置初始化网络参数
cat << EOF > /root/vpn_startup.sh
#!/bin/bash 

echo "1" > /proc/sys/net/ipv4/ip_forward 

for F in /proc/sys/net/ipv4/conf/*/accept_redirects; do 
    echo "0" > \$F 
done 

for F in /proc/sys/net/ipv4/conf/*/send_redirects; do 
    echo "0" > \$F 
done 

for F in /proc/sys/net/ipv4/conf/*/rp_filter; do 
    echo "0" > \$F 
done 

systemctl restart ipsec

exit 0
EOF

chmod +x /etc/rc.local /root/vpn_startup.sh
/root/vpn_startup.sh

## 配置VPN
mkdir -p /etc/ipsec.d

CONF_FILE=/etc/ipsec.d/to-$DEST.conf
SECURITY_FILE=/etc/ipsec.d/to-$DEST.secrets

cat << EOF > $CONF_FILE
conn to-$DEST
    auto=start
    type=tunnel

    ###THIS SIDE###
    left=%defaultroute
    leftid=$LEFT
    leftnexthop=%defaultroute
    leftsubnets=$LEFT_SUBNET
    ###PEER SIDE###
    right=$RIGHT
    rightsubnets=$RIGHT_SUBNET

    #phase 1 encryption-integrity-DiffieHellman
    keyexchange=ike
    ikev2=no
    ike=aes256-sha1;modp1024
    ikelifetime=86400s
    authby=secret #use presharedkey
    rekey=yes  #should we rekey when key lifetime is about to expire

    #phase 2 encryption-pfsgroup
    phase2=esp #esp for encryption | ah for authentication only
    phase2alg=aes256-sha1
    pfs=no

    #forceencaps=yes
    dpddelay=10
    dpdtimeout=60
    dpdaction=restart_by_peer
    salifetime=3600s
EOF

cat << EOF > $SECURITY_FILE
$LEFT $RIGHT   : PSK "${VPNPSK}"
EOF

# Start ipsec service
systemctl enable ipsec
systemctl restart ipsec
