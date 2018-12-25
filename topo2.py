from mininet.log import lg

import ipmininet
from ipmininet.cli import IPCLI
from ipmininet.ipnet import IPNet
from ipmininet.iptopo import IPTopo
from ipmininet.router.config.base import RouterConfig
from ipmininet.router.config.zebra import StaticRoute, Zebra

"""
                         fw
                          |
  a ---- r1  ---- r2 ---- r3  ----  c
          |        +      |
          ------- r4 ------
                   +
                   b

"""

# R1 R3 R4 are Segment Routing Enabled Server.
# FW is R5

ipv6_address={
    1:"2001:1a::/64",
    3:"2001:3c::/64",
    4:"2001:4b::/64"
}
ipv4_address={
    1:"10.0.0.0/24",
    3:"10.0.1.0/24",
    4:"10.0.2.0/24"
}

ipv4_gw={
    1:"10.0.0.1",
    3:"10.0.1.1",
    4:"10.0.2.1"
}




class SimpleTopo(IPTopo):

    def build(self, *args, **kwargs):
        """
        """
        r1_routes = [StaticRoute("fc00:4::/64", "2001:14::2"),StaticRoute("::/0", "2001:12::2")]
        r3_routes = [StaticRoute("fc00:4::/64", "2001:34::2"),StaticRoute("fc00:5::/64", "2001:35::2"),StaticRoute("::/0", "2001:23::1")]
        r4_routes = [StaticRoute("fc00:1::/64", "2001:14::1"),StaticRoute("fc00:3::/64", "2001:34::1"),
                     StaticRoute("::/0", "2001:24::1")]
        r2_routes = [StaticRoute("fc00:1::/64", "2001:12::1"),
                     StaticRoute("fc00:3::/64", "2001:23::2"),
                     StaticRoute("fc00:4::/64", "2001:24::2")]

        fw_routes = [StaticRoute("::/0","2001:35::1")]
    
        r1 = self.addRouter_v('r1', r1_routes)
        r3 = self.addRouter_v('r3', r3_routes)
        r4 = self.addRouter_v('r4', r4_routes)
        fw = self.addRouter_v('fw', fw_routes)


        r2 = self.addRouter_v6('r2', r2_routes) # Pure IPv6 Router

        a_routes = [StaticRoute("0.0.0.0/0", "10.0.0.2"),StaticRoute("::/0", "2001:1a::1/64")]
        b_routes = [StaticRoute("0.0.0.0/0", "10.0.2.2"),StaticRoute("::/0", "2001:4b::1/64")]
        c_routes = [StaticRoute("0.0.0.0/0", "10.0.1.2"),StaticRoute("::/0", "2001:3c::1/64")]


        a = self.addRouter_v('a',a_routes)
        b = self.addRouter_v('b',b_routes)
        c = self.addRouter_v('c',c_routes)

        # Links between Routers

        self.addLink(r1, r2, params1={"ip": "2001:12::1/64"},
                     params2={"ip": "2001:12::2/64"})
        self.addLink(r2, r3, params1={"ip": "2001:23::1/64"},
                     params2={"ip": "2001:23::2/64"})
        self.addLink(r2, r4, params1={"ip": "2001:24::1/64"},
                     params2={"ip": "2001:24::2/64"})

        self.addLink(r1, r4, params1={"ip": "2001:14::1/64"},
                     params2={"ip": "2001:14::2/64"})
        self.addLink(r3, r4, params1={"ip": "2001:34::1/64"},
                     params2={"ip": "2001:34::2/64"})


        # Links between Router and Hosts (IPv4)

        self.addLink(r1, a,
                     params1={"ip": "10.0.0.2/24"},
                     params2={"ip": "10.0.0.1/24"})
        self.addLink(r4, b,
                     params1={"ip": "10.0.2.2/24"},
                     params2={"ip": "10.0.2.1/24"})
        self.addLink(r3, c,
                     params1={"ip": "10.0.1.2/24"},
                     params2={"ip": "10.0.1.1/24"})

        # Links between Router and Hosts (IPv6)
        self.addLink(r1, a,
                     params1={"ip": "2001:1a::1/64"},
                     params2={"ip": "2001:1a::2/64"})
        self.addLink(r4, b,
                     params1={"ip": "2001:4b::1/64"},
                     params2={"ip": "2001:4b::2/64"})
        self.addLink(r3, c,
                     params1={"ip": "2001:3c::1/64"},
                     params2={"ip": "2001:3c::2/64"})

        self.addLink(r3, fw,
                     params1={"ip": "2001:35::1/64"},
                     params2={"ip": "2001:35::2/64"})


        super(SimpleTopo, self).build(*args, **kwargs)

    def addRouter_v6(self, name, staticRoutes):
        return self.addRouter(name, use_v4=False, use_v6=True, config=(RouterConfig, {'daemons': [(Zebra, {"static_routes": staticRoutes})]}))

    def addRouter_v(self, name, staticRoutes):
        return self.addRouter(name, use_v4=True, use_v6=True, config=(RouterConfig, {'daemons': [(Zebra, {"static_routes": staticRoutes})]}))

