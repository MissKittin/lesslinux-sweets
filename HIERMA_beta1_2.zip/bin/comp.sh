#!/usr/bin/env bash
dest_path="$($scriptdir/hierma_getparm.sh dest_path)"
ostype=$($scriptdir/hierma_getparm.sh ostype)
comp_path="$scriptdir/setupinf"
complist=$("$scriptdir/hierma_getparm.sh" complist)
tmpinf=tmpinf
index=0

gauge_update() {
    # Update the progress bar.
    count=$((count+1))
    percent=$((count*100/total))
    echo "XXX"
    echo "$percent"
    echo "Found component $compdesc"
    echo "XXX"
}

if [ -z "$complist" ]; then
    complist="$scriptdir/setupinf/comp.lst"
fi

cp "$complist" mycomp.tmp

expand_string() {
# Expand the string variable if one is used.
fullstr=$(echo "$1" | grep '%')
if [ ! -z "$fullstr" ]; then
    strvar=$(echo "$1" | sed 's/%//g')
    strout=$("$scriptdir/hierma_infsect.sh" -f "$inf" -s Strings -g "$strvar" | sed 's/\"//g')
else
    # String does not need expansion.
    strout="$(echo $1 | sed 's/\"//g')"
fi
echo "$strout"
# Returned to stdout, put it in a variable.
}

if [ $EXPRESS = 1 ] && [ ! -z "$complist" ]; then

# Just write the components to MSBATCH.INF and be done with it.
# If some components are not specified in your list as 0, I imagine Setup
# may install certain components based on default settings for a typical
# installation even if you don't want them to.
"$scriptdir/hierma_infsect.sh" -f msbatch.inf -s OptionalComponents -l "$complist" -p

else
# If not running in unattended mode or a component list was not specified,
# display the dialog.

dialog --title "Optional Components" --infobox "Obtaining list of $ostype components..." 3 45
# TODO: Try to add a gauge again.
# New methodology for Beta 1.2. This should allow you to select components
# in any language.
grep -l '^\[Optional Components\]' "$dest_path/htemp/"*.inf > compinfs.tmp
#while read inf; do
#    "$scriptdir/hierma_infsect.sh" -f "$inf" -t "Optional Components" >> total.tmp
#done < compinfs.tmp
#total=$(cat total.tmp | wc -l)
#rm total.tmp 2> /dev/null
#count=0
while read inf; do
    "$scriptdir/hierma_infsect.sh" -f "$inf" -t "Optional Components" > thesecomps.tmp
    while read thiscomp; do
        uninstall="$("$scriptdir/hierma_infsect.sh" -f "$inf" -s "$thiscomp" -g Uninstall)"
        if [ ! -z "$uninstall" ]; then
            "$scriptdir/hierma_infsect.sh" -f "$inf" -s "$thiscomp" -g OptionDesc -g Tip > compinfo.tmp
            # Match found, add name to array...
            compdesc2="$(sed -n '1p' compinfo.tmp)"
            comptip2="$(sed -n '2p' compinfo.tmp)"
            compdesc="$(expand_string "$compdesc2")"
            menu[$index]="$compdesc"
            index=$((index+1))

            # ...then add description and default toggle status
            comptip="$(expand_string "$comptip2")"
            menu[$index]="$comptip"
            index=$((index+1))

            compstatus=$(grep "^\"$compdesc\"[ \t]*=" mycomp.tmp | awk -F'=' '{print $2}')
            if [ "$compstatus" = 1 ]; then
                menu[$index]=ON
            else
                menu[$index]=OFF
            fi
            index=$((index+1))
        fi
#        gauge_update
    done < thesecomps.tmp
done < compinfs.tmp #| dialog --title "Optional Components" --gauge "Obtaining list of $ostype components..." 6 75

dialog --separate-output --title "Optional Components" --cancel-label "Back" --checklist 'Select all of the built-in software components you wish to have installed.' 23 78 17 "${menu[@]}" 2> comp.tmp
exitstatus=$?

# TODO: Create functionality to add the components
# to the configuration database.
if [ $exitstatus = 0 ]; then
    dialog --title "Optional Components" --infobox "Assigning new component settings..." 3 40

    # Beta 1.2: The database points to an external file to get components from.
    index=0
    compcount=$(($(echo ${#menu[@]})/3))
    sort -f comp.tmp | uniq -i > comp3.tmp && mv comp3.tmp comp.tmp

    for i in $(seq 1 $compcount); do
        compexists="$(grep "^${menu[$index]}$" comp.tmp)"
        if [ ! -z "$compexists" ]; then
            echo "\"${menu[$index]}\"=1" >> comp2.tmp
            sed "s/\"${menu[$index]}\"[ \t]*=.*/\"${menu[$index]}\"=1/g" mycomp.tmp > mycomp2.tmp && mv mycomp2.tmp mycomp.tmp
        else
            echo "\"${menu[$index]}\"=0" >> comp2.tmp
            sed "s/\"${menu[$index]}\"[ \t]*=.*/\"${menu[$index]}\"=0/g" mycomp.tmp > mycomp2.tmp && mv mycomp2.tmp mycomp.tmp
        fi
        index=$((index+3))
    done

    # Beta 1.1a: Optimized so all put operations take place in a single command.
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s OptionalComponents -l comp2.tmp -p
    # Reminder, working.comp should be saved along with the configuration
    # database if the user wants.
    mv mycomp.tmp working.comp
    rm comp2.tmp 2> /dev/null
else
    # May want to keep compinfs.tmp around for faster reloading of the
    # component menu.
    rm compinfs.tmp 2> /dev/null
    exit 1
fi

fi

rm compinfs.tmp
exit 0
