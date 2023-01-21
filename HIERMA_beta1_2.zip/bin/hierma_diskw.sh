#!/usr/bin/env bash
# This script handles the actual partition writing and is called from
# other scripts.

partwrite() {
sleeptime=10
# Execute this routine ONLY if repartitioning the entire disk.
dialog --title "Partition Manager" --infobox "Creating partition $pripart" 3 50
if [ "$myparttype" = "FAT16" ] || [ "$myparttype" = "FAT16 LBA" ]; then
	sizelimit='+2G'
	chs='-C 1024 -H 64 -S 63'
else
	sizelimit=''
	chs=' '
fi
# Overwrite the MBR.
dd if=/dev/zero of=$mydisk bs=512 count=1 2> /dev/null
# Commence destruction of the hard disk!
echo "n
p
1

$sizelimit

t
$1
a
1
w" | fdisk $chs $mydisk > /dev/null

# Account for very slow systems.
dialog --title "Partition Manager" --infobox "Waiting $sleeptime seconds to ensure victory in upcoming format" 3 70
sync; sleep $sleeptime

}

hierma_format() {

dialog --title "Partition Manager" --infobox "Formatting $pripart as $myparttype" 3 50
# Create the filesystem. If the first argument is -F, use FAT32.
if [ "$1" = "-F" ]; then
	mkfs.msdos -F 32 -I $pripart > /dev/null
else
	mkfs.msdos -F 16 -I $pripart > /dev/null
fi

# Tell mtools the drive is at the user's selected disk.
# $1 is empty if using FAT16, -F if using FAT32.
echo "drive c: file=\"$pripart\"" > hierma_mtools.tmp
export MTOOLSRC="hierma_mtools.tmp"
mformat $1 C:
unset MTOOLSRC
rm hierma_mtools.tmp

}
