#!/bin/bash

fcdir=/tmp/firefox_decrypt-0.7.0
if [ -d /usr/share/lesslinux/firefox_decrypt-0.7.0 ] ; then
	fcdir=/usr/share/lesslinux/firefox_decrypt-0.7.0
fi
cd "$fcdir" 
echo '' | python3 firefox_decrypt.py -n -f csv "$1"

