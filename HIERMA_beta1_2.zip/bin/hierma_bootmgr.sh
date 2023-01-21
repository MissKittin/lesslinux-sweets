#!/usr/bin/env bash
mydisk="$($scriptdir/hierma_getparm.sh mydisk)"
mypart="$($scriptdir/hierma_getparm.sh mypart)"
dest_path="$($scriptdir/hierma_getparm.sh dest_path)"
basepart="$(basename $mydisk)1"
bootdisks="bootdisks"   # default boot image path
devdet2="$($scriptdir/hierma_getparm.sh devdet)"

# Get a more flexible solution for this later.
#mntroot="/mnt/hierma_$basepart"
mntroot="/mnt/hierma_dest"
noboot=1

ftp_command() {
# Return the appropriate lftp command to stdout, depending on what
# credentials were specified.

if [ -z $ftpuser ]; then
    ftpcmd="lftp ${ftpserver}${bootdisks}"
elif [ -z $ftppass ]; then
    ftpcmd="lftp -u $ftpuser ${ftpserver}${bootdisks}"
else
    ftpcmd="lftp -u $ftpuser,"$ftppass" ${ftpserver}${bootdisks}"
fi

}

sysl_cmd() {
    # Remnant of attempting to use SYSLINUX 6.03 on an outdated Core Linux
    # before switching to 10.1.
    if [ "$entry_opt" = "BOOTENV" ] || [ "$entry_opt" = "UBOOTENV" ]; then
        syslcmd="/opt/syslinux/syslinux"
    else
        syslcmd="syslinux"
    fi
}

clean_exit() {
umount /mnt/hierma_fd
rmdir /mnt/hierma_fd 2> /dev/null
exit 0
}

autoexec_cmds() {
cp /mnt/hierma_fd/AUTOEXEC.BAT ./ 2> /dev/null
dos2unix AUTOEXEC.BAT 2> /dev/null
echo "A:\FDISK.EXE /MBR" >> AUTOEXEC.BAT
echo "A:\SYS.COM c:" >> AUTOEXEC.BAT
echo "C:\\HIERMA\\$setupcmd $switches $devdet" >> AUTOEXEC.BAT
unix2dos AUTOEXEC.BAT 2> /dev/null
mv AUTOEXEC.BAT /mnt/hierma_fd/ 2> /dev/null
}

# Beta 1.2: Moved to this script.
# Apply the correct power management switch.
power="$("$scriptdir/hierma_getparm.sh" power)"
if [ "$power" = "ACPI" ]; then
    if [ "$devdet2" ]; then
        devdet="$devdet2;j"
    else
        devdet="/p j"
    fi
elif [ "$power" = "No APM" ] || [ "$power" = "APM" ]; then
    if [ "$devdet2" ]; then
        devdet="$devdet2;i"
    else
        devdet="/p i"
    fi
else
    devdet="$devdet2"
fi
unset devdet2

mkdir /mnt/hierma_fd 2> /dev/null

create_batch() {
    dialog --title "Creating Batch File" --infobox "Please wait while the batch file is being created." 3 55
    batch_path="$mntroot"
    switches="$($scriptdir/hierma_getparm.sh switches)"
    setupcmd="$($scriptdir/hierma_getparm.sh setupcmd)"
    if [ $noboot = 1 ]; then
        batch_path="$dest_path"
        cp "$scriptdir/hierma.bat" ./
        cp "$scriptdir/CHOICE.EXE" "$dest_path/"
        cp "$scriptdir/FDISK.EXE" "$dest_path/"
        cp "$scriptdir/SYS.COM" "$dest_path/"

        sed "s|<REPLACE>|$setupcmd $switches $devdet|g" hierma.bat > "$dest_path/hierma.bat"
        rm hierma.bat
        if [ $EXPRESS != 1 ]; then
            dialog --title "Batch File" --msgbox "A batch file has been created at\n\n   $batch_path/HIERMA.BAT\n\nYou can run this from within DOS or Windows to execute Setup using the settings you've supplied." 10 75
        fi
    else
        dospath="$(echo $dest_path | sed "s|^$mypart||;s|^/||;s|/$||" | sed 's:\\:\\\\:g')"
        mount -o loop "$mntroot/boot/syslinux/boot.img" /mnt/hierma_fd
        
        if [ $boot_choice = "Default" ]; then
            delconfig=1
            autoexec_cmds
        elif [ -f /mnt/hierma_fd/CONFIG.SYS ] || [ -f /mnt/hierma_fd/AUTOEXEC.BAT ]; then
            dialog --title "Remove Existing Configuration?" --yesno "Since the setup files are located on hard disk, you shouldn't need to load any drivers or TSRs. HIERMA can either remove the configuration files on the destination floppy image for you, or leave them intact and append the setup command to the bottom of AUTOEXEC.BAT.\n\nDo you want to remove the configuration files? (This will not affect the source image or disk you copied from.)" 12 78
            delconfig=$?
        else
            delconfig=0
        fi
        if [ $delconfig = 0 ]; then
            rm /mnt/hierma_fd/CONFIG.SYS /mnt/hierma_fd/FDCONFIG.SYS /mnt/hierma_fd/AUTOEXEC.BAT 2> /dev/null
            # Determining the DRIVE LETTERS of each partition is surely
            # going to be one hell of a nightmare in Linux...
            # Might have to ask the user for them.
            autoexec_cmds
        else
            autoexec_cmds
        fi
        umount /mnt/hierma_fd 2> /dev/null
        
    fi
}

