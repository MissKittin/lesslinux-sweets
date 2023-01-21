#!/bin/sh
# HIERMA script to retrieve a data entry from a configuration database.
# The result is fed to the standard output handle for use in your script.
#
# Parameters:
# $1 = name of section (default: WORKING)
# $2 = name of configuration file (default: hierma.conf)

scriptdir="$(dirname $0)"

section="${1:-WORKING}"
db="${2:-working.conf}"

sed -n "s|#.*$||g;/$section {/,/}/p;" "$db"
