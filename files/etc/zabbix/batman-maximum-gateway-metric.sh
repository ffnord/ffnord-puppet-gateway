#!/bin/bash

GATEWAYS=$(/usr/sbin/batctl -m bat-$1 gwl | awk -F' ' 'NR <= 1 {next} {print $1}')
METRIC=0

for i in $GATEWAYS
do
	TRACEROUTE=$(/usr/sbin/batctl -m bat-$1 traceroute "$i" | awk 'NR>1')
	if [[ "$TRACEROUTE" =~ "Unreachable" ]]; then
		echo 99
		exit
	fi

	THISMETRIC=$(wc -l <<< $TRACEROUTE)

	if [ "$THISMETRIC" -gt "$METRIC" ]; then
		METRIC=$THISMETRIC
	fi
done

echo $METRIC
