#!/usr/bin/env bash

dest_path="$($scriptdir/hierma_getparm.sh dest_path)"
src_path="$($scriptdir/hierma_getparm.sh src_path)"
# Some terminologies are inconsistent, probably needs fixing.
choice_type="$($scriptdir/hierma_getparm.sh ostype)"

select_path() {
choice=""
index=0
menu[$index]="Other"
index=$((index+1))
menu[$index]="Specify another setup path on the medium"
index=$((index+1))

basesrc=$(basename "$src_path")
dialog --title "Finding Install Directories" --infobox "Looking for valid install paths in $basesrc" 3 70
find "$src_path" -iname PRECOPY1.CAB > ospath.tmp
while read ospath; do
    precopy1_md5=$(md5sum $ospath | awk '{print $1}')
    col1=$(dirname $ospath | sed "s|^$src_path/||g")
    dircheck=$(dirname $(grep "^$col1" ospath.tmp))
    col2=$(grep $precopy1_md5 "$scriptdir/checksum.conf" | awk -F':' '{print $3}')

    if [ "$col1" = "$dircheck" ]; then
        menu[$index]="./"
    else
        menu[$index]="$col1"
    fi
    index=$((index+1))
    if [ "$col2" = "" ]; then
        menu[$index]="Unknown"
    else
        menu[$index]="$col2"
    fi
    index=$((index+1))    
done < ospath.tmp

choice=$(dialog --title "Found Install Directories" --menu 'Select one of the operating systems found on the medium, or "Other" to specify a different path.' 18 75 10 "${menu[@]}" 3>&1 1>&2 2>&3)
if [ $? != 0 ]; then # did user hit cancel?
    exit 1
fi
}

other_path() {

# BUGFIX NEEDED!
# Selecting "Other", then "Back", and selecting a found path causes
# directory path redundancy.

choice=$(dialog --title "Other Setup Directory" --dselect "$src_path" 9 75  3>&1 1>&2 2>&3)
otherexit=$?
src2="$src_path"
unset src_path
if [ $otherexit != 0 ]; then # did user hit cancel?
    src_path="$src2"
    unset src2
    rm ospath.tmp
    exit 2  # repeat this script from hierma.sh
fi
}

os_check() {

# Only do this unless ostype is already defined in the database.
# A user can override the found operating system type by defining it
# in said database!
if [ -z "$choice_type" ]; then

# Check the selected operating system for a match again.
choice_md5=$(for i in $(find "$choice" -iname precopy1.cab); do md5sum $i | awk -F '[= ]' '{print $1}'; done)
choice_md5err=$?
# Grab the short identifier of the matching checksum.
choice_typesearch=$(cat "$scriptdir/checksum.conf" | grep "^$choice_md5")
choice_typeerr=$?
if [ $choice_md5err != 0 ] || [ $choice_typeerr != 0 ]; then
    # The distinguishing file was not found, or did not match up
    # with any of the known releases!
    # Display a menu for selecting an OS type manually.

    # Beta 1.2: Converted to static menu for faster execution.
    choice_type=$(dialog --title "Operating System Selection" --menu 'The operating system path you selected does not match any known or currently supported release. Please select one of the options which most closely matches your build.' 15 75 5 \
        'win95' 'Windows 95 RTM' \
        'win95b' 'Windows 95 OSR2' \
        'win98' 'Windows 98' \
        'win98se' 'Windows 98 Second Edition' \
        'winme' 'Windows ME'
        3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then # did user hit cancel?
        rm ospath.tmp
        exit 2  # Repeat this script from hierma.sh
    else
        "$scriptdir/hierma_setparm.sh" ostype $choice_type
        # This is constant for now, will change when DOS/Windows NT becomes
        # supported.
        "$scriptdir/hierma_setparm.sh" setupcmd SETUP.EXE
    fi
else
    # A match was found, now isolate the short identifier.
    choice_type=$(echo $choice_typesearch | awk -F':' '{print $2}')
    "$scriptdir/hierma_setparm.sh" ostype $choice_type
fi

fi

}

copy_local() {

# Should the prompt exit normally, begin copying the files.
if [ -z "$src_path" ]; then
total=$(find "$choice" | wc -l)

cp -Rv "$choice/"* "$dest_path" |
while read filename other
do
    count=$((count+1))
    percent=$((count*100/total))
    currentfile=$(echo $filename | tr -d \')
    echo "XXX"
    echo "$percent"
    echo "Copying $(basename $currentfile)"
    echo "XXX"
done | dialog --title "Local Copy" --gauge "Now copying the setup files..." 6 75 0
else
total=$(find "$src_path/$choice" | wc -l)

cp -Rv "$src_path/$choice/"* "$dest_path" |
while read filename other
do
    count=$((count+1))
    percent=$((count*100/total))
    currentfile=$(echo $filename | tr -d \')
    echo "XXX"
    echo "$percent"
    echo "Copying $(basename $currentfile)"
    echo "XXX"
done | dialog --title "Local Copy" --gauge "Now copying the setup files..." 6 75 0
fi

# Remember to have this removed at the end!
# Also update config scripts to use this temporary directory.
# Yeah, I'm storing them on the destination due to concerns with RAM,
# but this will probably change as swapfile creation is implemented.
dialog --title "Local Copy" --infobox "Extracting PRECOPY files to temporary directory..." 3 57
mkdir "$dest_path/htemp" 2> /dev/null
find "$dest_path" -iname precopy1.cab -exec cabextract -L -q -d "$dest_path/htemp" '{}' \;

}

# Actually execute the stuff over here and learn the basics.
if [ $EXPRESS != 1 ]; then
# Interactive run.
select_path
if [ "$choice" = "Other" ]; then
    other_path
fi
fi
# Either unattended or interactive runs. os_check may stop for user input if
# the operating system is not known.
os_check
# Runs only if os_check completed normally.
copy_local

rm ospath.tmp 2> /dev/null
exit 0
