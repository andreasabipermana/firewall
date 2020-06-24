#!/bin/bash
read -p 'Masukan Port SSH: ' SSH;

iptables -F
iptables -X

#mendrop semua
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#allow-from loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

iptables -A INPUT -p tcp --tcp-option 64 -m recent --set -j DROP
iptables -A INPUT -p tcp --tcp-option 128 -m recent --set -j DROP

#membuat chain baru
iptables -N SMALL

iptables -A INPUT -p udp -m length --length 0:27 -m recent --set -j SMALL
iptables -A INPUT -p tcp -m length --length 0:39 -m recent --set -j SMALL
iptables -A INPUT -p icmp -m length --length 0:27 -m recent --set -j SMALL
iptables -A INPUT -p 30 -m length --length 0:31 -m recent --set -j SMALL
iptables -A INPUT -p 47 -m length --length 0:39 -m recent --set -j SMALL
iptables -A INPUT -p 50 -m length --length 0:49 -m recent --set -j SMALL
iptables -A INPUT -p 51 -m length --length 0:35 -m recent --set -j SMALL
iptables -A INPUT -m length --length 0:19 -m recent --set -j SMALL
iptables -A SMALL -m limit --limit 1/second -j LOG --log-level 4 --log-prefix "SMALL -- SHUN" --log-tcp-sequence --log-tcp-options --log-ip-options
iptables -A SMALL -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A FORWARD -p tcp --tcp-flags ALL NONE -j DROP


iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A FORWARD -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
iptables -A FORWARD -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP
iptables -A FORWARD -p tcp --tcp-flags ACK,FIN FIN -j DROP
iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH -j DROP
iptables -A FORWARD -p tcp --tcp-flags ACK,PSH PSH -j DROP
iptables -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP
iptables -A FORWARD -p tcp --tcp-flags ACK,URG URG -j DROP
iptables -A INPUT -d 0.0.0.0 -j DROP
iptables -A INPUT -d 255.255.255.255 -j DROP

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

#mendrop packet dengan connection state Invalid
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A OUTPUT -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state INVALID -j DROP

iptables -A INPUT -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p icmp --icmp-type echo-request -m state --state NEW -j ACCEPT

iptables -A INPUT -p tcp --dport $SSH -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport $SSH -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --dport $SSH -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --sport $SSH -m state --state ESTABLISHED -j ACCEPT

#Limit Koneksi ke Port 80
iptables -A INPUT -p tcp --dport 80 -m limit --limit 100/minute --limit-burst 200 -j ACCEPT 
iptables -A INPUT -p tcp --dport 443 -m limit --limit 100/minute --limit-burst 200 -j ACCEPT 

read -p 'Masukan IP DNS: ' dns;
iptables -A INPUT -p udp -d $dns --dport 53 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p udp --dport 53 -m state --state NEW -j ACCEPT
iptables -A FORWARD -p udp -d $dns --dport 53 -m state --state NEW -j ACCEPT
iptables -A INPUT -p tcp -d $dns --dport 53 -m state --state NEW -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -m state --state NEW -j ACCEPT
iptables -A FORWARD -p tcp -d $dns --dport 53 -m state --state NEW -j ACCEPT

read -p 'Berapa jumlah port yang boleh keluar masuk selain SSH ?: ' choose;
echo "-------------------------------------------------------------------------------"
for i in `seq 1 $choose`;
do
read -p "Masukan Port ke $i: " dport;

iptables -A INPUT -p tcp --dport $dport -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport $dport -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --dport $dport -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --sport $dport -m state --state ESTABLISHED -j ACCEPT

iptables-save | tee /etc/sysconfig/iptables

done






