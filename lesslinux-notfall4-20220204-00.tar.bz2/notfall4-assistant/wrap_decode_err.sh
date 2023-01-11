#!/bin/bash
# encoding: utf-8
# wrap_decode_err.sh

path="$1"
num="$2"

echo '' | python2 /usr/share/lesslinux/firefox_decrypt-0.7.0/firefox_decrypt.py -c "$num" -n "$path" 2>&1 

