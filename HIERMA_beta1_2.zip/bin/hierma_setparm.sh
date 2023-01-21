#!/bin/sh
# HIERMA script to assign a value to a field from a configuration database.
# The result is fed to the standard output handle for use in your script.
#
# Parameters:
# $1 = field to retrieve value from
# $2 = new value to set
# $3 = name of section (default: WORKING)
# $4 = name of configuration file (default: hierma.conf)

scriptdir="$(dirname $0)"

entry="${1:-ERROR}"
newvalue="${2:-DELETE}"
section="${3:-WORKING}"
db="${4:-working.conf}"

# If $entry or $newvalue is missing, exit with error code 1.
if [ "$entry" = "ERROR" ]; then
    >&2 echo First parameter not specified. This script is buggy and
    >&2 echo you should complain to the writer about it.
    exit 1
fi

# If the database was not found, create it.
if [ ! -f "$db" ]; then
    echo "$section {" >> "$db"
    echo "}" >> "$db"
fi

# If the section was not found, create it.
section2=$(grep "$section {" "$db")
if [ -z "$section2" ]; then
    echo >> "$db"
    echo "$section {" >> "$db"
    echo "}" >> "$db"
fi
# Isolate the specified section and get the line number.
lineno="$(cat -n "$db" | sed -n "s|#.*$||g;/$section {/,/}/p" | sed "1d;$ d" | awk -F'\t' '{print $2 "?" $1}' | grep "^$entry=" | awk -F'?' '{print $2}' | sed 's/\s//g')"

oldvalue="$(sed -n "s|#.*$||g;/$section {/,/}/p;" $db | sed "1d;$ d" | grep "^$entry=" | sed "s|.*=||g;s|^[ \t]*||;s|(|\\(|g;s|)|\\)|g")"

newvalue2="$(echo $newvalue | sed 's:\\:\\\\:g;s/&/\\&/g')"

# If the field was not found, a new line should be added to the bottom of the section.
if [ -z "$lineno" ]; then
    if [ "$newvalue" != "DELETE" ]; then
        # Add a new entry with the assigned value.
        lineno="$(cat -n "$db" | sed -n "s|#.*$||g;/$section {/,/}/p;" | sed -n "$ p" | awk '{print $1}')"
        sed "${lineno}s|.*|$entry=$newvalue2\n\}|g" "$db" > setparm.tmp && mv setparm.tmp "$db"
    fi
else
    if [ "$newvalue" = "DELETE" ]; then
        # If the second argument is empty or DELETE, delete the field.
        sed "${lineno}d" "$db" > setparm.tmp && mv setparm.tmp "$db"
    else
        # Assign the new value to the existing entry.
        sed "${lineno}s|.*|$entry=$newvalue2|g" "$db" > setparm.tmp && mv setparm.tmp "$db"
    fi
fi
