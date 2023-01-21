#!/usr/bin/env bash
# TODO: If sed or other tools throw errors about not being able to create
# temporary files on FAT drives, files being modified should be
# stored in RAM first.

bpp=$("$scriptdir/hierma_getparm.sh" dispattr | awk -F',' '{print $1}')
horz=$("$scriptdir/hierma_getparm.sh" dispattr | awk -F',' '{print $2}')
vert=$("$scriptdir/hierma_getparm.sh" dispattr | awk -F',' '{print $3}')

dest_path="$($scriptdir/hierma_getparm.sh dest_path)"
complist="$($scriptdir/hierma_getparm.sh complist)"
dialog --title "Updating Answer File" --infobox "Please wait while the setup answer file is being updated." 3 61

# List of translation files to use is stored in an array.
declare -a list=("$scriptdir/msb_setup.conf" "$scriptdir/msb_name.conf" "$scriptdir/msb_system.conf")

if [ "$1" = "CREATE" ]; then
# INITIAL.INF contains values to be used in MSBATCH.INF by default.
# They are overridden by whatever is in a section of the configuration
# database.
dialog --title "Creating Answer File" --infobox "Please wait while the setup answer file is being created." 3 61
cp "$scriptdir/initial.inf" msbatch.inf
dos2unix msbatch.inf 2> /dev/null # suppress error output
else
dialog --title "Updating Answer File" --infobox "Please wait while the setup answer file is being updated." 3 61
fi

# Now modify the internal attributes accordingly.
for listfile in "${list[@]}"; do

# Small cleanup of code, was a messy if/elif/elif statement before.
case $listfile in
    "$scriptdir/msb_setup.conf") infsect="Setup" ;;
    "$scriptdir/msb_name.conf") infsect="NameAndOrg" ;;
    "$scriptdir/msb_system.conf") infsect="System" ;;
esac

# TODO: Address empty settings having their names printed.
while read option; do
    hiropt="$(echo $option | awk -F'=' '{print $1}')"
    infopt="$(echo $option | awk -F'=' '{print $2}')"
    newval="$($scriptdir/hierma_getparm.sh "$hiropt")"

    if [ -z "$newval" ]; then
        #"$scriptdir/hierma_infsect.sh" -f msbatch.inf -s "$infsect" -d "$infopt"
        echo "$infopt" >> optdel.tmp
    else
        if [ "$hiropt" = "key" ]; then
        # For Windows 98/ME
        #"$scriptdir/hierma_infsect.sh" -f msbatch.inf -s "$infsect" -p "ProductKey=$newval"
        echo "ProductKey=\"$newval\"" >> optput.tmp
        fi
        #"$scriptdir/hierma_infsect.sh" -f msbatch.inf -s "$infsect" -p "$infopt=$newval"
        echo "$infopt=\"$newval\"" >> optput.tmp
    fi
done < "$listfile"
"$scriptdir/hierma_infsect.sh" -f msbatch.inf -s "$infsect" -l optdel.tmp -d -l optput.tmp -p 2> /dev/null
rm optdel.tmp optput.tmp 2> /dev/null
done

# There's also these other options which setup INFs don't take, or have
# trouble with unless the new values are thrown into the registry.

# Forced refresh rate set in the internal configuration
forcerefresh=$($scriptdir/hierma_getparm.sh refresh)
if [ -z "$forcerefresh" ]; then
    # In the registry, -1 means to use the highest supported refresh rate.
    $scriptdir/hierma_regtool.sh -f "$dest_path/hierma.reg" -k 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Class\Display\0000\DEFAULT' -p "\"RefreshRate\"=\"-1\""
else
    $scriptdir/hierma_regtool.sh -f "$dest_path/hierma.reg" -k 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Class\Display\0000\DEFAULT' -p "\"RefreshRate\"=\"$forcerefresh\""
fi

# Beta 1.2: Needed to add default resolution and color depth to registry
# so they could be applied for sure, as DisplChar often wasn't enough.
# internal note: may need to change this to Config\0001\Display\Settings
# (remove comment when status is confirmed)
"$scriptdir/hierma_regtool.sh" -f "$dest_path/hierma.reg" -k "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Class\Display\0000\DEFAULT" -p "\"BitsPerPixel\"=\"$bpp\"" -p "\"Resolution\"=\"$horz,$vert\""

# Network logon credentials for VREDIR (password not included)
pcname=$($scriptdir/hierma_getparm.sh pcname)
workgroup=$($scriptdir/hierma_getparm.sh workgroup)
domain=$($scriptdir/hierma_getparm.sh domain)
"$scriptdir/hierma_infsect.sh" -f msbatch.inf -s Install -g "AddReg" -a "VLogon" > /dev/null

# Clear existing registry entries for netlogon first
# Now done in one command for Beta 1.2
"$scriptdir/hierma_infsect.sh" -f msbatch.inf -s VLogon -l "$scriptdir/setupinf/regdellead" -e

# Computer name
if [ ! -z "$pcname" ]; then
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s VLogon -p "HKLM,\"%PCName%\",\"ComputerName\",,\"$pcname\"" -p "HKLM,\"%VNETSUP%\",\"ComputerName\",,\"$pcname\""
fi

# Workgroup
if [ ! -z "$workgroup" ]; then
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s VLogon -p "HKLM,\"%VNETSUP%\",\"Workgroup\",,\"$workgroup\""
else
    # Default workgroup name.
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s VLogon -p "HKLM,\"%VNETSUP%\",\"Workgroup\",,\"WORKGROUP\""
fi

