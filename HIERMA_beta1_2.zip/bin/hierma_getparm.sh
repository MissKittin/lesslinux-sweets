#!/bin/sh
# TODO: Combine the database functions into ONE script. You've got a hell of
# a lot of work to backtrack on... (or you know maybe it's not all that needed)

# HIERMA script to retrieve a data entry from a configuration database.
# The result is fed to the standard output handle for use in your script.
#
# Parameters:
# $1 = entry to retrieve
# $2 = name of section (default: WORKING)
# $3 = name of configuration file (default: hierma.conf)

scriptdir="$(dirname $0)"

entry="${1:-ERROR}"
section="${2:-WORKING}"
db="${3:-working.conf}"

# If $entry or $newvalue is missing, exit with error code 1.
if [ "$entry" = "ERROR" ]; then
    >&2 echo First parameter not specified. This script is buggy and
    >&2 echo you should complain to the writer about it.
    exit 1
fi

# Isolate the specified section and return value to standard output.
if [ "$entry" = "ERROR" ] || [ -z "$(sed -n "s|#.*$||g;/$section {/,/}/p;" "$db" | sed "1d;$ d" | grep ^$entry=)" ] || [ -z "$(sed -n "s|#.*$||g;/$section {/,/}/p;" "$db")" ] || [ ! -f "$db" ]; then
    exit 1
else
    sed -n "s|#.*$||g;/$section {/,/}/p;" "$db" | sed "1d;$ d" | grep "^$entry=" | sed -n "s|^$entry=||g;s|^[ \t]*||;1p"
fi