class RouterConfiguration(object):
    def __init__(self,host,host_num):
        self.host=host
        self.host_num=host_num
        self.configure()

    def exec_cmd(self,cmd):
        if type(cmd)==list:
            for c in cmd:
                print(c)
                self.host.cmd(c)
            return None
        else:
            print(cmd)
            result = self.host.cmd(cmd)
        return result

    def configure(self):
        # Config IPv6 Loopback address first.
        self.exec_cmd("ip -6 addr add fc00:{0}::{0}/64 dev lo".format(self.host_num))
        self.host_loc="fc00:{}::".format(self.host_num)
        # Get all the interface
        intf_list = [i.strip().strip(":") for i in self.exec_cmd("ifconfig -a | sed 's/[ \t].*//;/^$/d'").split('\r\n')]
        print(intf_list)
        # Config Systemctl
        cmds = ["sysctl -w net.ipv6.conf.{}.seg6_enabled=1".format(i) for i in intf_list]
        self.exec_cmd(cmds)
        # Config SR addr
        self.exec_cmd("ip sr tunsrc set fc00:{0}::{0}".format(self.host_num))
    
    @staticmethod
    def build_dx4_tunnel(host1,host2,id,segs_12=None,segs_21=None):
        """
        This function is used to build a DX4 Tunnel with optional TE
        """
        # In order to build a End.DX4 Tunnel, we need lots of Info
        # First build the commands
        seg_list_12 = ""
        seg_list_21 = ""

        if segs_12:
            for host in segs_12:
                segtag = SegmentHost(host,id).segid
                seg_list_12=seg_list_12 + segtag + ","
        if segs_21:
            for host in segs_21:
                segtag = SegmentHost(host,id).segid
                seg_list_21=seg_list_21 + segtag + ","
        

                
        cmd_h1 = ["ip -6 route add {}{}/128 encap seg6local action End.DX4 nh4 {} dev r{}-eth1"
                 .format(host1.host_loc,id,ipv4_gw[host1.host_num],host1.host_num),
                 "ip route add {} encap seg6 mode encap  segs {}{}{} dev r{}-eth1"
                 .format(ipv4_address[host2.host_num],seg_list_12,host2.host_loc,id,host1.host_num)]

        cmd_h2 = ["ip -6 route add {}{}/128 encap seg6local action End.DX4 nh4 {} dev r{}-eth1"
                 .format(host2.host_loc,id,ipv4_gw[host2.host_num],host2.host_num),
                 "ip route add {} encap seg6 mode encap  segs {}{}{} dev r{}-eth1"
                 .format(ipv4_address[host1.host_num],seg_list_21,host1.host_loc,id,host2.host_num)]
        host1.exec_cmd(cmd_h1)
        host2.exec_cmd(cmd_h2)

    @staticmethod
    def build_dx6_tunnel(host1,host2,id,segs_12=None,segs_21=None):
        """
        This function is used to build a DX6 Tunnel with optional TE
        """
        # In order to build a End.DX4 Tunnel, we need lots of Info
        # First build the commands

        seg_list_12 = ""
        seg_list_21 = ""

        if segs_12:
            for host in segs_12:
                segtag = SegmentHost(host,id).segid
                seg_list_12=seg_list_12 + segtag + ","
        if segs_21:
            for host in segs_21:
                segtag = SegmentHost(host,id).segid
                seg_list_21=seg_list_21 + segtag + ","


        cmd_h1 = ["ip -6 route add {}{}/128 encap seg6local action End.DX6 nh6 :: dev r{}-eth1"
                 .format(host1.host_loc,id,host1.host_num),
                 "ip -6 route add {} encap seg6 mode encap  segs {}{}{} dev r{}-eth1"
                 .format(ipv6_address[host2.host_num],seg_list_12,host2.host_loc,id,host1.host_num)]

        cmd_h2 = ["ip -6 route add {}{}/128 encap seg6local action End.DX6 nh6 :: dev r{}-eth1"
                 .format(host2.host_loc,id,host2.host_num),
                 "ip route add {} encap seg6 mode encap  segs {}{}{} dev r{}-eth1"
                 .format(ipv6_address[host1.host_num],seg_list_21,host1.host_loc,id,host2.host_num)]
        host1.exec_cmd(cmd_h1)
        host2.exec_cmd(cmd_h2)

