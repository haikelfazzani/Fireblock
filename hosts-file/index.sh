#!/bin/bash

# colors
Color_Off='\033[0m' # Text Reset
Red='\033[0;31m'    # Red
Green='\033[0;32m'  # Green
Yellow='\033[0;33m' # Yellow

# update /etc/hosts
declare -a remote_files=("_domains" "apple" "cloudfront" "common" "facebook" "google" "microsoft" "msn" "twitter" "yahoo")
TEMP_FILE_PATH='./hosts-file/hosts_file.tmp'
HOSTS_FILE_PATH='/etc/hosts'

date=$(date +%F)
hostname=$(hostname)

echo -e ">>${Green} [Start] updating /etc/hosts ${Color_Off}"

HEADER="# Last updated: $date\n
\n
# The following lines are desirable for IPv4 capable hosts\n
\n\n
127.0.0.1       localhost\n
127.0.1.1       $hostname\n
# The following lines are desirable for IPv6 capable hosts\n
\n\n
::1             localhost ip6-localhost ip6-loopback\n
fe00::0         ip6-localnet\n
ff02::1         ip6-allnodes\n
ff02::2         ip6-allrouters\n
ff02::3         ip6-allhosts\n
\n\n
# The following lines are desirable for blocked domains\n
\n"

echo -e $HEADER >$TEMP_FILE_PATH

for i in "${remote_files[@]}"; do
  domains=$(curl -s -X GET \
    -H "Content-type: text/plain; charset=UTF-8" \
    -H "Accept: text/plain; charset=UTF-8" \
    "https://gitlab.com/haikelfazzani/blocklist/-/raw/master/hosts/_domains.txt")

  echo "$domains" | sed 's/[|^]//g; /^$/d; s/ *$//' | sed -E "/^[^#]/ s/^/0.0.0.0       /" >>$TEMP_FILE_PATH
  echo -e "> ${Yellow} [End Processing] $i ${Color_Off}"
done

awk -i inplace '!seen[$0]++' $TEMP_FILE_PATH
sed -i -e 's/0.0.0.0.*#/# /g' $TEMP_FILE_PATH
cat $TEMP_FILE_PATH >$HOSTS_FILE_PATH

echo -e ">>${Green} [End] updating /etc/hosts ${Color_Off}"
