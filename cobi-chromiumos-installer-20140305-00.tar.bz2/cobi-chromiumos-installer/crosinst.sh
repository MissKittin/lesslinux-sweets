#!/bin/bash

cd /usr/share/lesslinux/cobi-chromiumos-installer
ruby -I . -I /usr/share/lesslinux/drivetools crosinst.rb $@
