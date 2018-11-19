#!/bin/sh

echo "Adding DX4 Rules for R1"
ip -6 route add fc00:1::aa/128 encap seg6local action End.DX4 nh4 10.0.0.1 dev r1-eth1
ip route add 10.0.1.0/24 encap seg6 mode encap  segs fc00:3::aa dev r1-eth1

