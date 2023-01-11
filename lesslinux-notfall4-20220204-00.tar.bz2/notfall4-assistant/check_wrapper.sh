#!/bin/bash

/AntiVir/scancl --version > /var/log/scancl-check.log 2>&1
retval=$?
echo $retval > /var/log/scancl-check.ret
sleep 2
