#!/static/bin/ash

# FIXME: Remove dependency on zenity!
# FIXME: Localize!

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
. /etc/lesslinux/branding/branding.en.sh
[ -f "/etc/lesslinux/branding/branding.${lang}.sh" ] && . /etc/lesslinux/branding/branding.${lang}.sh

this_version=` cat /etc/lesslinux/updater/version.txt `

/usr/bin/zenity --question --text "Bevor Sie $brandlong aktualisieren stellen Sie sicher, dass eine Internetverbindung hergestellt ist.\n\nSind Sie bereit für die Suche nach Updates?" || exit 1

# Importiere den Schlüssel
/usr/bin/gpg --import /etc/lesslinux/updater/updatekey.asc

# Update-Ordner erstellen (muss nicht groß sein)
/bin/mkdir -m 0700 /tmp/lesslinux.update

# Download des Update-Scriptes, erfordert setzen de
for fname in updater.tbz updater.tbz.asc ; do
    echo internet > /proc/self/attr/current
    /static/bin/wget -O /tmp/lesslinux.update/${fname} http://download.lesslinux.org/updater/${this_version}/${fname}
    retval=$?
    echo _ > /proc/self/attr/current
    if [ "$retval" -gt 0 ] ; then
	/usr/bin/zenity --error --text 'Die Updates konnten nicht überspielt werden!'
	exit 1
    fi
done

# Prüfung der Signatur
if /usr/bin/gpg --verify /tmp/lesslinux.update/updater.tbz.asc ; then
    echo "===> Signatur OK, fahre fort"
    # Signatur war gut? Na dann starten wir das Script...
    cd /tmp/lesslinux.update
    tar xjf updater.tbz
    /static/bin/ash RUNME.sh
else
    /usr/bin/zenity --error --text 'Das Signaturprüfung des Update-Scriptes ist fehlgeschlagen!'
    exit 1
fi

		
