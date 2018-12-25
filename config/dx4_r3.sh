#!/bin/sh

echo "Adding DX4 Rules for R3"
ip -6 route add fc00:3::bb/128 encap seg6local action End dev r3-eth2


