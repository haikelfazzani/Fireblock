#!/bin/bash

source ./firewall/constants.sh

fetch_list_ip() {
    echo "Start fetching.."

    SRC_URL="https://raw.githubusercontent.com/stamparm/ipsum/master/ipsum.txt"

    curl -s -X GET \
        -H "Accept: plain/text" \
        "$SRC_URL" >$TEMP_FILE_PATH

    awk '{if (++dup[$0] == 1) print $0;}' $TEMP_FILE_PATH

    sed -i '/^$/d; / *#/d; /\//d' $TEMP_FILE_PATH
    sed -i 's/\s.*//' "$TEMP_FILE_PATH"

    num_lines=$(wc -l <"$TEMP_FILE_PATH")
    echo "Total number of IP: $num_lines"
}

split_temp_file() {
    echo "Split temp file into chunks.."

    input_file="$TEMP_FILE_PATH"
    output_dir="temp"
    max_lines=65000

    if [ ! -d "$output_dir" ]; then
        mkdir "$output_dir"
    fi

    split -l $max_lines -d "$input_file" "$output_dir/part_"
}

process_temp_files() {
    output_dir="temp"
    COUNTER=0
    for file in "$output_dir"/part_*; do
        update_rules "$file" "$COUNTER"
        COUNTER=$((COUNTER + 1))
    done
}

update_rules() {
    TEMP_FILE_PART="$1"
    ipset_name="malicious-ip-$2"

    ipset -q flush $ipset_name
    ipset create $ipset_name hash:net -exist

    echo -e "UPDATING RULES: $ipset_name ($1)"

    while read -r ip; do
        if [[ "$ip" =~ $ipRegexV4 ]]; then
            ipset add $ipset_name $ip -exist
        else
            echo $ip >>$TEMP_FILE_INVALID_PATH
            sed -i "/$ip/d" $TEMP_FILE_PART
        fi
    done <"$TEMP_FILE_PART"

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
    fetch_list_ip
    split_temp_file
    process_temp_files
)

errorCode=$?
if [ $errorCode -ne 0 ]; then
    echo "Error in block_ips file: $(basename "$0"):$LINENO - Exit code: $errorCode"
    exit $errorCode
fi
