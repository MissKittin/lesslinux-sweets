#!/usr/bin/env bash
# Copy Windows 9x drivers.
# Fun fact: This script was rewritten largely from scratch following an
# accidental deletion of all the script files for beta 1.2. This one should
# be less prone to breaking itself from any future updates, I hope.

dest_path="$($scriptdir/hierma_getparm.sh dest_path)"
ostype=$("$scriptdir/hierma_getparm.sh" ostype | tr '[:upper:]' '[:lower:]')

# Hide mount/unmount options for non-root users.
while (true); do
if [ "$(id -un)" = "root" ]; then
dcopy_choice=$(dialog --title "Driver Source" --cancel-label "Back" --menu "If you have a collection of drivers handy, HIERMA will search the entire path you specify. This only works with extracted drivers that have accompanying INF files; self-contained executable driver installers will not be loaded." 15 70 5 \
    'Local' 'Load drivers from a local source' \
    'FTP' 'Load drivers from an FTP source' \
    'Mount' 'Mount a device' \
    'Unmount' 'Unmount a device' \
    'Skip' 'Skip driver copying' 3>&1 1>&2 2>&3)
else
dcopy_choice=$(dialog --title "Driver Source" --menu "If you have a collection of drivers handy, HIERMA will search the entire path you specify. This only works with extracted drivers that have accompanying INF files; self-contained executable driver installers will not be loaded." 13 70 13 \
    'Local' 'Load drivers from a local source' \
    'FTP' 'Load drivers from an FTP source' \
    'Skip' 'Skip driver copying' 3>&1 1>&2 2>&3)
fi

if [ $? = 0 ]; then
    case $dcopy_choice in
        'Local')
            "$scriptdir/hierma_pathsel.sh" LOCAL driver_path
            if [ $? = 0 ]; then
                drvsrc="local"
                driver_path="$($scriptdir/hierma_getparm.sh driver_path)"
                break
            fi
            ;;
        'FTP')
            "$scriptdir/hierma_pathsel.sh" FTP driver_path ftpserver_drv ftpuser_drv ftppass_drv
            if [ $? = 0 ]; then
                drvsrc="ftp"
                driver_path="$($scriptdir/hierma_getparm.sh driver_path)"
                ftpserver="$("$scriptdir/hierma_getparm.sh" ftpserver_drv)"
                ftpuser="$("$scriptdir/hierma_getparm.sh" ftpuser_drv)"
                ftppass="$("$scriptdir/hierma_getparm.sh" ftppass_drv)"
                break
            fi
            ;;
        'Mount') "$scriptdir/hierma_mount.sh" MOUNT ;;
        'Unmount') "$scriptdir/hierma_mount.sh" UMOUNT ;;
        'Skip') exit ;;
    esac
else
    rm inftmp *.tmp longfile.err 2> /dev/null
    exit 1
fi
done

ftp_command() {
# Return the appropriate lftp command to stdout, depending on what
# credentials were specified.

if [ -z $ftpuser ]; then
    ftpcmd="lftp ${ftpserver}${driver_path}"
elif [ -z $ftppass ]; then
    ftpcmd="lftp -u $ftpuser ${ftpserver}${driver_path}"
else
    ftpcmd="lftp -u $ftpuser,"$ftppass" ${ftpserver}${driver_path}"
fi

}

gauge_update() {
    # Update the progress bar.
    count=$((count+1))
    percent=$((count*100/total))
    echo "XXX"
    echo "$percent"
    echo "Copying drivers for $baseinf"
    echo "XXX"
}

