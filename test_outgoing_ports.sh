#!/bin/bash

output=available_ports.txt
echo "" > $output

#nc -zv portquiz.net 1-65535 2>&1 | grep "succeeded"

for i in $(seq 1 65535); do
    echo "testing $i..."
    nc -zv portquiz.net $i 2>&1 | grep "succeeded" >> $output
done

echo
echo "--= DONE =--"
echo
