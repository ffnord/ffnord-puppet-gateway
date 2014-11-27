#!/bin/sh
sysctl -w net.ipv4.conf.${1}.rp_filter=0
ip route replace default via $4 table 42
ip rule del pref 30000 || true
ip rule add from $4 lookup 42 pref 30000
exit 0
