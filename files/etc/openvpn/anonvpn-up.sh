#!/bin/sh
sysctl -w net.ipv4.conf.${1}.rp_filter=0
ip route replace 0.0.0.0/1 via $4 table 42
ip route replace 128.0.0.0/1 via $4 table 42
exit 0
