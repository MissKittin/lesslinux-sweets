#!/bin/bash

dvd=$1
mkdir -p /var/log/lesslinux
xorriso -dev /dev/${dvd} -toc > /var/log/lesslinux/xotoc-${dvd}.log 2>&1
# xorriso -dev /dev/${dvd} -list_formats > /var/log/lesslinux/xotoc-${dvd}.log 2>&1
