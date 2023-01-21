#!/usr/bin/env bash
# Registry modification tool.
#
# Parameters:
# -f: Registry file name
# -k: Full registry key path
# -g: Get field value
# -p: Put new value to field
# -d: Delete field
# -x: Delete key from registry file
#
# Read the documentation for usage guidelines.

# HIERMA needs to know what the operating system is in order to add the
# correct registry header.
ostype=$("$scriptdir/hierma_getparm.sh" ostype)

switch_lineno() {
awk -F'\t' '{print $2 ";" $1}' regkey.tmp | sed 's/;\s*/;/g' > regkey2.tmp && mv regkey2.tmp regkey.tmp
}

key_rebuild() {
cat -n "$reg" | sed -n "s|;.*$||g;s|$regkey|$regkey|Ig;s|\s*=\s*|=|g;/\[$regkey\]/,/\[/p" | sed '$d' > regkey.tmp
}

regtool_get() {
get2="$(grep -i "^$get=" regkey.tmp | awk -F'=' '{print $2}' | awk -F';' '{sub(FS $NF,x); print}' | head -n1)"
get3="$(echo $get2 | grep 'hex:')"
# Returned to standard output in your script.
if [ ! -z "$get3" ]; then
    # If value is in a binary format, remove the quote marks.
    # Should values have quote marks when returned to stdout
    # regardless of their type?
    if [ "$listfile" ]; then
        echo $get=$get3
    else
        echo $get3 | sed 's/\"//g'
    fi
else
    if [ "$listfile" ]; then
        echo $get=$get2
    else
        echo $get2
    fi
fi
}

regtool_put() {
equalscheck="$(echo $put | grep '=')"
if [ -z "$equalscheck" ]; then
    >&2 echo 'Invalid input value, are you missing the equals sign?'
    exit 1
fi
putfield="$(echo $put | awk -F'=' '{print $1}')"
# If the registry key does not exist, create it.
if [ ! -s regkey.tmp ]; then
    sed "\$a\[$regkey\]\n$put\n" "$reg" > regkey2.tmp && mv regkey2.tmp "$reg"
    # Update regkey.tmp for successive writes to the new key.
    key_rebuild
    switch_lineno
else
    lineno=$(grep -i "^$putfield=" regkey.tmp | awk -F';' '{print $NF}')
    if [ -z "$lineno" ]; then
        # Field does not exist or does not use an equal sign. Append.

        # NOTE: A non-equals value may be duplicated using this tool.
        # If this is not what you want, delete the previous value
        # prior to adding a new one.

        lineno=$(tail -n1 regkey.tmp | awk -F';' '{print $NF}')
        sed "${lineno}s/$/\n$put/" "$reg" > regkey2.tmp && mv regkey2.tmp "$reg"
    else
        # Field exists and must be replaced now.
        sed "${lineno}s/.*/$put/g" "$reg" > regkey2.tmp && mv regkey2.tmp "$reg"
    fi
fi
}

regtool_delete() {
lineno=$(grep -i "^$delete" regkey.tmp | awk -F';' '{print $NF}' | head -n1)
# Need this to check for an EXACT match!
# Beta 1.2: This option doesn't use case sensitivity.
oldval="$(sed -n "${lineno}p" "$reg" | awk -F'=' '{print $1}' | awk -F';' '{sub(FS $NF,x); print}')"
oldval2="$(echo $delete | grep -i ^$oldval$)"
if [ "$delete" = "$oldval2" ]; then
    sed "${lineno}d" "$reg" > regkey.tmp && mv regkey.tmp "$reg"
    key_rebuild
    switch_lineno
fi
}

