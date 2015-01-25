#!/bin/sh
expr $(/usr/sbin/batctl -m bat-$1 gwl | wc -l) - 1
