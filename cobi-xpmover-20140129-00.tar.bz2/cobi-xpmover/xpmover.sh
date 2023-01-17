#!/bin/bash

cd /usr/share/lesslinux/cobi-xpmover
ruby -I . -I /usr/share/lesslinux/drivetools xpmover.rb $@
