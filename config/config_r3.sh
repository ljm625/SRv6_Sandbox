#!/bin/bash


# Configure Interfaces
ifconfig eth1 up
ip addr add 10.0.1.2/24 dev eth1

ifconfig eth2 up
ip -6 addr add 2001:23::2/64 dev eth2

ifconfig eth3 up
ip -6 addr add 2001:b::1/64 dev eth3

ifconfig lo up
ip -6 addr add fc00:3::3/64 dev lo


# Enable forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1

# Accept SRv6 traffic
sysctl -w net.ipv6.conf.all.seg6_enabled=1
sysctl -w net.ipv6.conf.lo.seg6_enabled=1
sysctl -w net.ipv6.conf.eth1.seg6_enabled=1
sysctl -w net.ipv6.conf.eth2.seg6_enabled=1
sysctl -w net.ipv6.conf.eth3.seg6_enabled=1


# Configure Routing
ip -6 route del default

ip -6 route add default via 2001:23::1
ip -6 route add fc00:b::/64 via 2001:b::2


# Enable forwarding
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1


# # Configure SR policies
ip -6 route add fc00:3::a/128 encap seg6local action End.DX4 nh4 10.0.1.1 dev eth1
ip route add 10.0.0.0/24 encap seg6 mode encap segs fc00:1::a dev eth2


# # Install required softwares
# export DEBIAN_FRONTEND=noninteractive
# apt-get -y update
# apt-get -y upgrade
# apt-get -y install build-essential libpcap-dev git wget libdumbnet-dev zlib1g-dev liblzma-dev openssl libssl-dev libnghttp2-dev libpcre3 \
# libpcre3-dev flex bison libdnet-dev libghc-zlib-dev dh-autoreconf libnet-dev gcc automake autoconf make libyaml-dev g++ binutils autotools-dev libtool pkg-config \
# libcunit1-dev libxml2-dev libev-dev libjansson-dev libc-ares-dev libjemalloc-dev libsystemd-dev cython python3-dev python-setuptools

# # Install nghttp2
# cd ~/
# git clone https://github.com/nghttp2/nghttp2
# cd nghttp2/
# git submodule update --init && autoreconf -i && automake && autoconf && ./configure && make && make install

# # Install SR-tcpdump
# cd ~/
# git clone https://github.com/srouting/sr-tcpdump
# cd sr-tcpdump
# ./configure && make && make install

# # Configure Interfaces
# ifconfig eth1 up
# ip -6 addr add fc00:23::3/64 dev eth1

# ifconfig eth2 up
# ip -6 addr add fc00:36::3/64 dev eth2

# # Enable forwarding
# sysctl -w net.ipv6.conf.all.forwarding=1

# # Accept SRv6 traffic
# sysctl -w net.ipv6.conf.all.seg6_enabled=1
# sysctl -w net.ipv6.conf.lo.seg6_enabled=1
# sysctl -w net.ipv6.conf.eth1.seg6_enabled=1
# sysctl -w net.ipv6.conf.eth2.seg6_enabled=1

# # Configure VNFs
# cd ~/
# rm -rf sr-sfc-demo/
# git clone https://github.com/SRouting/sr-sfc-demo
# cd sr-sfc-demo/config/
# sh deploy-vnf.sh add f2 veth0 veth1 fd00:3:0::f2:1/64 fd00:3:1::f2:1/64 fd00:3:0::f2:2/64 fd00:3:1::f2:2/64

# # Install and configure srext (SR proxy)
# cd ~/
# git clone https://github.com/SRouting/SRv6-net-prog
# cd SRv6-net-prog/srext/
# make && make install && depmod -a && modprobe srext
# srconf localsid add fc00:3::f2:AD60 end.ad6 ip fd00:3:0::f2:2 veth0 veth1
# srconf localsid add fc00:3::f2:AD61 end.ad6 ip fd00:3:1::f2:2 veth1 veth0

# # Configure Routing
# ip -6 route add fc00:6::/64 via fc00:36::6
# ip -6 route add fc00:2::/64 via fc00:23::2

# # Install Snort
# cd ~/
# wget https://snort.org/downloads/snort/daq-2.0.6.tar.gz
# wget https://snort.org/downloads/snort/snort-2.9.11.1.tar.gz

# tar xvzf daq-2.0.6.tar.gz
# cd daq-2.0.6
# ./configure && make && sudo make install

# cd ~/
# tar xvzf snort-2.9.11.1.tar.gz
# cd snort-2.9.11.1
# ./configure --enable-sourcefire && make && sudo make install

# # Update shared libraries (mandatory according to Snort documentation)
# sudo ldconfig

# # configure snort rules
# sudo mkdir -p /etc/snort/ /etc/snort/rules/ /var/log/snort

# touch /etc/snort/snort.conf /etc/snort/rules/local.rule
# echo 'var RULE_PATH rules' >> /etc/snort/snort.conf
# echo 'include $RULE_PATH/local.rule' >> /etc/snort/snort.conf
# echo 'alert icmp any any -> any any (msg:"ICMP detected"; sid:1000)' >> /etc/snort/rules/local.rule
