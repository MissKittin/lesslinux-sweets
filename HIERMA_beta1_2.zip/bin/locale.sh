#!/usr/bin/env bash
dest_path="$("$scriptdir/hierma_getparm.sh" dest_path)"

dialog --title "Locale" --infobox "Please wait, gathering the locale options..." 3 50

# Assemble the locale list unless it exists already.
if [ ! -f locale.tmp ]; then
    precopy="$(find "$dest_path" -iname "precopy1.cab")"
    cabextract "$precopy" -F locale.inf -q
    unix2dos locale.inf 2> /dev/null
    echo >> locale.inf # Infsect ignores last line, so pad the INF.

    "$scriptdir/hierma_infsect.sh" -f locale.inf -s HIERMA_ALL -g OptionDesc | sed 's/\%//g' > locale.tmp
    awk -F':' '{print $2}' locale.tmp > locstr.tmp
    "$scriptdir/hierma_infsect.sh" -f locale.inf -s Strings -l locstr.tmp -g | awk -F'=' '{print $2}' | sed 's/\"//g;s|British|British/Scottish|g' > locstr2.tmp && mv locstr2.tmp locstr.tmp
fi

# Create a menu from the list.
index=0
while read locale; do
    col1="$(echo $locale | awk -F':' '{print $1}')"
    menu[$index]="$col1"
    index=$((index+2))
done < locale.tmp

index=1
while read locstr; do
    menu[$index]="$locstr"
    index=$((index+2))
done < locstr.tmp

# Display the menu.
locale_choice=$(dialog --title "Locale" --menu "Select the primary locale to be used when installing your operating system." 23 55 14 "${menu[@]}" 3>&1 1>&2 2>&3)
if [ $? = 0 ]; then
    "$scriptdir/hierma_setparm.sh" locale "$locale_choice"
    od="$("$scriptdir/hierma_infsect.sh" -f locale.inf -s "$locale_choice" -g OptionDesc | sed 's/\%//g')"
    locale_desc="$("$scriptdir/hierma_infsect.sh" -f locale.inf -s Strings -g "$od" | sed 's/\"//g')"

    # Just look up "The Flying Scotsman" (wonder if he'll do a video on this)
    if [ "$locale_desc" = "English (British)" ]; then
        locale_desc="English (British/Scottish)"
    fi

    "$scriptdir/hierma_setparm.sh" locale_desc "$locale_desc"
fi
