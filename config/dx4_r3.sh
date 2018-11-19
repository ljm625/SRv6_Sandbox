#!/bin/sh

echo "Adding DX4 Rules for R3"
ip -6 route add fc00:3::aa/128 encap seg6local action End.DX4 nh4 10.0.1.1 dev r3-eth1
ip route add 10.0.0.0/24 encap seg6 mode encap  segs fc00:1::aa dev r3-eth1


