#!/bin/sh

echo "Adding DX4 Rules for R4"

ip -6 route add fc00:4::bb/128 encap seg6local action End.DX4 nh4 10.0.2.1 dev r4-eth1
ip route add 10.0.0.0/24 encap seg6 mode encap  segs fc00:1::bb dev r4-eth1