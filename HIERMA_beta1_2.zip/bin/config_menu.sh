#!/usr/bin/env bash
# Load the list of internal updates. It's bound to vary as new ideas come up
# or HIERMA gets translated, so it's better to just store it in an external
# file.
updindex=0
while read intupd; do
    col1=$(echo $intupd | awk -F'|' '{print $1}')
    updmenu[$updindex]="$col1"
    updindex=$((updindex+1))
    col2=$(echo $intupd | awk -F'|' '{print $2}')
    updmenu[$updindex]="$col2"
    updindex=$((updindex+2))
done < "$scriptdir/setupinf/intupd"

defmatch() {
    # $1 = parameter to check
    # $2 = value to match
    # Check the database to determine the default radio option.
    # Useful for both radio and check lists.
    def="$($scriptdir/hierma_getparm.sh $1)"
    if [ "$def" = "$2" ]; then
        echo ON
    else
        echo OFF
    fi
}

setuptoggle() {
    # Get existing setup switches, and set default toggles in the menu
    # based on what's found. Result returned to stdout.
    # $1 = switch (typed like /is)
    myswitch="$("$scriptdir/hierma_getparm.sh" switches | grep "$1 ")"
    if [ "$myswitch" ]; then
        echo ON
    else
        myswitch="$("$scriptdir/hierma_getparm.sh" switches | grep "$1$")"
        if [ "$myswitch" ]; then
            echo ON
        else
            echo OFF
        fi
    fi
}

devicetoggle() {
    # Much like setuptoggle(), except a different syntax is used.
    mydevdet="$("$scriptdir/hierma_getparm.sh" devdet | grep "$1;")"
    if [ -z "$mydevdet" ]; then
        # Check if switch is at the end of the line.
        mydevdet="$("$scriptdir/hierma_getparm.sh" devdet | grep "$1$")"
        if [ "$mydevdet" ]; then
            echo ON
        else
            echo OFF
        fi
    else
        echo ON
    fi
}

mainmenu() {
# May need to know the OS type for certain operating systems.
ostype="$($scriptdir/hierma_getparm.sh ostype)"

# Grab already legible attributes.
key="$($scriptdir/hierma_getparm.sh key)"
instpath="$($scriptdir/hierma_getparm.sh instpath)"
tz="$($scriptdir/hierma_getparm.sh tz)"
kbddesc="$($scriptdir/hierma_getparm.sh kbddesc)"
locale_desc="$($scriptdir/hierma_getparm.sh locale_desc)"
monitor="$($scriptdir/hierma_getparm.sh monitor)"
dispattr="$($scriptdir/hierma_getparm.sh dispattr)"
name="$($scriptdir/hierma_getparm.sh name)"
org="$($scriptdir/hierma_getparm.sh org)"
machine="$($scriptdir/hierma_getparm.sh machine)"
uninstback="$($scriptdir/hierma_getparm.sh uninstback)"

# Gather some values from the database and make them legible.

# Display attributes
dispattr1=$(echo $dispattr | awk -F, '{print $1}')
dispattr2=$(echo $dispattr | awk -F, '{print $2}')
dispattr3=$(echo $dispattr | awk -F, '{print $3}')
refresh="$($scriptdir/hierma_getparm.sh refresh)"

# Network credentials
pcname=$("$scriptdir/hierma_getparm.sh" pcname)
workgroup=$("$scriptdir/hierma_getparm.sh" workgroup)
domain=$("$scriptdir/hierma_getparm.sh" domain)
if [ -z "$workgroup" ]; then
    workgroup="WORKGROUP"
fi
# If a logon domain is specified, the second column displays it; otherwise,
# it shows the workgroup.
if [ -z "$domain" ]; then
    netlogon_desc="$pcname\\$workgroup"
else
    netlogon_desc="$pcname\\$domain"
fi

# Install type
insttype=$($scriptdir/hierma_getparm.sh insttype)
case $insttype in
    0) insttype_name="Compact" ;;
    1) insttype_name="Typical" ;;
    2) insttype_name="Portable" ;;
    # If insttype is 3, an invalid value, or nonexistent, scripts
    # should default to "Custom" as the install type.
    *) insttype_name="Custom" ;;
esac

# Uninstall options
uninstall=$($scriptdir/hierma_getparm.sh uninstall)
case $uninstall in
    1) uninstall_name="Prompt to save system files" ;;
    5) uninstall_name="Backup existing system files" ;;
    *) uninstall_name="Do not backup existing system files" ;;
