# SRv6 Sandbox

This project is a SRv6 Sandbox base on Mininet.

### Requirements

- Linux Kernel higher than 4.15 

- Latest Mininet Installed

- Quagga Installed

- Python Installed

### Install Guide

The install guide is base on Ubuntu 18.04 LTS version

1. Upgrade Kernel to the recommended version

   ```bash
   apt-get install linux-headers-4.15.0-38 linux-headers-4.15.0-38-generic linux-image-4.15.0-38-generic linux-modules-4.15.0-38-generic linux-modules-extra-4.15.0-38-generic
   ```
2. Reboot and check if the kernel is upgraded
   ```bash
   uname -a
   Linux ubuntu 4.15.0-38-generic #41-Ubuntu SMP Wed Oct 10 10:59:38 UTC 2018 x86_64 x86_64 x86_64 GNU/Linux

   ```
3. Install Mininet and Quagga
   ```bash
   apt-get install mininet gawk libreadline-dev libc-ares-dev
   wget http://download.savannah.gnu.org/releases/quagga/quagga-1.2.4.tar.gz
   tar -xzvf ./quagga-1.2.4.tar.gz
   cd ./quagga-1.2.4
   ./configure --enable-vtysh --enable-user=root --enable-group=root --enable-vty-group=root
   make install
   ```
4. Install iproute2
   ```bash
   wget https://mirrors.edge.kernel.org/pub/linux/utils/net/iproute2/iproute2-4.9.0.tar.gz
   tar -xzvf ./iproute2-4.9.0.tar.gz
   cd ./iproute2-4.9.0
   apt-get install bison flex
   make
   make install
   ```
5. Install python dependencies
   ```bash
   pip install mako ipaddress ipmininet --no-deps
   ```
6. Run Environment
   ```bash
   sudo python topo.py
   ```

### Usage Guide

In file topo.py:

You can define topology by adding Host/Router and adding Links.

Use build_dx4_tunnel to build a DX4 Tunnel
Use build_dx6_tunnel to build a DX6 Tunnel
Use RouterConfiguration to Initialize a Router to SRv6 Router.

#### For manual configuration

For manual configuration, run dx4_r1.sh on R1 and dx4_r3 on R3

### Mininet Simple tutorial

After running sudo python topo.py, you will be promoted to a Mininet shell.

Run "xterm <Hostname>" to go to the destinated host shell

For example, xterm R1 will give you access to R1 shell.

