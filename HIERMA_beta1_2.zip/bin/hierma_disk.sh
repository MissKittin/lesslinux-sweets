#!/usr/bin/env bash

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
# Beta 1.2: No, I have a better idea...
#dialog --title "Partition Manager" --infobox "Waiting $sleeptime seconds to ensure victory in upcoming format" 3 70
sync

}

hierma_format() {

dialog --title "Partition Manager" --infobox "Formatting $pripart as $myparttype" 3 50
# Create the filesystem. If the first argument is -F, use FAT32.
# Beta 1.2: Repeatedly attempt mkfs.msdos until it succeeds instead of
# waiting 10 seconds. Scales better with systems of varied speeds.
if [ "$1" = "-F" ]; then
	mkfs.msdos -F 32 -I $pripart > /dev/null 2>&1
    while [ $? != 0 ]; do
        sleep 1
    	mkfs.msdos -F 32 -I $pripart > /dev/null 2>&1
    done
else
	mkfs.msdos -F 16 -I $pripart > /dev/null 2>&1
    while [ $? != 0 ]; do
        sleep 1
    	mkfs.msdos -F 16 -I $pripart > /dev/null 2>&1
    done

fi

# Tell mtools the drive is at the user's selected disk.
# $1 is empty if using FAT16, -F if using FAT32.
echo "drive c: file=\"$pripart\"" > hierma_mtools.tmp
export MTOOLSRC="hierma_mtools.tmp"
mformat $1 C:
unset MTOOLSRC
rm hierma_mtools.tmp

}

fdisk -l | grep 'Disk /dev/sd' | awk -F':' '{print $1}' | sed 's/Disk\s//;/contain a valid/d' > disklist.tmp
sed 's/\s//g' disklist.tmp > disklist2.tmp && mv disklist2.tmp disklist.tmp

fdisk -l | grep 'Disk /dev/sd' | awk -F':' '{print $2}' | sed 's/,.*//' > disksize.tmp

lineno=0
index=0
while read disk; do

    menu[$index]="$disk"
    index=$((index+1))
    lineno=$((lineno+1))
    disksize="$(sed -n "${lineno}p" disksize.tmp)"
    menu[$index]="$disksize"
    index=$((index+1))

done < disklist.tmp

mydisk=$(dialog --title "Format a Disk" --menu "Currently, HIERMA only supports creating single partitions spanning entire disks, so you'll have to format a hard disk which you intend to install your operating system to." 19 60 15 "${menu[@]}" 3>&1 1>&2 2>&3)

if [ $? = 0 ]; then
    pripart=$(echo $mydisk | sed 's/$/1/')
    myparttype=$(dialog --title "Partition Type" --menu "You have selected $mydisk\n\nPlease specify the partition type. Keep in mind that FAT16 LBA will NOT work on MS-DOS, and an LBA filesystem is required for Win95B, NT5 and onward." 14 70 3 \
    'FAT16' 'MS-DOS, NT4, Win95A' \
	'FAT16 LBA' 'Win95A, Win95B, NT5 and onward' \
	'FAT32 LBA' 'Win95B, NT5 and onward' 3>&1 1>&2 2>&3)
    if [ $? = 0 ]; then
    	dialog --title "Partition Manager" --yesno "You selected partition type $myparttype\n\nYou are about to DESTROY THE ENTIRE CONTENTS of $mydisk. If you are unsure if this is the partition you want to format, CHOOSE \"NO\" NOW.\n\nAre you SURE you want to format the partition?" 11 60
        if [ $? = 0 ]; then
        basedisk=$(basename $mydisk)

        case "$myparttype" in
        'FAT16')
            partwrite 6
            hierma_format
            ;;

        'FAT16 LBA')
            partwrite e
            hierma_format
            ;;

        'FAT32 LBA')
            partwrite c
            hierma_format -F
            ;;

        esac
        "$scriptdir/hierma_setparm.sh" mydisk "$mydisk"
        "$scriptdir/hierma_setparm.sh" dest_path "/mnt/hierma_dest/HIERMA"
        #echo "/mnt/hierma_dest" > lastdir
        # Tell setdest to use /mnt/hierma_dest automatically.
        mkdir -p /mnt/hierma_dest
        mount -t msdos "$pripart" /mnt/hierma_dest
        mkdir -p /mnt/hierma_dest/HIERMA
        rm *.tmp 2> /dev/null
        dialog --title "Partition Manager" --msgbox "The new partition has been mounted at /mnt/hierma_dest/HIERMA, and the destination path has been set to that automatically." 6 70
        exit 2

        else
            exit 1
        fi
    else
        exit 1
    fi
else
    exit 1
fi

# Beta 1.2: Don't display this dialog anymore. hierma_bootmgr.sh is
# returning.
#dialog --title "Install Boot Manager" --yesno "HIERMA can install a temporary boot manager on your hard disk which loads a minimal boot floppy to automatically execute your setup program. This boot manager will be overridden by that of your operating system's upon loading the setup program.\n\nDo you want to install a boot manager? If you choose \"No\", a batch file will be created in the setup directory, and you'll need to execute it from your own DOS floppy." 12 70

#if [ $? = 0 ]; then
#    "$scriptdir/hierma_setparm.sh" install_bootmgr 1
#else
#    "$scriptdir/hierma_setparm.sh" install_bootmgr 0
#fi
rm *.tmp 2> /dev/null
