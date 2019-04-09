#!/bin/sh

grep -rn "GET" | sed -n "/[A-Za-z_ ]*([A-Za-z_0-9 ]*, *GET,/p" | awk -F "," '{print $3}' | sed "s/\"//g" | sed "s/^ *\//\//g" > apis.txt
