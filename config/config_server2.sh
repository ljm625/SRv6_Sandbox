#!/bin/bash

# Configure Interfaces
ifconfig eth1 up
ip -6 addr add 2001:b::2/64 dev eth1

ifconfig lo up
ip -6 addr add fc00:b::b/64 dev lo

# Enable forwarding
sysctl -w net.ipv4.ip_forward=1
 
sysctl -w net.ipv6.conf.all.forwarding=1

# Accept SRv6 traffic
sysctl -w net.ipv6.conf.all.seg6_enabled=1
sysctl -w net.ipv6.conf.lo.seg6_enabled=1
sysctl -w net.ipv6.conf.eth1.seg6_enabled=1


# Enable SR Aware IPtables
sysctl -w net.ipv6.ip6t_seg6=1

# Configure Routing
ip -6 route del default
ip -6 route add default via 2001:b::1

# Enable forwarding
sysctl -w net.ipv6.conf.all.forwarding=1


# Configure SRv6 Policy 
ip -6 route add fc00:b::a1/128 encap seg6local action End dev eth1


# Configure snort rules
sudo mkdir -p /etc/snort/ /etc/snort/rules/ /var/log/snort
touch /etc/snort/snort.conf /etc/snort/rules/local.rule
echo 'var RULE_PATH rules' >> /etc/snort/snort.conf
echo 'include $RULE_PATH/local.rule' >> /etc/snort/snort.conf
echo 'alert icmp any any -> any any (msg:"ICMP detected"; sid:1000)' >> /etc/snort/rules/local.rule



# # Configure Branches (BR1 and BR2)
# cd ~/
# rm -rf sr-sfc-demo
# git clone https://github.com/SRouting/sr-sfc-demo
# cd sr-sfc-demo/config/
# sh deploy-term.sh add br1 veth1 inet6 fc00:b1::1/64 fc00:b1::2/64
# sh deploy-term.sh add br2 veth2 inet6 fc00:b2::1/64 fc00:b2::2/64

# # Configure Policy Based Routing (PBR)
# echo "201 br1" >> /etc/iproute2/rt_tables
# ip -6 rule add from fc00:b1::/64 lookup br1

# echo "202 br2" >> /etc/iproute2/rt_tables
# ip -6 rule add from fc00:b2::/64 lookup br2

# # Configure SR SFC policies
# ip -6 route add fc00:e::/64 encap seg6 mode encap segs fc00:2::f1:0,fc00:3::f2:AD60,fc00:6::D6 dev eth1 table br1
# ip -6 route add fc00:e::/64 encap seg6 mode encap segs fc00:5::f3:0,fc00:6::D6 dev eth2 table br2

# # Configure Routing
# ip -6 route add fc00:2::/64 via fc00:12::2
# ip -6 route add fc00:5::/64 via fc00:14::4

# # Configure SRv6 End.D6 behaviour for traffic going to BR1 and BR2
# ip -6 route add local fc00:1::d6/128 dev lo
