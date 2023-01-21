#!/usr/bin/env bash
# Infsect!
#
# This is a shared script for grabbing the contents of INFs and assigning
# values to fields in them. Works with INIs too since they're largely
# the same format.
#
# Parameters:
# -f: INF file name
# -l: File containing list of parameters
# -s: INF section name
# -g: Get field value
# -p: Put new value to field
# -d: Delete field
# -a: Append to existing value with comma
# -r: Remove comma-terminated subvalue in field
# -t: Print all contents of section
# -x: Delete section
#
# Read the documentation for usage guidelines.

# $write indicates if the file is being written to, which thereby controls
# whether the temporary INF gets copied to the source INF or not.

switch_lineno() {
awk -F'\t' '{print $2 ";" $1}' infsect.tmp | sed 's/;\s*/;/g' > infsect2.tmp && mv infsect2.tmp infsect.tmp
}

section_rebuild() {
cat -n "$inf" | sed -n "s|;.*$||g;s|$section|$section|Ig;s|\s*=\s*|=|g;/\[$section\]/,/\[/p" | sed '$d' > infsect.tmp
}

infsect_get() {
if [ "$section" = "HIERMA_ALL" ]; then
    for section_all in $(grep '^\[' "$inf" | sed 's/[][]//g'); do
        cat -n "$inf" | sed -n "s|;.*$||g;s|$section_all|$section_all|Ig;s|\s*=\s*|=|g;/\[$section_all\]/,/\[/p" | sed '$d' > infsect.tmp
        switch_lineno
        allget="$(grep -i "^$get=" infsect.tmp | awk -F'=' '{print $2}' | awk -F';' '{sub(FS $NF,x); print}')"
        if [ ! -z "$allget" ]; then
            # Lean down the output by only showing what has a value.
            echo $section_all:$allget
        fi
    done
else
    returnget="$(grep -i "^$get=" infsect.tmp | awk -F'=' '{print $2}' | awk -F';' '{sub(FS $NF,x); print}' | head -n1)"
    if [ "$listfile" ]; then
        echo $get=$returnget
    else
        echo $returnget
    fi
fi
}

infsect_put() {
# If the section does not exist, create it.
if [ ! -s infsect.tmp ]; then
    sed "\$a\[$section\]\n$put\n" "$inf" > infsect.tmp && mv infsect.tmp "$inf"
    # Update infsect.tmp for successive writes to the new section.
    section_rebuild
    switch_lineno
else
    lineno=$(grep -i "^$putfield=" infsect.tmp | awk -F';' '{print $NF}')
    if [ -z "$lineno" ]; then
        # Check if it's a solitary value with no equals...
        lineno=$(grep -i "^$putfield/" infsect.tmp | awk -F';' '{print $NF}')
        if [ -z "$lineno" ]; then
        # Field does not exist. Append.
        lineno=$(tail -n1 infsect.tmp | awk -F';' '{print $NF}')
        sed "${lineno}s|$|\n$put|" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
        fi
    else
        # Field exists and must be replaced now.
        sed "${lineno}s|.*|$put|g" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
    fi
fi
}

infsect_delete() {
lineno=$(grep -i "^$delete" infsect.tmp | awk -F';' '{print $NF}' | head -n1)
# Need this to check for an EXACT match!
# Beta 1.2: This option doesn't use case sensitivity.
oldval="$(sed -n "s/ //g;${lineno}p" "$inf" | awk -F'=' '{print $1}')"
delmatch=$(awk -vs1="$delete" -vs2="$oldval" 'BEGIN {
    if ( tolower(s1) == tolower(s2) ) {
        print "YES"
    }
}')
if [ "$delmatch" = "YES" ]; then
    sed "${lineno}d" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
    section_rebuild
    switch_lineno
fi
unset delmatch
}

infsect_dellead() {
lineno=$(grep -i "^$deletel" infsect.tmp | awk -F';' '{print $NF}' | sed 's/\s//g' | head -n1)
if [ ! -z "$lineno" ]; then
    sed "${lineno}d" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
    section_rebuild
    switch_lineno
fi
}

