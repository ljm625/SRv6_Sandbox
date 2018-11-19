#!/bin/sh

echo "Adding DX6 Rules for R1"
ip -6 route add fc00:1::bb/128 encap seg6local action End.DX6 nh6 :: dev r1-eth2
ip -6 route add 2001:4b::/64 encap seg6 mode encap segs fc00:4::bb dev r1-eth2