os_exclude() {

grep -iv "$ostype" "$scriptdir/setupinf/os.conf" > exclude.tmp
while read os; do
    if [ $drvsrc = "ftp" ]; then
        grep -iv "^./$os/" hierma_inflist.tmp > hierma_inflist2.tmp && mv hierma_inflist2.tmp hierma_inflist.tmp
    else
        grep -iv "^$driver_path/$os/" hierma_inflist.tmp > hierma_inflist2.tmp && mv hierma_inflist2.tmp hierma_inflist.tmp
    fi
done < exclude.tmp

grep -iv "oemsetup.inf$" hierma_inflist.tmp > hierma_inflist2.tmp && mv hierma_inflist2.tmp hierma_inflist.tmp
grep -iv "msbatch.inf$" hierma_inflist.tmp > hierma_inflist2.tmp && mv hierma_inflist2.tmp hierma_inflist.tmp
grep -iv "custom.inf$" hierma_inflist.tmp > hierma_inflist2.tmp && mv hierma_inflist2.tmp hierma_inflist.tmp

}

dialog --title "Driver Copying" --infobox "Please wait while the driver INF list is assembled." 3 56

create_db() {

touch inftrack.tmp

while read inf; do
    baseinf=$(basename $inf)
    if [ $drvsrc = "ftp" ]; then
        $ftpcmd -e "get $inf; bye" > /dev/null
        "$scriptdir/hierma_infsect.sh" -f "$baseinf" -s Strings -g HIERMA_DESC -g HIERMA_OSTYPE > drvdesc.tmp
        rm $baseinf 2> /dev/null
    else
        "$scriptdir/hierma_infsect.sh" -f "$inf" -s Strings -g HIERMA_DESC -g HIERMA_OSTYPE > drvdesc.tmp
    fi
    desc="$(sed -n '1p' drvdesc.tmp)"
    drvos="$(sed -n 's/ //g;2p' drvdesc.tmp)"
    if [ -z "$drvos" ]; then
        allos=1
    else
        allos=0
    fi
    rm drvdesc.tmp 2> /dev/null

    # Beta 1.2 introduces a new string specifically for use by this program,
    # HIERMA_OSTYPE. This string can be used to exclude certain operating
    # systems from using an INF while sharing the same set of files.
    if [ "$allos" != 1 ]; then
        osmatch="$(echo "$drvos" | grep "^$ostype,")"
        if [ -z "$osmatch" ]; then
            # Keep trying for different character combinations...
            # Might want to externalize this procedure.
            osmatch="$(echo "$drvos" | grep ",$ostype,")"
        fi
        if [ -z "$osmatch" ]; then
            osmatch="$(echo "$drvos" | grep ",$ostype$")"
        fi
        if [ -z "$osmatch" ]; then
            osmatch="$(echo "$drvos" | grep "^$ostype$")"
        fi
    else
        osmatch="YesYouCanInstallThisOkayThankYou"
    fi

    # Keep track of INF names in a list so the script can be sure it's
    # copying the exact one the user selects.
    if [ "$osmatch" ]; then
        if [ "$(grep -i :$baseinf$ inftrack.tmp)" ]; then
            count=$(grep -i :$baseinf$ inftrack.tmp | wc -l)
            echo "$inf:$baseinf ($count):$desc" >> infdb.tmp
        else
            echo "$inf:$baseinf:$desc" >> infdb.tmp
        fi
    fi
    unset drvos osmatch allos
done < hierma_inflist.tmp

}

dialog_menu() {

# Drivers can be selected by default in the configuration database.
# This is more useful for unattended installations.
"$scriptdir/hierma_getparm.sh" drivers | sed 's/;/\n/g' > infsel.tmp

index=0
while read inf; do
    col1="$(echo $inf | awk -F':' '{print $2}')" # User-selectable name
    col2="$(echo $inf | awk -F':' '{print $3}' | sed 's/\"//g')" # HIERMA_DESC

    menu[$index]="$col1"
    index=$((index+1))
    menu[$index]="$col2"
    index=$((index+1))

    infsel="$(grep "^$baseinf" infsel.tmp)"
    if [ -s infsel.tmp ] && [ -z "$infsel" ]; then
        # If the drivers field in the database exists and the filename
        # was not found, the driver is toggled OFF by default.
        menu[$index]="OFF"
    else
        menu[$index]="ON"
    fi
    index=$((index+1))
done < infdb.tmp

# Prompt user to select which drivers to copy.
dialog --title "Driver Copying" --separate-output --checklist "Here, you can either copy all of the drivers or select only the ones you know you'll need." 0 75 0 "${menu[@]}" 2> infsel.tmp
if [ $? != 0 ]; then
    # User hit Cancel. Go back to driver source dialog!
    rm inftmp *.tmp longfile.err 2> /dev/null
    exit 3
fi

}