infsect_append() {
if [ ! -s infsect.tmp ]; then
    # If the section doesn't exist, create it and add the value.
    sed "\$a\[$section\]\n$get=$append\n" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
    # Update infsect.tmp for successive writes to the new section.
    section_rebuild
    #switch_lineno
else
    # Check if a value already exists.
    oldval=$(grep -i "^$get=" infsect.tmp | awk -F'=' '{print $2}' | awk -F';' '{sub(FS $NF,x); print}')

    # Account for the different character combinations.
    existingvalue=$(echo $oldval | grep -i "^$append$")
    if [ -z "$existingvalue" ]; then
        existingvalue=$(echo $oldval | grep -i "^$append,")
        if [ -z "$existingvalue" ]; then
        existingvalue=$(echo $oldval | grep -i ",$append,")
        fi
        if [ -z "$existingvalue" ]; then
        existingvalue=$(echo $oldval | grep -i ",$append$")
        fi
    fi

    if [ -z "$oldval" ]; then
        # Either the field or value doesn't exist. Delete the field
        # and replace with new field and value.
        lineno=$(tail -n1 infsect.tmp | awk -F';' '{print $NF}')
        sed "s|^$get=.*||g;${lineno}s|$|\n$get=$append|" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
        section_rebuild
        switch_lineno
    elif [ -z "$existingvalue" ]; then
        # Append to existing field only if value isn't already in it.
        lineno=$(grep -i "^$get=" infsect.tmp | awk -F';' '{print $NF}')
        sed "${lineno}s|$|,$append|" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
        # There's a weird little quirk where a trailing comma may be
        # added if using a listfile. The following line removes it.
        sed "${lineno}s|,$||" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
    fi
fi
}

infsect_remove() {
fullfield=$(grep -i "^$get=" infsect.tmp)

# First, check in between commas.
existingvalue1=$(echo "$fullfield" | grep -i ",$remove,")
# Next, check between equals and comma.
existingvalue2=$(echo "$fullfield" | grep -i "=$remove,")
# Check between comma and end of line.
existingvalue3=$(echo "$fullfield" | sed 's/[ \t]*$//g' | grep -i ",$remove;")
# Check between equals and end of line.
existingvalue4=$(echo "$fullfield" | sed 's/[ \t]*$//g' | grep -i "=$remove;")
lineno=$(echo $fullfield | awk -F';' '{print $NF}')

# Test for each of the surrounding character combinations.
# ,value,
if [ ! -z "$existingvalue1" ]; then
baseexist="$(echo $existingvalue1 | grep -oi ",$remove," | sed 's/=//g;s/,//g')"
if [ "$remove" = "$baseexist" ]; then
    sed "${lineno}s|,$remove||" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
fi

# =value,
elif [ ! -z "$existingvalue2" ]; then
baseexist="$(echo $existingvalue2 | grep -oi "=$remove," | sed 's/[=,]//g')"
if [ "$remove" = "$baseexist" ]; then
    sed "${lineno}s|$remove,||" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
fi

# ,value; (semicolon is end of line, line number comes after)
elif [ ! -z "$existingvalue3" ]; then
baseexist="$(echo $existingvalue3 | grep -oi ",$remove;" | sed 's/[=,;]//g')"
if [ "$remove" = "$baseexist" ]; then
    sed "${lineno}s|,$remove$||" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
fi

# =value;
elif [ ! -z "$existingvalue4" ]; then
baseexist="$(echo $existingvalue4 | grep -oi "=$remove;" | sed 's/[=;]//g;s/,//g')"
if [ "$remove" = "$baseexist" ]; then
    sed "${lineno}d" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
fi
fi
}

