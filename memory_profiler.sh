#!/bin/bash

while true; do
    usage_string=$(top -l 1 | grep "$1" | awk '{print $9}')
    usage_value=$(egrep -o -m 1 '^[0-9]+' <<< "$usage_string")

    echo -n "$(date +'%T'), "

    if egrep -q 'k|K' <<< "$usage_string"; then
        echo "$((usage_value / 1000))"
    elif egrep -q 'm|M' <<< "$usage_string"; then
        echo "$((usage_value))"
    elif egrep -q 'g|G' <<< "$usage_string"; then
        echo "$((usage_value * 1000))"
    else
        echo "Profiler error." >&2
    fi

    sleep 1
done
