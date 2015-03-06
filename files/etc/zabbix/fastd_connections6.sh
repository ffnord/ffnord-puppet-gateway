#!/bin/sh
export FASTD_SOCKET=/var/run/fastd-status.$1.sock
/usr/local/bin/fastd-query peers | grep '"address"' | grep -v any | grep '\[' | wc -l