local_list() {

find "$driver_path" -iname "*.inf" > hierma_inflist.tmp
os_exclude
create_db
dialog_menu

}

remote_list() {

$ftpcmd -e "find; bye" > hierma_inflist.tmp
grep -i ".inf$" hierma_inflist.tmp > hierma_inflist2.tmp && mv hierma_inflist2.tmp hierma_inflist.tmp
os_exclude
create_db
dialog_menu

}

if [ $drvsrc = "ftp" ]; then
    ftp_command
    remote_list
else
    local_list
fi

msbatch_append() {

drvinf="$1"
setupclass="$($scriptdir/hierma_infsect.sh -f "$dest_path/$drvinf" -s Version -g SetupClass | tr '[:upper:]' '[:lower:]')"
if [ -z "$setupclass" ]; then
    # Some files may use Class instead of SetupClass for defining
    # the driver class. If SetupClass returns nothing, use Class.
    setupclass="$($scriptdir/hierma_infsect.sh -f "$dest_path/$drvinf" -s Version -g Class | tr '[:upper:]' '[:lower:]')"
    # In either case, continue the function normally.
fi

# Sometimes, the field may have whitespace...
setupclass="$(echo $setupclass | sed 's/\s//g')"

if [ "$setupclass" = "base" ] || [ "$setupclass" = "display" ]; then
# If SetupClass is BASE or DISPLAY, the INF file should be added
# to a CopyFiles section in MSBATCH.INF.
#
# For base drivers such as chipset INFs, this will make certain the
# chipset drivers are installed before anything else to ensure maximum
# reliability in detecting other devices.
#
# For display drivers, this will allow a registry trick in Windows 95
# to work where a defined high color/resolution setting will be
# applied on the second boot with any non-default driver.

# Could multiple section edits be done in one execution
# to speed up the process?
"$scriptdir/hierma_infsect.sh" -f msbatch.inf -s SourceDisksFiles -p "$drvinf=101"
"$scriptdir/hierma_infsect.sh" -f msbatch.inf -s HIERMA.DriverInf -p "$drvinf"
fi

}

infcopy() {
lfncount=0

while read infsel; do
    inf="$(grep :$infsel: infdb.tmp | awk -F':' '{print $1}')"
    baseinf="$(basename $inf)"
    inf_nameonly="${baseinf%.*}"
    inf_charcount="$(echo $inf_nameonly | wc -c)"
    subdir="$(dirname $inf)"

    if [ $inf_charcount -gt 9 ]; then
        newinf="lfn$lfncount.inf"
        if [ $drvsrc = "ftp" ]; then
            $ftpcmd -e "get $inf; bye" > /dev/null
            mv "$baseinf" "$dest_path/$newinf"
            echo "$inf -> $newinf" >> longfile.err
        else
            cp "$inf" "$dest_path/$newinf"
        fi
        msbatch_append "$newinf"
    # Get total of driver files.
    "$scriptdir/hierma_infsect.sh" -f "$dest_path/$newinf" -t SourceDisksFiles >> total.tmp
    else
        if [ $drvsrc = "ftp" ]; then
            $ftpcmd -e "get $inf -o $dest_path/; bye" > /dev/null
        else
            cp "$inf" "$dest_path/"
        fi
        msbatch_append "$baseinf"
    "$scriptdir/hierma_infsect.sh" -f "$dest_path/$baseinf" -t SourceDisksFiles >> total.tmp
    echo "$baseinf" >> total.tmp
    fi

done < infsel.tmp

total=$(cat total.tmp | wc -l)
rm total.tmp 2> /dev/null

}

