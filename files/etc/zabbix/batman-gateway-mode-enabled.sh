#!/bin/sh
/usr/sbin/batctl -m bat-$1 gw | grep server | wc -l
