#!/bin/bash

usage () {
echo ""
echo "+------------------------------------------------------------------------+"
echo "+-------------------+ Terminal deploy script +---------------------------+"
echo "+------------------------------------------------------------------------+"
echo "+-- A script to add/clean a network namespace to be used as a terminal --+"
echo "+-- The terminal can be IPv4, IPv6, or dual network stack.             --+"
echo "+-- Usage:                                                             --+"
echo "+-- $ ./deploy-term.sh help                                            --+"
echo "+-- $ ./deploy-term.sh add TERM_NAME NFV_IFACE MODE                    --+"
echo "+-- MODE := inet   NFV_ADDR4  TERM_ADDR4                               --+"
echo "+--         inet6  NFV_ADDR6  TERM_ADDR6                               --+"
echo "+--         dual   NFV_ADDR4  TERM_ADDR4 NFV_ADDR6 TERM_ADDR6          --+"
echo "+-- $ ./deploy-term.sh del TERM_NAME NFV_IFACE                          --+"
echo "+-- N.B:                                                              --+"
echo "+-- IP Addresses should be in the form ADDR/MASK 'A::2/64'            --+"
echo "+-- Clean the TERM before re-trying to add (in case of error)          --+"
echo "+-- $./deploy-term.sh del TERM_NAME NFV_IFACE                           --+"
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

if [ $# -lt 3 ]
	then
	echo "ERROR: too few parameters. please try \"$0 help\" "
	exit
fi

COMMAND=$1
TERM_NAME=$2
NFV_IFACE=$3

if [ $COMMAND = "del" ]
	then
	echo "DELETING \"${TERM_NAME}\"........."
	ip link delete dev ${NFV_IFACE}
	ip netns del $TERM_NAME
	exit
fi


if [ $# -ge 4 ]
	then
	MODE=$4
	if [ $MODE != "inet" ] &&  [ $MODE != "inet6" ]  && [ $MODE != "dual" ]
		then
		echo " ERROR: Mode ${MODE} is not a valid inet mode  many. please try \"$0 help\" "
		exit
	fi
fi

if [ $# -lt 6 ]
	then
	echo "ERROR: too few parameters for add command. please try \"$0 help\" "
	exit
fi

TERM_IFACE="veth0-${TERM_NAME}"

if [ $MODE = "inet" ] || [ $MODE = "inet6" ]
	then
	if [ $# -gt 8 ]
		then
		echo "ERROR: too many parameters for inet or inet6 mode. please try \"$0 help\" "
		exit
	fi

	NFV_IP=$5
	TERM_IP=$6
	NH=`echo ${NFV_IP} | cut -d'/' -f1`

	# create TERM
	ip netns add $TERM_NAME
	#create link between NFV and TERM
	ip link add ${NFV_IFACE} type veth peer name ${TERM_IFACE}
	#assign virtual interface to TERM
	ip link set ${TERM_IFACE} netns ${TERM_NAME}
	ifconfig ${NFV_IFACE} up
	ip netns exec ${TERM_NAME} ifconfig ${TERM_IFACE} up

	if [ $MODE = "inet" ]
		then
			#configure NFV Interface
			ip addr add ${NFV_IP} dev ${NFV_IFACE}
			#configure TERM interfcae
			ip netns exec ${TERM_NAME} ip addr add ${TERM_IP} dev ${TERM_IFACE}
			#enable forwarding in TERM
			ip netns exec ${TERM_NAME} sysctl -w net.ipv4.conf.all.forwarding=1 >/dev/null
			ip netns exec ${TERM_NAME} ip route add default via ${NH}

	else
		ip netns exec ${TERM_NAME} sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null
		ip -6 addr add ${NFV_IP} dev ${NFV_IFACE}
		ip netns exec ${TERM_NAME} ip -6 addr add ${TERM_IP} dev ${TERM_IFACE}
		ip netns exec ${TERM_NAME} ip -6 route add default via ${NH}
	fi

else
	if [ $# -lt 8 ]
		then
		echo "ERROR: too few parameters for dual mode. please try \"$0 help\" "
		exit
	fi

	if [ $# -gt 10 ]
		then
		echo "ERROR: too many parameters for dual mode. please try \"$0 help\" "
		exit
	fi

	NFV_IPv4=$5
	TERM_IPv4=$6
	NFV_IPv6=$7
	TERM_IPv6=$8

	# create TERM
	ip netns add $TERM_NAME
	#create link between NFV and TERM
	ip link add ${NFV_IFACE} type veth peer name ${TERM_IFACE}
	#assign virtual interface to TERM
	ip link set ${TERM_IFACE} netns ${TERM_NAME}
	ifconfig ${NFV_IFACE} up
	ip netns exec ${TERM_NAME} ifconfig ${TERM_IFACE} up

	#configure NFV Interface
	ip addr add ${NFV_IPv4} dev ${NFV_IFACE}
	ip -6 addr add ${NFV_IPv6} dev ${NFV_IFACE}

	#configure TERM interfcae
	ip netns exec ${TERM_NAME} ip addr add ${TERM_IPv4} dev ${TERM_IFACE}
	ip netns exec ${TERM_NAME} ip -6 addr add ${TERM_IPv6} dev ${TERM_IFACE}

	#enable forwarding in TERM
	ip netns exec ${TERM_NAME} sysctl -w net.ipv4.conf.all.forwarding=1 >/dev/null
	ip netns exec ${TERM_NAME} sysctl -w net.ipv6.conf.all.forwarding=1 >/dev/null
	NH4=`echo ${NFV_IPv4} | cut -d'/' -f1`
	NH6=`echo ${NFV_IPv6} | cut -d'/' -f1`

	ip netns exec ${TERM_NAME} ip route add default via ${NH4}
	ip netns exec ${TERM_NAME} ip -6 route add default via ${NH6}

fi

echo ""
echo "+---------------------------------------+"
echo "+---- Terminal successfully created ----+"
echo "+---------------------------------------+"
echo "+-- NAME            : " $TERM_NAME
echo "+-- HOST Iface      : " $NFV_IFACE
echo "+-- HOST Iface addr : " $NFV_IP
echo "+-- TERM Iface      : " $TERM_IFACE
echo "+-- TERM Iface addr : " $TERM_IP
echo "+----------------------------------+"
echo ""
exit
