#!/usr/bin/env bash

index=0

if [ ! -f updtitle.tmp ]; then
# Keep a list of titles and their cooresponding script files.
while read script; do
    title="$(grep %TITLE%= $script | awk -F'=' '{print $2}')"
    echo $title=$script >> updtitle.tmp
done < upd.lst
fi

while read script; do
    col1="$(grep %TITLE%= $script | awk -F'=' '{print $2}')"
    menu[$index]="$col1"
    index=$((index+1))
    col2="$(grep %DESC%= $script | awk -F'=' '{print $2}')"
    menu[$index]="$col2"
    index=$((index+1))

    # WHY DO YOU ALWAYS FORGET THIS!!!!! IT NEEDS A THIRD PARAMETER
    # INDICATING IF IT IS TICKED BY DEFAULT!!!
    ticked="$(grep %DEFAULT%= $script | awk -F'=' '{print $2}')"
    menu[$index]="$ticked"
    index=$((index+1))
done < upd.lst

updatesel_menu() {
   dialog --title "Update Selection" --separate-output --checklist "Here you can select a set of external updates/modifications to install. Updates are marked for preloading using the space bar. When you're ready, press OK." 19 78 8 "${menu[@]}" 2> updsel.tmp
}

exitstatus=0
updatesel_menu
exitstatus=$?
if [ $exitstatus != 0 ]; then
    # Go back...
    exit 1
fi

# Install the updates if user hit OK.

while read script; do
    # Execute EVERY update script!!! KETTLE!!!!!!!!!!!!!!!
    execute="$(grep "$script=" updtitle.tmp | awk -F'=' '{print $2}')"
    title="$(grep "$script=" updtitle.tmp | awk -F'=' '{print $1}')"
    dialog --title "Installing Updates" --infobox "Preloading update $title" 3 60
    $execute
done < updsel.tmp

# Ask user if it wants to load more updates.
dialog --title "Install more updates?" --defaultno --yesno "If you have more updates to install from another medium, you can go back to the configuration dialog and load it from there.\n\nDo you want to go back to the configuration menu?" 9 60

# TODO: User should be able to save the last set of updates at the end
# of the script.

if [ $? = 0 ]; then
    # Exit code 1 will bring the user back to the update configuration dialog.
    exit 1
fi
