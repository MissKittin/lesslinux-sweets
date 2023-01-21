#!/usr/bin/env bash
# TODO: KEYATTR should be the second column in this menu.
# .lst should all become .tmp. (probably not?)

# TODO: Dual methods for local/FTP updating.

# Hide mount/unmount options for non-root users.
if [ "$(id -un)" = "root" ]; then
update_choice=$(dialog --title "Update Source" --cancel-label "Back" --menu "HIERMA can preload updates for your operating system to install, whether they be INF scripts, registry modifications, executables, or merely sets of files. Update preloading has to be carried out by additional shell scripts that follow HIERMA's standards, so you'll need a compatible update source handy." 16 70 5 \
    'Local' 'Load updates from a local source' \
    'FTP' 'Load updates from an FTP source' \
    'Mount' 'Mount a device' \
    'Unmount' 'Unmount a device' \
    'Skip' 'Skip update preloading' 3>&1 1>&2 2>&3)
updcfgdlg=$?
else
update_choice=$(dialog --title "Update Source" --menu "HIERMA can preload updates for your operating system to install, whether they be INF scripts, registry modifications, executables, or merely sets of files. Update preloading has to be carried out by additional shell scripts that follow HIERMA's standards, so you'll need a compatible update source handy." 14 70 13 \
    'Local' 'Load updates from a local source' \
    'FTP' 'Load updates from an FTP source' \
    'Skip' 'Skip update preloading' 3>&1 1>&2 2>&3)
updcfgdlg=$?
fi

if [ $updcfgdlg = 0 ]; then
    rm upd.lst confupd.lst updsel.lst 2> /dev/null
    case $update_choice in
        'Local')
            $scriptdir/hierma_pathsel.sh LOCAL update_path
            update_path="$($scriptdir/hierma_getparm.sh update_path)"
            ;;
        'FTP')
            $scriptdir/hierma_pathsel.sh FTP update_path
            update_path="$($scriptdir/hierma_getparm.sh update_path)"
            ;;
        'Mount') $scriptdir/hierma_mount.sh MOUNT ;;
        'Unmount') $scriptdir/hierma_mount.sh UMOUNT ;;
        'Skip') exit 2 ;;
    esac
else
    exit 1
fi

ostype=$($scriptdir/hierma_getparm.sh ostype)
if [ ! -f upd.lst ]; then
    # first check for scripts that don't have the OSTYPE directive
    grep -L "%OSTYPE%=" "$update_path"/*.sh > upd.lst

    # now check for scripts with OSTYPE directive and ignore them if they
    # don't match the config entry
    grep -H "%OSTYPE%=" "$update_path"/*.sh > upd.tmp
    grep "=$ostype," upd.tmp > upd2.tmp
    grep ",$ostype$" upd.tmp >> upd2.tmp
    grep ",$ostype," upd.tmp >> upd2.tmp
    grep "=$ostype$" upd.tmp >> upd2.tmp
    awk -F':' '{print $1}' upd2.tmp > upd3.tmp
    cat upd3.tmp >> upd.lst
    rm *.tmp
fi

if [ ! -f confupd.lst ]; then
    # Which scripts are configurable?
    while read script; do
        config_meta=$(grep %CONFIG%=1 $script)
        if [ ! -z "$config_meta" ]; then
            echo $script >> confupd.lst
        fi
    done < upd.lst
fi

if [ ! -s confupd.lst ]; then
    # No tweakable updates found, go directly to installer.
    exit
fi

index=0

# This option is selected when the user is done tweaking updates.
menu[$index]="Proceed to update checklist"
index=$((index+1))
menu[$index]=""
index=$((index+1))

if [ ! -f conftitle.tmp ]; then
# Keep a list of titles and their cooresponding script files.
while read script; do
    title="$(grep %TITLE%= $script | awk -F'=' '{print $2}')"
    echo $title=$script >> conftitle.tmp
done < confupd.lst
fi

while read script; do
    col1="$(grep %TITLE%= $script | awk -F'=' '{print $2}')"
    menu[$index]="$col1"
    index=$((index+1))
    col2="$(grep %DESC%= $script | awk -F'=' '{print $2}')"
    menu[$index]="$col2"
    index=$((index+1))
done < confupd.lst
updatecfg_menu() {
    choice=$(dialog --title "Configure Updates" --menu "Some updates on your medium can be tweaked to suit your needs prior to installation. If you have updates stored at another location, choose \"Use another medium\"." 19 78 8 "${menu[@]}" 3>&1 1>&2 2>&3)
}
exitstatus=0

while [ $exitstatus = 0 ]; do
updatecfg_menu
exitstatus=$?
if [ $exitstatus != 0 ]; then
    exit 1
fi

if [ "$choice" = "Proceed to update checklist" ]; then
    break
else
    execute="$(grep "$choice=" conftitle.tmp | awk -F'=' '{print $2}')"
    # Standard config switch. All tweakable update scripts must use this.
    $scriptdir/$execute -c
fi
done
