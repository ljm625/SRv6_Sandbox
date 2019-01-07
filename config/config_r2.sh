#!/bin/bash

# Configure Interfaces
ifconfig eth1 up
ip -6 addr add 2001:12::2/64 dev eth1

ifconfig eth2 up
ip -6 addr add 2001:23::1/64 dev eth2

ifconfig eth3 up
ip -6 addr add 2001:a::1/64 dev eth3

ifconfig lo up
ip -6 addr add fc00:2::2/64 dev lo


# Enable forwarding
sysctl -w net.ipv6.conf.all.forwarding=1

# Accept SRv6 traffic
sysctl -w net.ipv6.conf.all.seg6_enabled=1
sysctl -w net.ipv6.conf.lo.seg6_enabled=1
sysctl -w net.ipv6.conf.eth1.seg6_enabled=1
sysctl -w net.ipv6.conf.eth2.seg6_enabled=1
sysctl -w net.ipv6.conf.eth3.seg6_enabled=1


# Configure Routing
ip -6 route add fc00:1::/64 via 2001:12::1
ip -6 route add fc00:3::/64 via 2001:23::2
ip -6 route add fc00:a::/64 via 2001:a::2
ip -6 route add fc00:b::/64 via 2001:23::2

# Enable forwarding
sysctl -w net.ipv6.conf.all.forwarding=1



# Configure VNFs
# cd ~/
# rm -rf sr-sfc-demo
# git clone https://github.com/SRouting/sr-sfc-demo
# cd sr-sfc-demo/config/
# sh deploy-vnf.sh add f1 veth0 veth1 fd00:2:0::f1:1/64 fd00:2:1::f1:1/64 fd00:2:0::f1:2/64 fd00:2:1::f1:2/64
# ip netns exec f1 sysctl -w net.ipv6.conf.all.seg6_enabled=1
# ip netns exec f1 sysctl -w net.ipv6.conf.lo.seg6_enabled=1
# ip netns exec f1 sysctl -w net.ipv6.conf.veth0-f1.seg6_enabled=1
# ip netns exec f1 sysctl -w net.ipv6.conf.veth1-f1.seg6_enabled=1
# ip netns exec f1 sysctl -w net.ipv6.ip6t_seg6=1
# ip netns exec f1 ifconfig lo up
# ip netns exec f1 ip -6 route add local fc00:2::f1:0/112 dev lo

# # Configure Routing
# ip -6 route add fc00:3::/64 via fc00:23::3
# ip -6 route add fc00:1::/64 via fc00:12::1
# ip -6 route add fc00:2::f1:0/112 via fd00:2:0::f1:2

