#!/bin/bash

dvd=$1
mkdir -p /var/log/lesslinux
xorriso -as cdrecord -checkdrive dev=/dev/${dvd} > /var/log/lesslinux/xocheckdrive-${dvd}.log 2>&1 