dupe_rename() {

# Inevitably, some numbers will be skipped with this
# approach. Doesn't matter, don't question me.
dup_ext=$(find "$dest_path" -iname "$drvname.*" | wc -l)
mv "$driverfile" "$dest_path/$drvname.$dup_ext"

# Modify the SourceDisksFiles entry pertaining to the
# driver's INF file.
#"$scriptdir/hierma_infsect.sh" -f "$exactinf" -s SourceDisksFiles -d "$srcdrv" -p "$drvname.$dup_ext=$diskno"
echo "$srcdrv" >> deldrv.tmp
echo "$drvname.$dup_ext=$diskno" >> putdrv.tmp

# Go through each CopyFiles section the driver may use
# and update filenames accordingly.
while read cf; do
    # The safe way: get the contents of the CopyFiles section
    # and check the filename for flags.
    "$scriptdir/hierma_infsect.sh" -f "$exactinf" -t "$cf" | sed 's/ //g' > "$cf.tmp"
    orgname="$(grep -i ^$driverfile$ $cf.tmp | sed 's/ //g')"
    if [ -z "$orgname" ]; then
        #"$scriptdir/hierma_infsect.sh" -f "$exactinf" -s "$cf" -e "$srcdrv," -p "$driverfile,$drvname.$dup_ext"
        echo "$srcdrv," >> "dellead_$cf.tmp"
    else
        #"$scriptdir/hierma_infsect.sh" -f "$exactinf" -s "$cf" -d "$srcdrv" -p "$driverfile,$drvname.$dup_ext"
        echo "$srcdrv" >> "deldrv_$cf.tmp"
    fi
    echo "$driverfile,$drvname.$dup_ext" >> "putdrv_$cf.tmp"
done < "copyfiles_$baseinf.tmp"

}

file_iteration() {

# Whitespace is erased in the CopyFiles lists. If a driver is poorly
# designed enough to have spaces in its section names, this procedure
# will fail.
"$scriptdir/hierma_infsect.sh" -f "$exactinf" -s HIERMA_ALL -g CopyFiles | awk -F':' '{print $2}' | sed 's/ //g;s/,/\n/g' | sort -f | uniq -i > "copyfiles_$baseinf.tmp"

if [ $drvsrc = "ftp" ]; then
    $ftpcmd -e "find $subdir; bye" > "drvdb_$baseinf.tmp"
else
    find "$subdir" > "drvdb_$baseinf.tmp"
fi

while read drv; do
    # The casing needs to be matched with the source file.
    srcdrv=$(echo $drv | awk -F'=' '{print $1}')
    fulldrv="$subdir/$srcdrv"
    driverfile="$(basename $(grep -i "$srcdrv$" "drvdb_$baseinf.tmp") 2> /dev/null)"
    if [ -z "$driverfile" ]; then
        # May be a compressed file with a trailing underscore.
        dr2="$(echo $srcdrv | sed 's/\([a-zA-Z0-9]\)\s*$/_/')"
        driverfile="$(basename $(grep -i "$dr2$" "drvdb_$baseinf.tmp") 2> /dev/null)"
    fi
    diskno=$(echo $drv | awk -F'=' '{print $2}')
    drvext="${driverfile##*.}"
    drvname="${driverfile%.*}"
    # Redeclare fulldrv with proper casing.
    fulldrv="$subdir/$driverfile"
    
    # When checking for duplicates, make sure the file is not an INF
    # to avoid creating unneeded duplicates.
    driver_isinf=$(awk -v s1="$drvext" -v s2="inf" 'BEGIN {
        if ( tolower(s1) == s2 ){
            print "YES"
        }
    }')

    if [ -f "$dest_path/$driverfile" ] && [ "$driver_isinf" != "YES" ]; then
        if [ $drvsrc = "ftp" ]; then
            $ftpcmd -e "get $fulldrv; bye" > /dev/null 2>&1
        else
            cp "$fulldrv" ./
        fi
        # Check if the files are actually different.
        current_md5=$(md5sum "$driverfile" | awk '{print $1}')
        existing_md5=$(md5sum "$dest_path/$driverfile" | awk '{print $1}')

        if [ "$current_md5" != "$existing_md5" ]; then
            dupe_rename
        else
            # If files match exactly, don't copy this one at all.
            rm "$driverfile"
        fi
    else
        # No duplicate, copy the file normally.
        if [ $drvsrc = "ftp" ]; then
            $ftpcmd -e "get $fulldrv -o "$dest_path/"; bye" > /dev/null 2>&1
        else
            cp "$fulldrv" "$dest_path/"
        fi
    fi

        gauge_update
done < "hierma_$baseinf.tmp"
# Now, apply modifications to the driver INF after recording all
# files that needed to be renamed.
if [ -f deldrv.tmp ]; then
    "$scriptdir/hierma_infsect.sh" -f "$exactinf" -s SourceDisksFiles -l deldrv.tmp -d -l putdrv.tmp -p
    rm deldrv.tmp putdrv.tmp 2> /dev/null
    while read cf; do
        "$scriptdir/hierma_infsect.sh" -f "$exactinf" -s "$cf" -l "dellead_$cf.tmp" -e -l "deldrv_$cf.tmp" -d -l "putdrv_$cf.tmp" -p 2> /dev/null
    done < "copyfiles_$baseinf.tmp"
    rm dellead_*.tmp deldrv_*.tmp putdrv_*.tmp 2> /dev/null
fi
# Keep tidy while in the loop! We're very tight on memory!!!
rm "hierma_$baseinf.tmp" "copyfiles_$baseinf.tmp" "drvdb_$baseinf.tmp"


}

