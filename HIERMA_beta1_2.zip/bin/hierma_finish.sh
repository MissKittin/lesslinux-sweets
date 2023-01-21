#!/usr/bin/env bash

dest_path="$($scriptdir/hierma_getparm.sh dest_path)"

setupcmd="$($scriptdir/hierma_getparm.sh setupcmd)"
switches="$($scriptdir/hierma_getparm.sh switches)"

# Beta 1.2: This script no longer handles installing the boot manager.

# Install the boot manager, or just create a batch file.

install_bootmgr=$("$scriptdir/hierma_getparm.sh" install_bootmgr)
if [ -z "$install_bootmgr" ]; then
    install_bootmgr=0
fi

dialog --title "Converting Files" --infobox "Assembling list of plain text files..." 3 46
# We're done with MSBATCH.INF now.
mv msbatch.inf "$dest_path/"
dialog --title "Temporary Cleanup" --infobox "Removing temporary files..." 3 32
rm -r txtfiles.tmp lastdir "$dest_path/htemp"

find "$dest_path" \( -iname "*.txt" -o -iname "*.bat" -o -iname "*.inf" -o -iname "*.ini" -o -iname "*.reg" \) > txtfiles.tmp
count=0
total=$(cat txtfiles.tmp | wc -l)
while read txtfile; do
    # Update the progress bar.
    count=$((count+1))
    percent=$((count*100/total))
    echo "XXX"
    echo "$percent"
    echo "Converting $basetxt"
    echo "XXX"

    # Convert the file silently.
    basetxt=$(basename $txtfile)
    cp "$txtfile" ./
    unix2dos $basetxt 2> /dev/null
    mv $basetxt "$dest_path/"
done < txtfiles.tmp | dialog --title "Converting Files to DOS/Windows Format" --gauge "Converting text files..." 7 75

# TODO: Add options to save configuration, as well as to delete the setup
# directory after completion but the latter might be for a future release.