bootmgr_install() {
    # SYSLINUX shared paths vary across whatever.
    if [ -f /usr/lib/syslinux/mbr/mbr.bin ]; then
        mbr_path=/usr/lib/syslinux/mbr/mbr.bin
    else
        mbr_path=/usr/local/share/syslinux/mbr.bin
    fi
    if [ -f /usr/lib/syslinux/memdisk ]; then
        memdisk_path=/usr/lib/syslinux/memdisk
    else
        memdisk_path=/usr/local/share/syslinux/memdisk
    fi

    dialog --title "Confirm Installing Boot Manager" --yesno "You are about to install the boot manager on drive $mydisk\n\nThis will overwrite any existing boot manager you may have on the disk. Do you want to proceed?" 9 65
    if [ $? = 0 ]; then
        cp "$memdisk_path" "$mntroot/boot/syslinux"
        cp "$scriptdir/syslinux.cfg" "$mntroot/boot/syslinux/"
        umount "$mntroot"
        printf '\1' | cat "$mbr_path" | dd of="$mydisk" bs=440 count=1 iflag=fullblock conv=notrunc 2> /dev/null
        if [ "$entry_opt" = "BOOTENV" ]; then
            chmod 1777 /tmp
        fi
        syslinux -d /boot/syslinux -i "${mydisk}1"

        mount -t msdos "${mydisk}1" "$mntroot"
        
    fi
}

if [ "$(id -un)" != "root" ]; then
    # Only create the batch file in the destination path.
    noboot=1
    create_batch
    exit 0
fi

while (true); do
boot_choice=$(dialog --title "Install Boot Manager" --menu "You can install a temporary boot manager that loads a minimal DOS environment to execute your setup program quickly. HIERMA includes a tiny FreeDOS boot image called fdboot.img, but you can also supply your own DOS boot floppy if desired.\n\nIf you do not want to install a boot manager, a batch script called HIERMA.BAT will be placed in destination path for you to run Setup with the settings you've assigned." 18 78 4 \
    'Default' 'Use the default boot image for the temporary boot manager' \
    'Image' 'Use another floppy image for the temporary boot manager' \
    'Disk' 'Supply a physical floppy for the temporary boot manager' \
    'None' 'Do not install a boot manager' 3>&1 1>&2 2>&3)
if [ $? = 0 ]; then