esac

# Power management options
power=$($scriptdir/hierma_getparm.sh power)
if [ -z "$power" ]; then
    power="Let OS decide"
fi

if [ -z "$name" ]; then
    name="NONE"
fi
if [ -z "$org" ]; then
    org="NONE"
fi
choice=$(dialog --title "Setup Options" --cancel-label "Back" --menu 'You can configure your setup program to run in a certain way and supply essential information from HIERMA. If you prefer to supply some or all of the information while your setup program is running, disable the Express option in "More Options".' 23 70 12 \
    'Proceed with these settings' '' \
    'Product Key' "$key" \
    'Install Path' "$instpath" \
    'Install Type' "$insttype_name" \
    'Time Zone' "$tz" \
    'Keyboard Layout' "$kbddesc" \
    'Locale' "$locale_desc" \
    'Monitor' "$monitor" \
    'Color Depth/Resolution' "${dispattr1}bpp, ${dispattr2}x${dispattr3} @ ${refresh}Hz" \
    'Name/Organization' "$name/$org" \
    'Network Identification' "$netlogon_desc" \
    'Uninstall Options' "$uninstall_name" \
    'Uninstall Backup' "$uninstback" \
    'Power Management' "$power" \
    'More Options' 'Toggle other Setup attributes' \
    'Setup Switches' 'Configure how Setup will run' \
    'Device Detection' 'Configure Setup device detection' \
    'Internal Updates' 'Apply small tweaks during Setup' \
3>&1 1>&2 2>&3)
if [ $? != 0 ]; then
    exit 1
fi
}

while (true); do
mainmenu

