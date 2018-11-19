#!/bin/sh

echo "Adding DX4 Rules for R3"
ip -6 route add fc00:3::a1/128 encap seg6local action End.B6.Encaps srh segs fc00:1::a2 dev r3-eth1