# Domain
if [ ! -z "$domain" ]; then
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s VLogon -p "HKLM,\"Network\Logon\",\"LMLogon\",1,01,00,00,00" -p "HKLM,\"%MSNP32NP%\",\"AuthenticatingAgent\",,\"$domain\""
    # Redundancy possibly needed for Windows 98.
    "$scriptdir/hierma_regtool.sh" -f hierma.reg -k "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\VxD\VNETSUP" -p "\"LMLogon\"=hex:01,00,00,00"
    "$scriptdir/hierma_regtool.sh" -f hierma.reg -k "Network\Logon" -p "@=\"$domain\""
else
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s VLogon -p "HKLM,\"Network\Logon\",\"LMLogon\",1,00,00,00,00" -e "HKLM,\"%MSNP32NP%\",\"AuthenticatingAgent\""
fi

# MSBATCH.INF must know to load the first boot registry file.
# (though this could already be put in the initial INF along with other things)
# Update for Luminaries 1.1: MSBATCH.INF must copy HIERMA.REG to the
# WINDOWS directory.
"$scriptdir/hierma_infsect.sh" -f msbatch.inf -s Install -g "AddReg" -a "RunOnce" > /dev/null
"$scriptdir/hierma_infsect.sh" -f msbatch.inf -s RunOnce -p "HKLM,\"%RunOnceSetup%\",\"HIERMA Registry Updates\",,\"REGEDIT.EXE /S hierma.reg\""

# Apply internal updates set in config_menu.sh.

# 512mbcap: Limit RAM addressed by Windows to 512MB
if [ "$($scriptdir/hierma_getparm.sh 512mbcap)" = 1 ]; then
    # Enabled: apply 512MB cap in SYSTEM.INI
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s Install -g "UpdateInis" -a "512MBCAP" > /dev/null
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s 512MBCAP -p '%25%\system.ini,386Enh,,"MaxPhysPage=30000"' -p '%25%\system.ini,vcache,,"MaxFileCache=524288"'
else
    # Disabled: remove 512MB cap from SYSTEM.INI
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s Install -g "UpdateInis" -r "512MBCAP" > /dev/null
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s 512MBCAP -e '%25%\system.ini,386Enh,,"MaxPhysPage=30000"' -e '%25%\system.ini,vcache,,"MaxFileCache=524288"'
fi

# dstupdate: Update DST information for U.S. timezones
if [ "$($scriptdir/hierma_getparm.sh dstupdate)" = 1 ]; then
    "$scriptdir/hierma_regtool.sh" -f hierma.reg -k "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones\Central" -l "$scriptdir/setupinf/Central" -p
    "$scriptdir/hierma_regtool.sh" -f hierma.reg -k "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones\Eastern" -l "$scriptdir/setupinf/Eastern" -p
    "$scriptdir/hierma_regtool.sh" -f hierma.reg -k "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones\Mountain" -l "$scriptdir/setupinf/Mountain" -p
    "$scriptdir/hierma_regtool.sh" -f hierma.reg -k "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones\Pacific" -l "$scriptdir/setupinf/Pacific" -p
    "$scriptdir/hierma_regtool.sh" -f hierma.reg -k "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones\Alaskan" -l "$scriptdir/setupinf/Alaskan" -p
else
    # Just delete the keys if it's disabled, I don't care what else you
    # managed to throw in them before external updates could commence.
    "$scriptdir/hierma_regtool.sh" -f hierma.reg -x "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones\Central"
    "$scriptdir/hierma_regtool.sh" -f hierma.reg -x "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones\Eastern"
    "$scriptdir/hierma_regtool.sh" -f hierma.reg -x "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones\Mountain"
    "$scriptdir/hierma_regtool.sh" -f hierma.reg -x "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones\Pacific"
    "$scriptdir/hierma_regtool.sh" -f hierma.reg -x "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Time Zones\Alaskan"
fi

# exdefault: Show all files and extensions by default
if [ "$($scriptdir/hierma_getparm.sh exdefault)" = 1 ]; then
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s Install -g AddReg -a "EXDEFAULT" > /dev/null
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s EXDEFAULT -p 'HKU,".Default\Software\Microsoft\Windows\CurrentVersion\Explorer","ShellState",1,10,00,00,00,03,00,00,00,00,00,00,00,00,00,00,00'
else
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s Install -g AddReg -r "EXDEFAULT" > /dev/null
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s EXDEFAULT -e 'HKU,".Default\Software\Microsoft\Windows\CurrentVersion\Explorer","ShellState",1,10,00,00,00,03,00,00,00,00,00,00,00,00,00,00,00'
fi

# usrprof: Enable user profiles
if [ "$($scriptdir/hierma_getparm.sh usrprof)" = 1 ]; then
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s Install -g AddReg -a "USRPROF" > /dev/null
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s USRPROF -p 'HKLM,"NetworkLogon","UserProfiles",1,1'
else
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s Install -g AddReg -r "USRPROF" > /dev/null
    "$scriptdir/hierma_infsect.sh" -f msbatch.inf -s USRPROF -e 'HKLM,"NetworkLogon","UserProfiles",1,1'
fi

# ultradma: Force enabling UltraDMA on all drives
if [ "$($scriptdir/hierma_getparm.sh ultradma)" = 1 ]; then
    cp "$dest_path/htemp/mshdc.inf" ./
    "$scriptdir/hierma_infsect.sh" -f mshdc.inf -s ESDI_AddReg -p "HKR,,IDEDMADRIVE0,1,01" -p "HKR,,IDEDMADRIVE1,1,01"
    mv mshdc.inf "$dest_path/"
else
    rm "$dest_path/mshdc.inf" 2> /dev/null
fi

# End of internal updates

exit 0
