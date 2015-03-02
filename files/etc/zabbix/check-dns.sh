#!/bin/sh

if [ `host ffnord.net 127.0.0.1 | grep "has address" | wc -l` -gt 0 ]; then
  echo "1"
else
  echo "0"
fi