write=0
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -f|--file)
        srcreg="$2"
        shift
        shift
        cp "$srcreg" srcreg.tmp 2> /dev/null
        dos2unix srcreg.tmp 2> /dev/null
        reg="srcreg.tmp"
        if [ ! -f "$reg" ]; then
            # If the registry file does not exist, create it.
            case $ostype in
            win2k|winxp)
                # Windows 2000 and XP yet to be supported by HIERMA...
                echo "Windows Registry Editor Version 5.00" >> "$reg"
                echo >> "$reg"
            ;;
            *)
                # For Windows 9x/NT4, use this header.
                echo "REGEDIT4" >> "$reg"
                echo >> "$reg"
            ;;
            esac
        fi
    ;;
    -k|--key)
        # Note the difference between key and regkey in this script.
        regkey="$(echo $2 | sed 's:\\:\\\\:g;s/&/\\&/g')"
        shift
        shift
        if [ -z "$reg" ]; then
            >&2 echo 'Registry file not specified!'
            exit 1
        fi
        key_rebuild
        switch_lineno
    ;;
    -l|--list)
        # Repeat an operation on a key using a list of parameters
        # in a file. If used, a file operation argument like -g or -p
        # should be empty.
        listfile="$2"
        shift
        shift
        ;;
    -t|--print-key)
        print_regkey="$(echo $2 | sed 's:\\:\\\\:g;s/&/\\&/g')"
        shift
        shift
        if [ -z "$reg" ]; then
            >&2 echo 'Registry file not specified!'
            exit 1
        fi
        # Print out the entire contents of the key; used instead of -k.
        sed -n "s|;.*$||g;s|$print_regkey|$print_regkey|Ig;s|\s*=\s*|=|g;/\[$print_regkey\]/,/\[/p" "$reg" | sed '$d;1d;/^\s*$/d'
        ;;
    -g|--get)
        if [ "$listfile" ]; then
            shift
            if [ "$listfile" ]; then
                # Surround get parameters with quote marks temporarily.
                sed 's/^/\"/;s/$/\"/' "$listfile" > newlist
                listfile=newlist
            fi
            while read get; do
                regtool_get
            done < "$listfile"
            unset listfile
            rm newlist 2> /dev/null
        else
            get="$(echo \"$2\" | sed 's/&/\\&/g')"
            shift
            shift
            regtool_get
        fi
    ;;
    -p|--put)
        write=1
        # Use this instead of -g if assigning a value to a field.
        # If the field exists, it will be replaced.
        # Syntax: \"field\"=\"value\"

        # If adding a line for a key to delete, such as
        # -HKEY_LOCAL_MACHINE\OtherThing, leave -p empty.
        if [ "$listfile" ]; then
            shift
            while read put; do
                regtool_put
            done < "$listfile"
            unset listfile
        else
            put="$(echo $2 | sed 's|\s*=\s*|=|g;s:\\:\\\\:g;s/&/\\&/g')"
            shift
            shift
            regtool_put
        fi

    ;;
    -d|--delete)
        write=1
        # Use this argument to delete a value from a registry file.
        if [ "$listfile" ]; then
            shift
            if [ "$listfile" ]; then
                # Surround get parameters with quote marks temporarily.
                sed 's/^/\"/;s/$/\"/' "$listfile" > newlist
                listfile=newlist
            fi
            while read delete; do
                regtool_delete
            done < "$listfile"
            unset listfile
        else
            delete="$(echo \"$2\" | sed 's:\\:\\\\:g;s/&/\\&/g')"
            shift
            shift
            regtool_delete
        fi
    ;;
    -x|--delete-key)
        write=1
        # Use this argument to delete an entire key.
        # Don't use -k if using -this argument, just specify the name of
        # the key to delete, like -x "HKEY_LOCAL_MACHINE\Enum\Something"
        regkey="$(echo $2 | sed 's:\\:\\\\:g;s/&/\\&/g')"
        shift
        shift
        if [ -z "$reg" ]; then
            >&2 echo 'Registry file not specified!'
            exit 1
        fi
        # Only the line numbers are stored in regkey.tmp.
        # Line numbers are sorted in reverse order to prevent
        # successive line numbers from not existing anymore.
        cat -n "$reg" | sed -n "s|$regkey|$regkey|Ig;/\[$regkey\]/,/\[/p" | sed '$d' | awk '{print $1}' | sort -r > regkey.tmp
        while read lineno; do
            # Key lines are deleted one by one, going back around to
            # the file for each line.
            sed "${lineno}d" "$reg" > regkey2.tmp && mv regkey2.tmp "$reg"
        done < regkey.tmp
    ;;
esac
done
set -- "${POSITIONAL[@]}"

if [ $write = 1 ]; then
    cp "$reg" "$srcreg" 2> /dev/null
    unix2dos "$srcreg" 2> /dev/null
fi
rm regkey.tmp srcreg.tmp 2> /dev/null
