#!/bin/sh
export FASTD_SOCKET=/var/run/fastd-status.$1.sock
/usr/local/bin/fastd-query connections