case $choice in
    'Proceed with these settings')
        # Exit with code 0, allowing the script to advance to the next step.
        rm *.tmp locale.inf multilng.inf monitor.inf monitor?.inf 2> /dev/null
        exit 0
        ;;

    'Product Key')
        key2=$(dialog --title "Product Key" --inputbox "Enter the product key to be used during Setup." 9 40 "$key" 3>&1 1>&2 2>&3)
        key=$key2
        $scriptdir/hierma_setparm.sh key "$key" ;;

    'Install Path')
        instpath2=$(dialog --title "Install Path" --inputbox 'This is the path that your setup program will use to install your operating system to the desired destination. This must be a DOS-based pathname respecting the 8.3 character format, such as C:\WINDOWS.' 11 50 "$instpath" 3>&1 1>&2 2>&3)
        if [ $? = 0 ]; then
            instpath="$instpath2"
            $scriptdir/hierma_setparm.sh instpath "$instpath"
        fi ;;

    'Install Type')
        # Radio lists are more intuitive; they allow the user to see
        # exactly what they or the default configuration had set before
        # in the same dialog.
        insttype2=$(dialog --title "Install Type" --radiolist 'The install type you select will cause Setup to use a predefined list of components to install. To ensure full control over the installation settings, it is highly recommended that you choose "Custom".' 15 50 5 \
        "0" "Compact" $(defmatch insttype 0)  \
        "1" "Typical" $(defmatch insttype 1) \
        "2" "Portable" $(defmatch insttype 2) \
        "3" "Custom" $(defmatch insttype 3) 3>&1 1>&2 2>&3)
        if [ $? = 0 ]; then
            insttype="$insttype2"
            $scriptdir/hierma_setparm.sh insttype "$insttype"
        fi ;;

    'Time Zone')
        $scriptdir/tz.sh ;;

    'Keyboard Layout')
        $scriptdir/kbdlayt.sh ;;

    'Locale')
        $scriptdir/locale.sh ;;

    'Monitor')
        $scriptdir/monitor.sh ;;

    'Color Depth/Resolution')
        dialog --title "Color Depth/Resolution" --form "Enter the initial display attributes. If these are invalid, 640x480 in 16 colors will be used instead.\n\nBe sure your monitor and video adapter support the refresh rate at the resolution you specify! To let your operating system decide the refresh rate, leave the field empty or enter -1." 17 56 4 \
            'Color Depth:' 1 15 "$dispattr1" 1 30 5 4 \
            'X Resolution:' 2 15 "$dispattr2" 2 30 5 4 \
            'Y Resolution:' 3 15 "$dispattr3" 3 30 5 4 \
            'Refresh Rate:' 4 15 "$refresh" 4 30 5 4 2> dispattr.tmp
        if [ $? = 0 ]; then
            dispattr1=$(sed -n '1p' dispattr.tmp)
            dispattr2=$(sed -n '2p' dispattr.tmp)
            dispattr3=$(sed -n '3p' dispattr.tmp)
            refresh=$(sed -n '4p' dispattr.tmp)
            $scriptdir/hierma_setparm.sh dispattr "$dispattr1,$dispattr2,$dispattr3"
            if [ -z "$refresh" ]; then
                $scriptdir/hierma_setparm.sh refresh -1
            else
                $scriptdir/hierma_setparm.sh refresh "$refresh"
            fi
        fi ;;

    'Name/Organization')
        if [ "$name" = "NONE" ]; then
            name=""
        fi
        if [ "$org" = "NONE" ]; then
            org=""
        fi
        dialog --title "Name/Organization" \
        --form "Enter your name that will appear in the registration information. You can also supply the name of your organization if applicable." 10 50 2 \
        'Name:' 1 1 "$name" 1 15 50 50 \
        'Organization:' 2 1 "$org" 2 15 50 50 2> nameorg.tmp

        if [ $? = 0 ]; then
            name=$(sed -n '1p' nameorg.tmp)
            org=$(sed -n '2p' nameorg.tmp)
            "$scriptdir/hierma_setparm.sh" name "$name"
            "$scriptdir/hierma_setparm.sh" org "$org"
        fi ;;

    'Network Identification')
        dialog --title "Network Logon" --form "If you have a network card installed and need to log on to an SMB-compatible share (Windows NT per se), you can specify a computer name and workgroup or domain from here." 13 60 3 \
            'Computer Name:' 1 13 "$pcname" 1 28 16 15 \
            'Workgroup:' 2 13 "$workgroup" 2 28 16 15 \
            'Domain:' 3 13 "$domain" 3 28 16 15 2> netlogon.tmp
        if [ $? = 0 ]; then
            pcname=$(sed -n '1p' netlogon.tmp)
            workgroup=$(sed -n '2p' netlogon.tmp)
            domain=$(sed -n '3p' netlogon.tmp)
            "$scriptdir/hierma_setparm.sh" pcname "$pcname"
            "$scriptdir/hierma_setparm.sh" workgroup "$workgroup"
            "$scriptdir/hierma_setparm.sh" domain "$domain"
        fi ;;

    'Uninstall Options')
        uninst_choice=$(dialog --title "Uninstall Options" --menu "If you are upgrading an existing version of Windows, you can specify whether to save your existing system files or not, or allow the client to decide." 13 50 3 \
            "0" "Do not backup existing system files" \
            "1" "Prompt to save system files" \
            "5" "Backup existing system files" \
        3>&1 1>&2 2>&3)
        if [ $? = 0 ]; then
            uninstall="$uninst_choice"
            $scriptdir/hierma_setparm.sh uninstall "$uninstall"
        fi ;;

    'Uninstall Backup')
        uninstback2=$(dialog --title "Uninstall Backup" --inputbox "If you are upgrading an existing operating system in place, a directory to back up to needs to be specified here. This option is useless if you're doing a clean install or have configured the setup program to not back up system files." 13 50 "$uninstback" 3>&1 1>&2 2>&3)
        if [ $? = 0 ]; then
            uninstback="$uninstback2"
            $scriptdir/hierma_setparm.sh uninstback "$uninstback"
        fi ;;

    'Power Management')
        power=$(dialog --title "Power Management" --radiolist "You can allow your operating system to manage some of the power management features of your computer, including suspension, modem wakeup, and hard disk spindown. If you do not wish to allow OS control of these features, disable it in your BIOS settings.\n\nNOTES:\n - With ACPI enabled, the OS takes control of ALL power management features.\n - It is recommended that you update your BIOS to ensure system stability with ACPI.\n - ACPI requires Windows 98, NT 5.0, or later." 20 75 3 \
        'Default' 'Let Setup choose the power configuration' "$(defmatch power Default)" \
        'APM' 'Install Advanced Power Management support' "$(defmatch power APM)" \
        'ACPI' 'Use Advanced Configuration and Power Interface' "$(defmatch power ACPI)" \
        3>&1 1>&2 2>&3)

        if [ $? = 0 ]; then
            if [ "$power" = "Default" ]; then
                "$scriptdir/hierma_setparm.sh" power DELETE
            else
                "$scriptdir/hierma_setparm.sh" power "$power"
            fi
        fi ;;

    'More Options')
        "$scriptdir/config_toggle.sh"
        ;;

    'Setup Switches')
        # TODO: Grab switches from the database to use as the default toggles.
        # Use line-by-line output for checklists.
        dialog --title "Setup Switches" --separate-output --checklist "You can change how your setup program is executed upon booting into a minimal DOS environment. It is recommended that you keep the default settings." 16 65 7 \
            "/is" "Do not run ScanDisk" $(setuptoggle /is) \
            "/im" "Skip conventional memory check" $(setuptoggle /im) \
            "/IW" "Automatically accept license agreement" $(setuptoggle /IW) \
            "/iq" "Do not check for cross-linked files" $(setuptoggle /iq) \
            "/nm" "No machine check (needed if using FreeDOS)" $(setuptoggle /nm) \
            "/ig" "Fix for older Gateway/Micron computers" $(setuptoggle /ig) \
            "/n" "Don't load the mouse driver" $(setuptoggle /n) \
            "/l" "Use Logitech protocol mouse" $(setuptoggle /l) \
            "/c" "Don't run SMARTDrive" $(setuptoggle /c) \
            "/d" "Bypass existing Windows configuration" $(setuptoggle /d) \
            "/ih" "Run ScanDisk in foreground" $(setuptoggle /ih) \
            "/it" "Do not check for dirty TSRs" $(setuptoggle /it) \
            2> switches.tmp

        if [ $? = 0 ]; then
            switches="$(cat switches.tmp | tr '\n' ' ' | sed 's/\"//g;')"
            "$scriptdir/hierma_setparm.sh" switches "$switches"
        fi
        rm switches.tmp ;;

    'Device Detection')
        dialog --title "Device Detection" --separate-output --checklist "This menu provides a few options for configuring device detection during Setup. It is recommended that you keep the default settings. To specify more device detection options, you'll need to manually modify the configuration databse. Read (some documentation) for more information." 18 65 7 \
            "c-" "Detect ALL devices" $(devicetoggle c-) \
            "c" "Use safe detection (for upgrades)" $(devicetoggle c) \
            "d=Keyboard" "Do not detect devices, except keyboard" $(devicetoggle d=Keyboard) \
            "g=3" "Maximum verbosity in device detection" $(devicetoggle g=3) \
            "p" "Log Setup performance timing to DETLOG.TXT" $(devicetoggle p) \
            "n" "Never use Safe Recovery" $(devicetoggle n) \
            "r" "Use Safe Recovery whenever possible" $(devicetoggle r) \
            2> devdet.tmp

        if [ $? = 0 ]; then
            # If no device detection switches are ticked, do not invoke /p.
            if [ -s devdet.tmp ]; then
                devdet=$(cat devdet.tmp | tr '\n' ' ' | sed 's/\"//g;s/ /;/g;s|^|/p |;s/;$//')
            else
                devdet="DELETE"
            fi
            "$scriptdir/hierma_setparm.sh" devdet "$devdet"
        fi
        rm devdet.tmp ;;

    'Internal Updates')
        # These updates are implanted into the HIERMA core and are
        # comprised of very small tweaks to plain text files.

        # Get status of each option
        updindex=2
        while read intupd; do
            upd=$(echo $intupd | awk -F'|' '{print $1}')
            updenabled=$($scriptdir/hierma_getparm.sh $upd)
            if [ "$updenabled" = 1 ]; then
                updmenu[$updindex]="ON"
                updindex=$((updindex+3))
            else
                updmenu[$updindex]="OFF"
                updindex=$((updindex+3))
            fi
        done < "$scriptdir/setupinf/intupd"
        # Don't know why but a trailing ON/OFF value is set at end of array??
        unset updmenu[$updindex]

        dialog --title "Internal Updates" --separate-output --checklist "HIERMA includes a few tweaks you can apply to various plain text files your operating system reads from when running its setup program. No additional media is required to install them." 18 75 10 "${updmenu[@]}" 2> intupd.tmp

        if [ $? = 0 ]; then
            updindex=0
            updcount=$(wc -l "$scriptdir/setupinf/intupd" | awk '{print $1}')
            for i in $(seq 1 $updcount); do
                updtest="$(grep "^${updmenu[$updindex]}$" intupd.tmp)"
                if [ ! -z "$updtest" ]; then
                    updstatus=1
                else
                    updstatus=0
                fi
                "$scriptdir/hierma_setparm.sh" ${updmenu[$updindex]} $updstatus
                updindex=$((updindex+3))
            done
        fi
        rm intupd.tmp
        ;;

    *) echo "I'll see you next week on the Anybody's Show." ;;  
esac
done
