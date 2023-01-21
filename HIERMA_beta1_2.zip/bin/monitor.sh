#!/usr/bin/env bash
dest_path="$("$scriptdir/hierma_getparm.sh" dest_path)"

# NOTE: Use find command instead of ls for for loops.
# COMPAQ is missing from the list, Dell monitor appears in ViewSonic,
# and AT&T doesn't work.

# This script has been completely overhauled to use Infsect, and now, instead
# of assembling a giant list of all the monitors at once, only the ones
# from the manufacturer the user selects in the menu are loaded.

mfgmenu() {

# Display the manufacturer menu using the existing mfg.tmp file.
dialog --title "Monitor" --infobox "Creating the manufacturer menu" 3 36

index=0
unset menu
menu[$index]="Generic"
index=$((index+1))
menu[$index]="Standard monitor types"
index=$((index+1))
while read mfg; do
    menu[$index]="$mfg"
    index=$((index+2))
done < mfg.tmp

index=3
while read mfgstr; do
    menu[$index]="$mfgstr"
    index=$((index+2))
done < mfgstr.tmp

mfgchoice=$(dialog --title "Monitor Manufacturer" --menu "Select the manufacturer of your monitor. Unless your monitor was manufactured before 1995 and/or is non-PnP compliant, it's best to select \"Plug and Play Monitor\" under \"Generic\"." 23 75 14 "${menu[@]}" 3>&1 1>&2 2>&3)
mfgexit=$?

}

monmenu() {

# Display the list of monitors pertaining to a manufacturer.
dialog --title "Monitor" --infobox "Assembling monitor list for $mfgchoice" 3 55

if [ ! -f "$mfgchoice.tmp" ]; then
    while read inf; do
        "$scriptdir/hierma_infsect.sh" -f "$inf" -t "$mfgchoice" | awk -F'=' '{print $1}' | sed 's/\%//g' >> "$mfgchoice.tmp"
    done < moninfs.tmp

    if [ "$mfgchoice" = "Generic" ]; then
        sed '/Unknown.DeviceDesc/d' "$mfgchoice.tmp" > g.tmp && mv g.tmp "$mfgchoice.tmp"
    fi

    "$scriptdir/hierma_infsect.sh" -f monstr.tmp -s Strings -l "$mfgchoice.tmp" -g | awk -F'=' '{print $2}' | sed 's/\"//g' > "str_$mfgchoice.tmp"
fi
    
index=0
unset menu
while read mon; do
    menu[$index]="$mon"
    index=$((index+2))
done < "$mfgchoice.tmp"

index=1
while read monstr; do
    menu[$index]="$monstr"
    index=$((index+2))
done < "str_$mfgchoice.tmp"

monchoice=$(dialog --title "$mfgchoice Monitors" --menu "" 23 78 17 "${menu[@]}" 3>&1 1>&2 2>&3 | sed 's/&/\\&/g')
monexit=$?

if [ $monexit = 0 ]; then
    mymondesc="$("$scriptdir/hierma_infsect.sh" -f monstr.tmp -s Strings -g "$monchoice" | sed 's/\"//g')"
    "$scriptdir/hierma_setparm.sh" monitor "$mymondesc"
    exit 0
fi

}

dialog --title "Monitor" --infobox "Please wait, assembling the manufacturer list..." 3 55

# First, assemble a complete list of manufacturers to neatly organize the
# abundant list of monitors.
if [ ! -f mfg.tmp ]; then
    precopy="$(find "$dest_path" -iname "precopy1.cab")"
    cabextract "$precopy" -F monitor.inf -q
    cabextract "$precopy" -F monitor?.inf -q
    unix2dos monitor.inf monitor?.inf 2> /dev/null
    ls -1 monitor* > moninfs.tmp

    # Grab the manufacturer list...
    while read inf; do
        echo >> "$inf"
        "$scriptdir/hierma_infsect.sh" -f "$inf" -t Manufacturer | awk -F'=' '{print $2}' | sed '/^Generic$/d' >> mfg.tmp
        # Create a collective of strings in the many MONITOR?.INF files.
        "$scriptdir/hierma_infsect.sh" -f "$inf" -t Strings >> monstr.tmp
    done < moninfs.tmp
    sort -f mfg.tmp | uniq -i > mfg2.tmp && mv mfg2.tmp mfg.tmp
    # Fool Infsect into thinking this is an INF with a section, I guess.
    sed '1s/^/\[Strings\]\n/;/^Generic=/d' monstr.tmp > monstr2.tmp && mv monstr2.tmp monstr.tmp
    echo >> monstr.tmp

    # ...then get the full name of each manufacturer.
    "$scriptdir/hierma_infsect.sh" -f monstr.tmp -s Strings -l mfg.tmp -g | awk -F'=' '{print $2}' | sed 's/\"//g' > mfgstr.tmp
fi # If the manufacturer list exists, don't build it.

while (true); do

mfgmenu
if [ $mfgexit = 0 ]; then
    monmenu
else
    exit 1
fi

done
