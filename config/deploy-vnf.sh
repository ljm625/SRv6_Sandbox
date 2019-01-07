#!/bin/bash

usage () {
echo ""
echo "+-----------------------------------------------------------------------+"
echo "+---------------------+ VNF deploy script +-----------------------------+"
echo "+-----------------------------------------------------------------------+"
echo "+-- This script Adds/cleans network namespace (VNF)                   --+"
echo "+-- Usage:                                                            --+"
echo "+-- $ ./deploy-vnf.sh help                                            --+"
echo "+-- $ ./deploy-vnf.sh add VNF_NAME NFV_IFACE1 NFV_IFACE2 NFV_IFACE1\  --+"
echo "+--     NFV_IFACE1_IP NFV_IFACE2_IP VNF_IFACE1_IP VNF_IFACE2_IP       --+"
echo "+-- $ ./deploy-vnf.sh del VNF_NAME NFV_IFACE1 NFV_IFACE2              --+"
echo "+-- N.B:                                                              --+"
echo "+-- IP Addresses should be in the form ADDR/MASK 'A::2/64'            --+"
echo "+-- Clean the VNF before re-trying to add (in case of error)          --+"
echo "+-- $./deploy-vnf.sh del VNF_NAME NFV_IFACE1 NFV_IFACE2               --+"
echo "+-----------------------------------------------------------------------+"
echo ""
exit
}

if [ $# -eq 0 ]
	then
	echo "ERROR: No command specified. please try \"$0 help\" "
	exit
fi

if [ $1 = "help" ]
	then
	usage
fi

if [ $1 != "add" ] && [ $1 != "del" ]
	then
	echo "ERROR: unrecognized coomand. please try \"$0 help\" "
	exit
fi

if [ $# -lt 4 ]
	then
	echo "ERROR: too few parameters. please try \"$0 help\" "
	exit
fi

COMMAND=$1
VNF_NAME=$2
NFV_IFACE1=$3
NFV_IFACE2=$4

if [ $COMMAND = "del" ]
	then
	echo "DELETING \"${VNF_NAME}\"........."
	ip link delete dev ${NFV_IFACE1}
        ip link delete dev ${NFV_IFACE2}
	ip netns del $VNF_NAME
	exit
fi

if [ $# -lt 8 ]
	then
        echo "ERROR: too few parameters. please try \"$0 help\" "
        exit
fi

VNF_IFACE1="veth0-${VNF_NAME}"
VNF_IFACE2="veth1-${VNF_NAME}"

NFV_IP1=$5
NFV_IP2=$6
VNF_IP1=$7
VNF_IP2=$8

NH1=`echo ${NFV_IP1} | cut -d'/' -f1`
NH2=`echo ${NFV_IP2} | cut -d'/' -f1`

# create VNF
ip netns add $VNF_NAME

# Create links between NFV and VNF
ip link add ${NFV_IFACE1} type veth peer name ${VNF_IFACE1}
ip link add ${NFV_IFACE2} type veth peer name ${VNF_IFACE2}

# Assign virtual interfaces to VNF
ip link set ${VNF_IFACE1} netns ${VNF_NAME}
ip link set ${VNF_IFACE2} netns ${VNF_NAME}

ifconfig ${NFV_IFACE1} up
ifconfig ${NFV_IFACE2} up

ip netns exec ${VNF_NAME} ifconfig lo up
ip netns exec ${VNF_NAME} ifconfig ${VNF_IFACE1} up
ip netns exec ${VNF_NAME} ifconfig ${VNF_IFACE2} up

ip netns exec ${VNF_NAME} sysctl -w net.ipv6.conf.all.forwarding=1

ip -6 addr add ${NFV_IP1} dev ${NFV_IFACE1}
ip -6 addr add ${NFV_IP2} dev ${NFV_IFACE2}

ip netns exec ${VNF_NAME} ip -6 addr add ${VNF_IP1} dev ${VNF_IFACE1}
ip netns exec ${VNF_NAME} ip -6 addr add ${VNF_IP2} dev ${VNF_IFACE2}

# Configure Policy Based Routing in the VNF
ip netns exec ${VNF_NAME} bash -c "echo '201 forward' >> /etc/iproute2/rt_tables"
ip netns exec ${VNF_NAME} bash -c "ip -6 rule add iif '${VNF_IFACE1}' lookup forward"
ip netns exec ${VNF_NAME} bash -c "ip -6 route add default via '${NH2}' table forward"
ip netns exec ${VNF_NAME} bash -c "echo '202 reverse' >> /etc/iproute2/rt_tables"
ip netns exec ${VNF_NAME} bash -c "ip -6 rule add iif '${VNF_IFACE2}' lookup reverse"
ip netns exec ${VNF_NAME} bash -c "ip -6 route add default via '${NH1}' table reverse"


echo ""
echo "+----------------------------------+"
echo "+---- VNF successfully created ----+"
echo "+----------------------------------+"
echo "+-- NAME             : " $VNF_NAME
echo "+-- HOST Iface1      : " $NFV_IFACE1
echo "+-- HOST Iface2      : " $NFV_IFACE2
echo "+-- HOST Iface1 addr : " $NFV_IP1
echo "+-- HOST Iface2 addr : " $NFV_IP2
echo "+-- VNF  Iface1      : " $VNF_IFACE1
echo "+-- VNF  Iface2      : " $VNF_IFACE2
echo "+-- VNF  Iface1 addr : " $VNF_IP1
echo "+-- VNF  Iface2 addr : " $VNF_IP2
echo "+----------------------------------+"
echo ""
exit
