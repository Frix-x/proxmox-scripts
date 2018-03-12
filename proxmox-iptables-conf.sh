#!/bin/sh

	# -------------------------
	# VARIABLES (as a reminder)
	# -------------------------

## Proxmox bridge holding external server IP
ExtVmbr="vmbr0"
## Proxmox bridge on VmWanNET (OPNsense WAN side)
WanVmbr="vmbr1"
## Proxmox bridge on VmDmzNET (OPNsense DMZ side)
DmzVmbr="vmbr2"
## Proxmox bridge on VmLanNET (OPNsense LAN side)
LanVmbr="vmbr3"

## Network/Mask of VmWanNET
VmWanNET="10.0.0.0/30"
## Network/Mmask of VmDmzNET
VmDmzNET="192.168.9.0/24"
## Network/Mmask of VmLanNET
VmLanNET="192.168.2.0/24"
## Network/Mmask of VpnNET
VpnNET="10.2.2.0/24"

## External physical server IP
ExtIP="192.168.1.16"
## Proxmox IP on the VmWanNET
ProxVmWanIP="10.0.0.1"
## Proxmox IP on the VmDmzNET
ProxVmDmzIP="192.168.9.1"
## Proxmox IP on the VmLanNET
ProxVmLanIP="192.168.2.1"
## OPNsense IP on the VmWanNET
PfsVmWanIP="10.0.0.2"


	# ------------------------
	# CLEAN ALL EXISTING RULES
	# ------------------------

iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

	# -------------------------
	# DEFAULT POLICY : DROP ALL
	# -------------------------

iptables -P OUTPUT DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP

ip6tables -P INPUT DROP
ip6tables -P OUTPUT DROP
ip6tables -P FORWARD DROP

	# ------
	# CHAINS
	# ------

### Creating chains
iptables -N TCP
iptables -N UDP

# Send NEW traffic to the UDP/TCP chains
iptables -A INPUT -p udp -m conntrack --ctstate NEW -j UDP
iptables -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j TCP

	# ------------
	# GLOBAL RULES
	# ------------

# Allow localhost
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
# Allowing current/active connections
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
# Allowing ping
iptables -A INPUT -p icmp --icmp-type 8 -m conntrack --ctstate NEW -j ACCEPT

	# ------------------
	# RULES FOR ExtVmbr
	# ------------------

### OUTPUT RULES

# Allow ping out
iptables -A OUTPUT -p icmp -j ACCEPT
# Allow LAN & DMZ to access internet
iptables -A OUTPUT -o $ExtVmbr -s $PfsVmWanIP -d $ExtIP -j ACCEPT
# Allow SSH, DNS, WHOIS, HTTP & HTTPS as client
iptables -A OUTPUT -o $ExtVmbr -s $ExtIP -p tcp --dport 22 -j ACCEPT
iptables -A OUTPUT -o $ExtVmbr -s $ExtIP -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -o $ExtVmbr -s $ExtIP -p tcp --dport 43 -j ACCEPT
iptables -A OUTPUT -o $ExtVmbr -s $ExtIP -p tcp --dport 80 -j ACCEPT
iptables -A OUTPUT -o $ExtVmbr -s $ExtIP -p tcp --dport 443 -j ACCEPT

### FORWARD RULES

# Allow request forwarding to OPNsense WAN interface
iptables -A FORWARD -i $ExtVmbr -d $PfsVmWanIP -o $WanVmbr -p tcp -j ACCEPT
iptables -A FORWARD -i $ExtVmbr -d $PfsVmWanIP -o $WanVmbr -p udp -j ACCEPT
# Allow request forwarding from LAN & DMZ
iptables -A FORWARD -i $WanVmbr -s $VmWanNET -j ACCEPT

### NAT MASQUERADE

# Allow VmWanNET (OPNsense) to use vmbr0 public adress to go out
iptables -t nat -A POSTROUTING -s $VmWanNET -o $ExtVmbr -j MASQUERADE

# All tcp to OPNsense WAN except 22, 8006
iptables -A PREROUTING -t nat -i $ExtVmbr -p tcp -j DNAT --to $PfsVmWanIP
# All udp to OPNsense WAN
iptables -A PREROUTING -t nat -i $ExtVmbr -p udp -j DNAT --to $PfsVmWanIP

	# -----------------
	# RULES FOR WanVmbr
	# -----------------

### INPUT RULES

# Allow SSH server & Proxmox web UI from VPN,LAN/DMZ
iptables -A TCP -i $WanVmbr -d $ProxVmWanIP -p tcp --dport 22 -j ACCEPT
iptables -A TCP -i $WanVmbr -d $ProxVmWanIP -p tcp --dport 8006 -j ACCEPT

### OUTPUT RULES

# Allow SSH server & Proxmox web UI from VPN,LAN/DMZ
iptables -A OUTPUT -o $WanVmbr -s $ProxVmWanIP -p tcp --sport 22 -j ACCEPT
iptables -A OUTPUT -o $WanVmbr -s $ProxVmWanIP -p tcp --sport 8006 -j ACCEPT

# (Rules need adjustements in OPNsense firewall to allow from VPN/LAN and block from DMZ)

	# -----------------
	# RULES FOR DmzVmbr
	# -----------------

# NO RULES => All blocked !!!

	# -----------------
	# RULES FOR LanVmbr
	# -----------------

# NO RULES => All blocked !!!
