ip -6 route add fc00:3::a/128 encap seg6local action End.B6.Encaps srh segs fc00:5::a,fc00:3::b dev r3-eth1

ip -6 route add fc00:3::b/128 encap seg6local action End.DX6 nh6 :: dev r3-eth1

