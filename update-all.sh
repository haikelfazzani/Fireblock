#!/bin/bash

./hosts-file/index.sh

./firewall/common-rules.sh

./firewall/block_range.sh

./firewall/block_ips.sh
