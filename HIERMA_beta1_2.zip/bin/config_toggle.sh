#!/usr/bin/env bash
onoff() {
    binvar="$($scriptdir/hierma_getparm.sh $1)"
    if [ "$binvar" = "1" ]; then
        echo "ON"
    else
        echo "OFF"
    fi
}

dialog --title "More Options" --separate-output --checklist 'Here, you can toggle more setup options which only have on/off settings.' 14 75 6 \
    'NoProductKey' 'Do not prompt for a product key (Win95 only)' "$(onoff noproductkey)" \
    'Express' 'Do not ask for user input unless required' "$(onoff express)" \
    'EBD' 'Create a startup floppy during setup' "$(onoff ebd)" \
    'PenWinWarning' 'Display warning if unknown Pen Windows installed' "$(onoff penwinwarning)" \
    'VRC' 'Automatically overwrite files without prompting' "$(onoff vrc)" \
    'DevicePath' 'Always search for new driver INFs in the setup path' "$(onoff devicepath)" 2> moreopt.tmp

if [ $? = 0 ]; then
    sed 's/\"//g' moreopt.tmp | tr '[:upper:]' '[:lower:]' > moreopt2.tmp && mv moreopt2.tmp moreopt.tmp
    
    # Reset the toggle values. Might need a better way to do this.
    "$scriptdir/hierma_setparm.sh" noproductkey 0
    "$scriptdir/hierma_setparm.sh" express 0
    "$scriptdir/hierma_setparm.sh" ebd 0
    "$scriptdir/hierma_setparm.sh" penwinwarning 0
    "$scriptdir/hierma_setparm.sh" vrc 0
    "$scriptdir/hierma_setparm.sh" devicepath 0

    while read option; do
        "$scriptdir/hierma_setparm.sh" $option 1
    done < moreopt.tmp
fi

rm moreopt.tmp