copy_drivers() {

while read infsel; do
    inf="$(grep :$infsel: infdb.tmp | awk -F':' '{print $1}')"
    baseinf="$(basename $inf)"
    longfile="$(grep "^$inf " longfile.err 2> /dev/null | awk '{print $3}')"
    subdir="$(dirname $inf)"

    if [ "$longfile" ]; then
        exactinf="$dest_path/$longfile"
    else
        exactinf="$dest_path/$baseinf"
    fi

    "$scriptdir/hierma_infsect.sh" -f "$exactinf" -t SourceDisksFiles | sed 's/\s//g' > "hierma_$baseinf.tmp"

    # For Windows 98/ME only, copy catalog files for WDM-compliant drivers.
    if [ "$ostype" != "win95" ] && [ "$ostype" != "win95b" ]; then
        catalog="$("$scriptdir/hierma_infsect.sh" -f "$exactinf" -s Version -g CatalogFile)"
        if [ "$catalog" ]; then
            echo "$catalog" >> "hierma_$baseinf.tmp"
        fi
    else
        "$scriptdir/hierma_infsect.sh" -f "exactinf" -s Version -d CatalogFile
    fi
    # If empty, don't bother with any of the additional overhead of trying
    # to copy driver files (particularly important with chipset INFs).
    if [ -s "hierma_$baseinf.tmp" ]; then
        file_iteration
    else
        rm "hierma_$baseinf.tmp" 2> /dev/null
        gauge_update
    fi

done < infsel.tmp | dialog --title "Driver Copying" --gauge "Now copying the drivers..." 7 75

}

dialog --title "Driver Copying" --infobox "Please wait, assembling the file lists..." 3 45
infcopy
copy_drivers


# clean up
rm inftmp *.tmp 2> /dev/null

if [ -f longfile.err ] && [ "$EXPRESS" != 1 ]; then

    #export DIALOGRC="$scriptdir/derror"
    dialog --title 'NOTE: Long INF Filenames Found' --msgbox "Your drivers have been copied, but some INFs have been renamed because their names don't conform to the 8.3 character limit SETUPX.DLL requires.\n\nSince the destination INF names have been shortened, any drivers using them should install, but you may want to take note of the list of renamed INFs in the upcoming dialog." 11 70
    dialog --title 'NOTE: Long INF Filenames Found' --exit-label "OK" --textbox longfile.err 0 0
    rm longfile.err 2> /dev/null
fi
