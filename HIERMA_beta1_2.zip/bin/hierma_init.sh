#!/usr/bin/env bash
# Database selector. hierma.conf is used by default, but the user can
# override it with their own database.
db="$scriptdir/hierma.conf"

idbselect() {

while (true); do
index=0
sed "s|#.*$||g" "$db" | grep ' {' | awk '{print $1}' | grep -Ev "WORKING|MOUNT|UMOUNT|NEWDB" > sectlist.tmp
while read section; do
    menu[$index]="$section"
    index=$((index+1))
    menu[$index]="$($scriptdir/hierma_getparm.sh hierma_desc $section "$db")"
    index=$((index+1))
done < sectlist.tmp
rm sectlist.tmp

# More options for loading a different configuration file,
# as well as mounting or unmounting devices.
# NOTE: Really need to make sure the HIERMA scripts and required utilities are loaded into RAM!!!
    menu[$index]="OtherDB"
    index=$((index+1))
    menu[$index]="Select another database"
    index=$((index+1))
	if [ "$(id -un)" = "root" ]; then
    menu[$index]="Mount"
    index=$((index+1))
    menu[$index]="Mount a device"
    index=$((index+1))
    menu[$index]="Unmount"
    index=$((index+1))
    menu[$index]="Unmount a device"
    index=$((index+1))
	fi
    
mysection=$(dialog --cancel-label "Exit" --title "Starting Options" --menu "If you have an existing answer database section you want to use, you can load that and HIERMA will use it to fill in some information ahead of time, and will try to run hands-free if the option \"hierma_express=1\" is set in it. Otherwise, choose \"default\" to walk through all the preparation steps interactively." 19 78 10 "${menu[@]}" 3>&1 1>&2 2>&3)
if [ $? != 0 ]; then
    exit 1
fi

case "$mysection" in
'OtherDB')
    db="$(dialog --title 'Select Database File' --fselect ./ 12 50 3>&1 1>&2 2>&3)"
    #db="$($scriptdir/hierma_pathsel.sh LOCAL)"
    if [ -z "$db" ]; then
        db="$scriptdir/hierma.conf"
    fi
    ;;
'Mount')
    "$scriptdir/hierma_mount.sh" MOUNT
    if [ $? != 0 ]; then
        initial_choice
    fi
    ;;
'Unmount')
    "$scriptdir/hierma_mount.sh" UMOUNT
    if [ $? != 0 ]; then
        initial_choice
    fi
    ;;
    *)
        "$scriptdir/hierma_getsect.sh" "$mysection" "$db" > working.conf
        break
        ;;
esac
done

}

udbselect() {

if [ ! -z "$hsect" ] && [ -f "$hdb" ]; then
    sect_exists=$(grep "$hsect {" $hdb)
else
    missing_err=1
fi

"$scriptdir/hierma_getsect.sh" "$hsect" "$hdb" > working.conf

}

if [ -f "$hdb" ]; then
    missing_err=0
else
    missing_err=1
fi

if [ $missing_err = 0 ] && [ $DBDEFINED = 1 ]; then
    udbselect
else
    idbselect
fi

sed '1s/.*/WORKING {/g' working.conf > working2.conf && mv working2.conf working.conf
exit 0