class HostConfiguration(object):
    def __init__(self,host,host_name,host_num):
        self.host=host
        self.host_num=host_num
        self.host_name = host_name
        self.configure()

    def exec_cmd(self,cmd):
        if type(cmd)==list:
            for c in cmd:
                print(c)
                self.host.cmd(c)
            return None
        else:
            print(cmd)
            result = self.host.cmd(cmd)
        return result

    def configure(self):
        # Config IPv6 Default route.
        self.exec_cmd("ip -6 route add default via 2001:{}{}::1".format(self.host_num,self.host_name))
    


class SegmentHost(object):
    def __init__(self,host,id):
        self.host=host
        self.id=id
        self.segid = "fc00:{}::{}".format(self.host.host_num,self.id)
        self.configure()
    
    def configure(self):
        # Configure the End Point host.
        cmd= "ip -6 route add {}/128 encap seg6local action End dev r{}-eth0".format(self.segid,self.host.host_num)
        self.host.exec_cmd(cmd)


if __name__ == '__main__':
    ipmininet.DEBUG_FLAG = True
    lg.setLogLevel("info")

    # Start network
    net = IPNet(topo=SimpleTopo(), use_v4=True, allocate_IPs=False)

    try:
        net.start()
        # Execute Commands

        # Enable SRv6 On Routers.
        r1 = RouterConfiguration(net.get('r1'),1)
        r2 = RouterConfiguration(net.get('r2'),2)
        r3 = RouterConfiguration(net.get('r3'),3)
        r4 = RouterConfiguration(net.get('r4'),4)
        fw = RouterConfiguration(net.get('fw'),5)

        HostConfiguration(net.get('a'),'a',1)
        HostConfiguration(net.get('b'),'b',4)
        HostConfiguration(net.get('c'),'c',3)


        # RouterConfiguration.build_dx4_tunnel(r1,r3,"a")
        # RouterConfiguration.build_dx4_tunnel(r3,r4,"b")
        # RouterConfiguration.build_dx4_tunnel(r1,r4,"c")

        # RouterConfiguration.build_dx6_tunnel(r1,r3,"a1")
        # RouterConfiguration.build_dx6_tunnel(r3,r4,"b1")
        # RouterConfiguration.build_dx6_tunnel(r1,r4,"c1")

        IPCLI(net)
    finally:
        net.stop()
