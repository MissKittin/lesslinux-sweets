#!/bin/bash
unxz -c "$1" | dd of="/dev/${2}" bs=512 seek="$3"
