#!/usr/bin/env bash
dest_path="$($scriptdir/hierma_getparm.sh dest_path)"
ostype=$($scriptdir/hierma_getparm.sh ostype)
comp_path="$scriptdir/setupinf"
tmpinf=tmpinf
index=0
dialog --title "Optional Components" --infobox "Obtaining list of $ostype components..." 3 45
while read comp; do
    fullline=$(grep "^$comp" "$comp_path/all_components.conf")
    if [ ! -z "$fullline" ]; then
        col1=$(echo $fullline | awk -F'|' '{print $1}' | sed 's/\%//')
        menu[$index]="$col1"
        index=$((index+1))
        #col2=$(echo $fullline | awk -F'|' '{print $2}')
        #menu[$index]="$col2"
        menu[$index]=""
        index=$((index+1))
        # TODO: This colum should reflect the database config.
        checked=$(echo $fullline | awk -F'|' '{print $3}')
        menu[$index]="$checked"
        index=$((index+1))
    fi
done < "$comp_path/$ostype.conf"

dialog --separate-output --title "Optional Components" --cancel-label "Back" --checklist 'Select all of the built-in software components you wish to have installed.\nHINT: In checklists like these, the space bar is used to toggle an item.' 22 50 12 "${menu[@]}" 2> comp.tmp
exitstatus=$?

# TODO: Create functionality to add the components
# to the configuration database.
if [ $exitstatus = 0 ]; then
    dialog --title "Optional Components" --infobox "Assigning new component settings..." 3 40

    # First set all components to 0 so as to avoid installing any
    # due to default settings in a component set.
    sed 's/$/"=0/g;s/^/"/g' "$comp_path/$ostype.conf" > comp2.tmp

    # Now, components the user wants to install are set to 1 in MSBATCH.INF.
    while read comp; do
        sed "s/\"$comp\"=0/\"$comp\"=1/" comp2.tmp > comp3.tmp && mv comp3.tmp comp2.tmp
    done < comp.tmp
    rm comp.tmp 2> /dev/null

    # Beta 1.1a: Optimized so all put operations take place in a single command.
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s OptionalComponents -l comp2.tmp -p
    rm comp2.tmp 2> /dev/null
else
    exit 1
fi

exit 0