case $boot_choice in
    'Default')
        noboot=0    # Yes, install a boot manager
        # Basically the same as "Image", but chooses the included FreeDOS
        # boot floppy straight away.
        mkdir -p "$mntroot/boot/syslinux"
        gunzip -c "$scriptdir/fdboot.imz" > "$mntroot/boot/syslinux/boot.img"
        create_batch
        bootmgr_install
        clean_exit
        ;;
    'Image')
        noboot=0
        imgsrc=$(dialog --title "Boot Image Source" --menu "Choose where the boot images are located." 9 60 2 \
            'Local' 'Get boot images from local source' \
            'FTP' 'Get boot images from remote source' 3>&1 1>&2 2>&3)
        if [ $? = 0 ]; then
            case "$imgsrc" in
            'Local')
                "$scriptdir/hierma_pathsel.sh" LOCAL bootdisks
                pathexit=$?
                ;;
            'FTP')
                "$scriptdir/hierma_pathsel.sh" FTP bootdisks ftpdisksrv ftpdiskuser ftpdiskpass
                pathexit=$?
                ;;
            esac
            if [ $pathexit = 0 ]; then
                ftpserver="$($scriptdir/hierma_getparm.sh ftpdisksrv)"
                ftpuser="$($scriptdir/hierma_getparm.sh ftpdiskuser)"
                ftppass="$($scriptdir/hierma_getparm.sh ftpdiskpass)"
                index=0
                bootdisks="$($scriptdir/hierma_getparm.sh bootdisks)"
                ftp_command
                if [ "$imgsrc" = "FTP" ]; then
                    $ftpcmd -e "find; bye" > bootdisks.tmp
                    grep -iE "(.img$|.imz$)" bootdisks.tmp > bootdisks2.tmp && mv bootdisks2.tmp bootdisks.tmp
                else
                    find "$bootdisks" \( -iname "*.img" -o -iname "*.ima" -o -iname "*.imz" \) > bootdisks.tmp
                fi
                if [ ! -s bootdisks.tmp ]; then
                    export DIALOGRC="$scriptdir/derror"
                    dialog --title "ERROR: No Boot Images Found" --msgbox "No boot images were found in the path specified. Either try a different path, or choose \"None\" to skip this process."
                    unset DIALOGRC
                else
                while read bdisk; do
                    # Check the COMMAND.COM in every image.
                    if [ "$imgsrc" = "FTP" ]; then
                        $ftpcmd -e "get $bdisk; bye" 2> /dev/null
                        basedisk="$(basename $bdisk)"
                        mount -o loop "$basedisk" /mnt/hierma_fd
                        md5="$(md5sum /mnt/hierma_fd/COMMAND.COM | awk '{print $1}')"
                        umount /mnt/hierma_fd
                        rm "$basedisk"
                        unset basedisk
                    else
                        mount -o loop "$bdisk" /mnt/hierma_fd
                        md5="$(md5sum /mnt/hierma_fd/COMMAND.COM | awk '{print $1}')"
                        umount /mnt/hierma_fd
                    fi

                    md5desc="$(grep ^$md5 checksum.conf | awk -F':' '{print $3}')"

                    col1=$(echo $bdisk | sed "s|^$bootdisks||Ig;s|^/||")
                    menu[$index]="$col1"
                    index=$((index+1))

                    if [ -z "$md5desc" ]; then
                        menu[$index]="Unknown"
                    else
                        menu[$index]="$md5desc"
                    fi
                    index=$((index+1))
                done < bootdisks.tmp
                fimage=$(dialog --title "Select Boot Image" --menu "HIERMA has found one or more boot disks in the specified path." 23 78 19 "${menu[@]}" 3>&1 1>&2 2>&3)
                if [ $? = 0 ]; then
                    mkdir -p "$mntroot/boot/syslinux"
                    newimage="$(grep "$fimage$" bootdisks.tmp)"
                    fext="$(echo $fimage | awk -F'.' '{print tolower($NF)}')"
                    if [ "$fext" = "imz" ]; then
                        # The floppy image must be decompressed.
                        if [ "$imgsrc" = "FTP" ]; then
                            baseimg="$(basename $newimage)"
                            $ftpcmd -e "get $newimage; bye" 2> /dev/null
                            gunzip -c "$baseimage" > "$mntroot/boot/syslinux/boot.img"
                            rm "$baseimage"
                        else
                            gunzip -c "$newimage" > "$mntroot/boot/syslinux/boot.img"
                        fi
                    else
                        if [ "$imgsrc" = "FTP" ]; then
                            $ftpcmd -e "get $newimage -o $mntroot/boot/syslinux/boot.img; bye" 2> /dev/null
                        else
                            cp "$newimage" "$mntroot/boot/syslinux/boot.img"
                        fi
                    fi
                    create_batch
                    bootmgr_install
                    clean_exit
                fi
                rm bootdisks.tmp
                fi
                unset menu
            fi
        fi
        
        ;;
    'Disk')
        noboot=0
        fdrive=$(dialog --title "Boot Manager from Diskette" --menu "Insert your DOS boot disk into the appropriate drive, then select it from the menu. Any standard floppy size is acceptable." 11 50 2 \
            '/dev/fd0' 'Drive A:' \
            '/dev/fd1' 'Drive B:' 3>&1 1>&2 2>&3)
        if [ $? = 0 ]; then
            mkdir -p "$mntroot/boot/syslinux"
            case $fdrive in
                '/dev/fd0') letter=A ;;
                '/dev/fd1') letter=B ;;
            esac
            (pv -n $fdrive | dd of="$mntroot/boot/syslinux/boot.img") 2>&1 | dialog --title "Boot Manager from Diskette" --gauge "Copying disk in drive $letter: to image $mntroot/boot/syslinux/boot.img" 7 75 0
            dialog --title "Boot Manager from Diskette" --msgbox "The boot disk was successfully copied to a temporary image which will be modified accordingly. You can now remove the disk from the $letter: drive." 7 60
            fimage="boot.img"
            create_batch
            bootmgr_install
            clean_exit
        fi
        ;;
    'None')
        noboot=1
        create_batch
        ;;
esac
else
    exit 1
fi
done
rmdir /mnt/hierma_fd 2> /dev/null
