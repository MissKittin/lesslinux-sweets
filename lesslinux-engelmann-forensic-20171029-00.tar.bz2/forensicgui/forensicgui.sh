#!/bin/bash

pwd=` dirname "$0" `
cd "$pwd"
ruby -I . -I /usr/share/lesslinux/drivetools forensicgui.rb
