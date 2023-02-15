#!/bin/bash

IPT=/sbin/iptables

cleanOldRules() {
  $IPT -F
  $IPT -X
  $IPT -t nat -F
  $IPT -t nat -X
  $IPT -t mangle -F
  $IPT -t mangle -X
  $IPT -P INPUT ACCEPT
  $IPT -P OUTPUT ACCEPT
  $IPT -P FORWARD ACCEPT
}

applyRules() {
  iptables -A INPUT -i lo -j ACCEPT
  iptables -A OUTPUT -o lo -j ACCEPT
  iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
  iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT

  iptables -A INPUT -m conntrack --ctstate INVALID -j DROP # Dropping Invalid Packets
  iptables -A INPUT -p icmp --icmp-type echo-request -j DROP
  iptables -A INPUT -i eth1 -p icmp --icmp-type echo-request -j DROP
  iptables -N port-scanning
  iptables -A port-scanning -p tcp --tcp-flags SYN,ACK,FIN,RST RST -m limit --limit 1/s --limit-burst 2 -j RETURN
  iptables -A port-scanning -j DROP
  iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --set
  iptables -A INPUT -p tcp --dport ssh -m conntrack --ctstate NEW -m recent --update --seconds 60 --hitcount 10 -j DROP
  iptables -N syn_flood

  iptables -A INPUT -p tcp --syn -j syn_flood
  iptables -A syn_flood -m limit --limit 1/s --limit-burst 3 -j RETURN
  iptables -A syn_flood -j DROP

  iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j ACCEPT

  iptables -A INPUT -p icmp -m limit --limit 1/s --limit-burst 1 -j LOG --log-prefix PING-DROP:
  iptables -A INPUT -p icmp -j DROP

  iptables -A OUTPUT -p icmp -j ACCEPT
  iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
  iptables -A INPUT -f -j DROP
  iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
  iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
  iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

  iptables-save >/etc/iptables/rules.v4
  iptables -S
}

(
  set -e
  cleanOldRules
  applyRules
)

errorCode=$?
if [ $errorCode -ne 0 ]; then
  echo "Error in common-rules: $errorCode"
  exit $errorCode
fi
