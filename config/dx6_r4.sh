#!/bin/sh

echo "Adding DX6 Rules for R4"
ip -6 route add fc00:4::bb/128 encap seg6local action End.DX6 nh6 :: dev r4-eth2
ip -6 route add 2001:1a::/64 encap seg6 mode encap segs fc00:1::bb dev r4-eth2

