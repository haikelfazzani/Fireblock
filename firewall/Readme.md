# Firewall

## Install
```shell
apt install ipset iptables netfilter-persistent ipset-persistent iptables-persistent
```

## Iptables common rules

**DROP RFC1918 PACKETS**
```shell
-A INPUT -s 10.0.0.0/8 -j DROP
-A INPUT -s 172.16.0.0/12 -j DROP
-A INPUT -s 192.168.0.0/16 -j DROP
```

**Outbound UDP Flood protection**
```shell
iptables -N udp-flood
iptables -A OUTPUT -p udp -j udp-flood
iptables -A udp-flood -p udp -m limit --limit 50/s -j RETURN
iptables -A udp-flood -j LOG --log-level 4 --log-prefix 'UDP-flood attempt: '
iptables -A udp-flood -j DROP
```

**prevent flooding general**
```shell
iptables -N udp-flood
iptables -A udp-flood -m limit --limit 4/second --limit-burst 4 -j RETURN
iptables -A udp-flood -j DROP
iptables -A INPUT -i eth0 -p udp -j udp-flood
iptables -A INPUT -i eth0 -f -j DROP
```

**prevent amplification attack**
```shell
iptables -N DNSAMPLY
iptables -A DNSAMPLY -p udp -m state --state NEW -m udp --dport 53 -j ACCEPT
iptables -A DNSAMPLY -p udp -m hashlimit --hashlimit-srcmask 24 --hashlimit-mode srcip --hashlimit-upto 30/m --hashlimit-burst 10 --hashlimit-name DNSTHROTTLE --dport 53 -j ACCEPT
iptables -A DNSAMPLY -p udp -m udp --dport 53 -j DROP
```

## Notes
- [A Tutorial for Controlling Network Traffic with iptables](https://www.linode.com/docs/guides/control-network-traffic-with-iptables/)
- [IPset reference](https://manpages.debian.org/testing/ipset/ipset.8.en.html)
- [Iptables Essentials](https://github.com/trimstray/iptables-essentials/blob/master/README.md#xmas-packets)
- [IPtables persist](https://unix.stackexchange.com/questions/52376/why-do-iptables-rules-disappear-when-restarting-my-debian-system)

# License
MIT