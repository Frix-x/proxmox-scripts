#!/bin/sh

# Activate IP forwarding
echo 1 > /proc/sys/net/ipv4/ip_forward

# Point OPNsense WAN as route to LAN
ip route change 192.168.2.0/24 via 10.0.0.2 dev vmbr1
# Point OPNsense WAN as route to DMZ
ip route change 192.168.9.0/24 via 10.0.0.2 dev vmbr1

# Point OPNsense WAN as route to VPN
ip route add 10.2.2.0/24 via 10.0.0.2 dev vmbr1
