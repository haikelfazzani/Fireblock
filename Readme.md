# Fireblock
Block Malware, phishing and malicious IPs and websites with on click

# Command
***block websites: update /etc/hosts***
```shell
sudo bash ./hosts-file/index.sh
```

***update firewall rules for range ips***
```shell
sudo bash ./firewall/block_range.sh
```

***update firewall rules for list ips***
```shell
sudo bash ./firewall/block_ips.sh
```

***update firewall rules for common rules***
```shell
sudo bash ./firewall/common-rules.sh
```

# Notes
- [Old Repository](https://gitlab.com/haikelfazzani/hosts)
- [Block list Repository](https://gitlab.com/haikelfazzani/blocklist)

# License
Apache 2.0