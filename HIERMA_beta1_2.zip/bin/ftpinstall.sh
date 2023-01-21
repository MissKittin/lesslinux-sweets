#!/usr/bin/env bash
ftpserver=$("$scriptdir/hierma_getparm.sh" ftpserver)
ftppath=$("$scriptdir/hierma_getparm.sh" src_path)
ftpuser=$("$scriptdir/hierma_getparm.sh" ftpuser)
ftppass=$("$scriptdir/hierma_getparm.sh" ftppass)
choice_type=$("$scriptdir/hierma_getparm.sh" ostype)
dest_path=$("$scriptdir/hierma_getparm.sh" dest_path)

ftp_command() {
# Return the appropriate lftp command to stdout, depending on what
# credentials were specified.

if [ -z $ftpuser ]; then
    ftpcmd="lftp ${ftpserver}${ftppath}"
elif [ -z $ftppass ]; then
    ftpcmd="lftp -u $ftpuser ${ftpserver}${ftppath}"
else
    ftpcmd="lftp -u $ftpuser,"$ftppass" ${ftpserver}${ftppath}"
fi

}

get_precopy() {
dialog --title 'Finding Install Directories' --infobox "Looking for valid install paths in ${ftpserver}${ftppath}" 3 70
# Get a list of the PRECOPY1.CAB files in the FTP server and path.
$ftpcmd -e "find; bye" > ftpdir.tmp
grep -i "precopy1.cab$" ftpdir.tmp > ftpprecopy.tmp
rm ftpdir.tmp 2> /dev/null

while read precopy; do
# Grab a PRECOPY1.CAB file and save it to the working directory.
# Get the MD5 checksum of the file and store it in a temporary list.
$ftpcmd -e "get $precopy; bye" > /dev/null
precopy_base=$(basename "$precopy")
echo $precopy\:$(md5sum $precopy_base | awk '{print $1}' | tr '[:upper:]' '[:lower:]') >> precopymd5.tmp
rm $precopy_base

done < ftpprecopy.tmp
rm ftpprecopy.tmp 2> /dev/null

}

select_path() {
# Assemble any found path listings into a menu.
index=0
menu[$index]="Other"
index=$((index+1))
menu[$index]="Specify another setup path on the server"
index=$((index+1))

while read listing; do
    precopy1_md5=$(echo $listing | awk -F':' '{print $2}')
    col1=$(dirname $listing | awk -F':' '{print $1}')
    if [ "$col1" = "." ]; then
        col1="./"
    fi
    col2=$(grep $precopy1_md5 "$scriptdir/checksum.conf" | awk -F':' '{print $3}')

    menu[$index]="$col1"
    index=$((index+1))
    if [ -z "$col2" ]; then
        menu[$index]="Unknown"
    else
        menu[$index]="$col2"
    fi
    index=$((index+1))

done < precopymd5.tmp

choice=$(dialog --title 'Found Install Directories' --menu 'Select one of the operating systems found on the server, or "Other" to specify a different path.' 18 75 10 "${menu[@]}" 3>&1 1>&2 2>&3)
if [ $? != 0 ]; then
    rm precopymd5.tmp 2> /dev/null
    exit 1
fi

}

other_path() {

choice=$(dialog --title "Other Setup Directory" --inputbox "If you know the path to the setup files, type it here. The path you specify is relative to:\n\n    $ftppath/" 12 70 '' 3>&1 1>&2 2>&3 | sed 's|^|\.\/|')
if [ $? != 0 ]; then # did user hit cancel?
    rm precopymd5.tmp 2> /dev/null
    exit 2  # repeat this script from hierma.sh
fi

}

os_check() {
# Only do this unless ostype is already defined in the database.
# A user can override the found operating system type by defining it
# in said database!
if [ -z "$choice_type" ]; then
# This approach to handling MD5 checksums seems WAY more efficient than
# the one in cdinstall.sh. As HIERMA becomes more polished up to the final
# release, cdinstall.sh should be rewritten.

choice_md5=$(grep "^$choice" precopymd5.tmp | awk -F':' '{print $2}')
choice_type=$(grep "^$choice_md5:" "$scriptdir/checksum.conf" | awk -F':' '{print $2}')
if [ -z $choice_type ]; then
    # The distinguishing file was not found, or did not match up
    # with any of the known releases!
    # Display a menu for selecting an OS type manually.
    choice_type=$(dialog --title "Operating System Selection" --menu 'The operating system path you selected does not match any known or currently supported release. Please select one of the options which most closely matches your build.' 15 75 5 \
        'win95' 'Windows 95 RTM' \
        'win95b' 'Windows 95 OSR2' \
        'win98' 'Windows 98' \
        'win98se' 'Windows 98 Second Edition' \
        'winme' 'Windows ME' \
        3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then # did user hit cancel?
        rm precopymd5.tmp
        exit 2  # Repeat this script from hierma.sh
    fi
else
    "$scriptdir/hierma_setparm.sh" ostype $choice_type
    # This is constant for now, will change when DOS/Windows NT becomes
    # supported.
    "$scriptdir/hierma_setparm.sh" setupcmd SETUP.EXE
fi

fi

}

copy_remote() {

total=$(($($ftpcmd -e "ls -R $choice; bye" | wc -l)-2))

count=0
echo $choice $dest_path
$ftpcmd -e "mirror -v -e $ftppath/$choice/ $dest_path; bye" > /dev/null |
while read word word2 filename; do
if [ "$word" = "Transferring" ]; then
    count=$((count+1))
    percent=$((count*100/total))
    currentfile=$(echo $filename | tr -d \`\')
    echo "XXX"
    echo "$percent"
    echo "Copying $currentfile"
    echo "XXX"
fi
done | dialog --title "Remote Copy" --gauge "Now copying the setup files..." 6 75 0

# Extract PRECOPY cabinets, same as local.
dialog --title "Remote Copy" --infobox "Extracting PRECOPY files to temporary directory..." 3 57
mkdir "$dest_path/htemp" 2> /dev/null
find "$dest_path" -iname precopy1.cab -exec cabextract -L -q -d "$dest_path/htemp" '{}' \;
}

ftp_command
get_precopy
select_path
if [ "$choice" = "Other" ]; then
    other_path
fi

os_check
copy_remote
rm precopymd5.tmp 2> /dev/null
exit 0