write=0
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -f|--file)
        srcinf="$2"
        shift
        shift
        # If the file doesn't exist, create it.
        if [ ! -f "$srcinf" ]; then
            touch "$srcinf"
        fi
        cp "$srcinf" srcinf.tmp 2> /dev/null
        dos2unix srcinf.tmp 2> /dev/null
        inf="srcinf.tmp"
        ;;
    -s|--section)
        section="$(echo $2 | sed 's/&/\\&/g')"
        shift
        shift
        if [ -z "$srcinf" ]; then
            >&2 echo 'INF or INI not specified!'
            rm srcinf.tmp
            exit 1
        elif [ -z "$section" ]; then
            >&2 echo 'Section not specified!'
            rm srcinf.tmp
            exit 1
        fi
        if [ "$section" = "HIERMA_ALL" ]; then
            # What's with all the HIERMA branding? You some kinda narcissist?
            # HIERMA_ALL means just work with the entire file regardless
            # of the section.
            cp "$inf" infsect.tmp
            switch_lineno
        else
            section_rebuild
        fi
        switch_lineno
        ;;
    -l|--list)
        # Repeat an operation on a section using a list of parameters
        # in a file. If used, a file operation argument like -g or -p
        # should be empty.
        listfile="$2"
        shift
        shift
        ;;
    -t|--print-section)
        print_section="$(echo $2 | sed 's/&/\\&/g')"
        shift
        shift
        if [ -z "$srcinf" ]; then
            >&2 echo 'INF or INI not specified!'
            exit 1
        fi
        # Print out the entire contents of the section; used instead of -s.
        sed -n "s|;.*$||g;s|$print_section|$print_section|Ig;s|\s*=\s*|=|g;/\[$print_section\]/,/\[/p" "$inf" | sed '$d;1d;/^\s*$/d'
        ;;
    -g|--get)
        # Only useful for entries with equals values.
        if [ "$listfile" ]; then
            shift
            while read get; do
                infsect_get
            done < "$listfile"
            # Unset the listfile variable for successive operations in the
            # same execution.
            unset listfile
        else
            get="$2"
            shift
            shift
            infsect_get
        fi
        # Returned to standard output in your script.
        # If using with -a or -r, redirect stdout to /dev/null.
    ;;
    -p|--put)
        write=1
        # If the file is empty, pad it with a newline.
        if [ ! -s "$inf" ]; then
            echo >> "$inf"
        fi

        # Use this instead of -g if assigning a value to a field.
        # If the field exists, it will be replaced.
        # Syntax: field=value
        if [ "$listfile" ]; then
            shift
            while read put; do
                infsect_put
            done < "$listfile"
            unset listfile
        else
            put="$(echo $2 | sed 's|\s*=\s*|=|g;s:\\:\\\\:g;s/&/\\&/g')"
            shift
            shift
            putfield="$(echo $put | awk -F'=' '{print $1}')"
            infsect_put
        fi
    ;;
    -d|--delete)
        write=1
        # Use this argument to delete a value from an INF script.
        if [ "$listfile" ]; then
            shift
            while read delete; do
                infsect_delete
            done < "$listfile"
            unset listfile
        else
            delete="$(echo $2 | sed 's:\\:\\\\:g;s/&/\\&/g')"
            shift
            shift
            infsect_delete
        fi
    ;;
    -e|--delete-leading)
        write=1
        # Use this argument to delete a line from an INF script which
        # contains a leading string. Useful for changing registry or INI
        # entries where fields may not have equals '=' values.
        # Only the first match from the top of the INF is deleted!

        if [ "$listfile" ]; then
            shift
            while read deletel; do
                infsect_dellead
            done < "$listfile"
            unset listfile
        else
            deletel="$(echo $2 | sed 's:\\:\\\\:g;s/&/\\&/g')"
            shift
            shift
            infsect_dellead
        fi
    ;;
    -a|--append)
        write=1
        # If the file is empty, pad it with a newline.
        if [ ! -s "$inf" ]; then
            echo >> "$inf"
        fi

        # Use this argument to add an additional value to an existing field
        # without affecting the others. This needs to be invoked with -g.
        # Useful for CopyFiles and other directives.
        if [ -z "$get" ]; then
            >&2 echo '-a must be used with -g. Exiting.'
            exit 1
        fi

        if [ "$listfile" ]; then
            shift
            while read append; do
                infsect_append
            done < "$listfile"
            unset listfile
        else
            append="$(echo $2 | sed 's:\\:\\\\:g;s/&/\\&/g')"
            shift
            shift
            infsect_append
        fi
    ;;
    -r|--remove)
        write=1
        # Use this argument to remove one value from an existing field
        # without affecting the others. This needs to be invoked with -g.
        if [ -z "$get" ]; then
            >&2 echo '-r must be used with -g. Exiting.'
            exit 1
        fi

        if [ "$listfile" ]; then
            shift
            while read remove; do
                infsect_remove
            done < "$listfile"
            unset listfile
        else
            remove="$(echo $2 | sed 's:\\:\\\\:g;s/&/\\&/g')"
            shift
            shift
            infsect_remove
        fi
    ;;
    -x|--delete-section)
        write=1
        # Use this argument to delete an entire section.
        # Don't use -s if using -this argument, just specify the name of
        # the section to delete, like -x DefaultInstall
        section="$(echo $2 | sed 's/&/\\&/g')"
        shift
        shift
        if [ -z "$inf" ]; then
            >&2 echo 'INF or INI not specified!'
            exit 1
        fi
        # Only the line numbers are stored in infsect.tmp.
        # Line numbers are sorted in reverse order to prevent
        # successive line numbers from not existing anymore.
        cat -n "$inf" | sed -n "s|$section|$section|Ig;/\[$section\]/,/\[/p" | sed '$d' | awk '{print $1}' | sort -r > infsect.tmp
        while read lineno; do
            # Section lines are deleted one by one, going back around to
            # the file for each line.
            sed "${lineno}d" "$inf" > infsect2.tmp && mv infsect2.tmp "$inf"
        done < infsect.tmp
    ;;
    -h|--help)
        # Don't have update scripts in place, but I'm sure some of you are
        # interested in knowing how Infsect works...
        echo placeholder
    ;;
esac
done
set -- "${POSITIONAL[@]}"

# Those line break differences confused the hell out of me, yet somehow
# I figured it out without spending five days.
if [ $write = 1 ]; then
    cp "$inf" "$srcinf" 2> /dev/null
    unix2dos "$srcinf" 2> /dev/null
fi
rm infsect.tmp srcinf.tmp 2> /dev/null
