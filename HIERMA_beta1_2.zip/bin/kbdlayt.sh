#!/usr/bin/env bash
dest_path="$("$scriptdir/hierma_getparm.sh" dest_path)"

dialog --title "Keyboard Layout" --infobox "Please wait, gathering the keyboard layouts..." 3 50

# Assemble a list of keyboard layouts unless it exists already.
if [ ! -f kbdlayt.tmp ]; then
    precopy="$(find "$dest_path" -iname precopy1.cab)"
    cabextract "$precopy" -F multilng.inf -q
    unix2dos multilng.inf 2> /dev/null
    echo >> multilng.inf

    #"$scriptdir/hierma_infsect.sh" -f multilng.inf -t KeyboardList | awk -F',' '{print $1}' > kbdlayt.tmp
    "$scriptdir/hierma_infsect.sh" -f multilng.inf -s HIERMA_ALL -g OptionDesc | sed 's/\%//g' > kbdlayt.tmp
    awk -F':' '{print $2}' kbdlayt.tmp > kbdstr.tmp
    "$scriptdir/hierma_infsect.sh" -f multilng.inf -s Strings -l kbdstr.tmp -g | awk -F'=' '{print $2}' | sed 's/\"//g;s|^British$|British/Scottish|g' > kbdstr2.tmp && mv kbdstr2.tmp kbdstr.tmp
fi

# Put the list into a menu
index=0
while read kbdl; do
    # Start with only the actual keyboard names in the left column.
    col1="$(echo $kbdl | awk -F':' '{print $1}')"
    menu[$index]="$col1"
    index=$((index+2))
done < kbdlayt.tmp

index=1
while read kbdstr; do
    menu[$index]="$kbdstr"
    index=$((index+2))
done < kbdstr.tmp

# Display the menu
kbdlchoice=$(dialog --title "Keyboard Layout" --menu "Select the keyboard layout which most closely matches your keyboard." 23 78 16 "${menu[@]}" 3>&1 1>&2 2>&3)
if [ $? = 0 ]; then
    "$scriptdir/hierma_setparm.sh" kbdlayt "$kbdlchoice"
    od="$("$scriptdir/hierma_infsect.sh" -f multilng.inf -s "$kbdlchoice" -g OptionDesc | sed 's/\%//g')"
    kbdldesc="$("$scriptdir/hierma_infsect.sh" -f multilng.inf -s Strings -g "$od" | sed 's/\"//g')"

    # Surely you must have some understanding, right?
    if [ "$kbdldesc" = "British" ]; then
        kbdldesc="British/Scottish"
    fi

    "$scriptdir/hierma_setparm.sh" kbddesc "$kbdldesc"
fi
rm multilng.inf 2> /dev/null
