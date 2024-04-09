#!/bin/bash

source ./firewall/constants.sh

block_range() {
    SRC_URL="https://gitlab.com/haikelfazzani/blocklist/-/raw/master/ips/range.txt"

    curl -s -X GET \
        -H "Accept: plain/text" \
        "$SRC_URL" >$TEMP_FILE_PATH

    uniq_ips=$(awk '{if (++dup[$0] == 1) print $0;}' $TEMP_FILE_PATH)

    ipset_name="malicious-range"

    ipset -q flush $ipset_name
    ipset create $ipset_name hash:net -exist

    # echo "$uniq_ips"
    echo "$uniq_ips" >$TEMP_FILE_PATH

    sed -r -i '/^\s*$/d; /^[[:blank:]]*#/d;s/#.*//' $TEMP_FILE_PATH

    while read -r ip_range; do
        ip=$(echo $ip_range | sed -r 's/\/.*//g')

        if [[ "$ip" =~ $ipRegexV4 ]]; then
            ipset add $ipset_name $ip_range -exist
            # echo "==> $ip_range"
        else
            echo $ip_range >>$TEMP_FILE_INVALID_PATH
            sed -i "/$ip/d" $TEMP_FILE_PATH
        fi
    done <"$TEMP_FILE_PATH"

    ipset save

    iptables -D INPUT -m set --match-set $ipset_name src -j DROP 2>/dev/null
    iptables -D OUTPUT -m set --match-set $ipset_name src -j DROP 2>/dev/null

    iptables -I INPUT -m set --match-set $ipset_name src -j DROP
    iptables -I OUTPUT -m set --match-set $ipset_name src -j DROP

    iptables-save >/etc/iptables/rules.v4
    iptables -S
}

(
    set -e
    block_range
)

errorCode=$?
if [ $errorCode -ne 0 ]; then
    echo "Error in block_ips file: $(basename "$0"):$LINENO - Exit code: $errorCode"
    exit $errorCode
fi
