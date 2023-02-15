#!/bin/bash

bash ./hosts-file/index.sh

bash ./firewall/common-rules.sh

bash ./firewall/block_range.sh

bash ./firewall/block_ips.sh
