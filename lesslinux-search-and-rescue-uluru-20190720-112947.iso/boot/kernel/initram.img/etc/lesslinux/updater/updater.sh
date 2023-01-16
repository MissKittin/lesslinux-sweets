#!/static/bin/ash

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin

# FIXME: Remove dependency on zenity!
# FIXME: Localize!

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
. /etc/rc.lang/en/messages.sh
[ -f "/etc/rc.lang/$lang/messages.sh" ] && . /etc/rc.lang/$lang/messages.sh
. /etc/lesslinux/branding/branding.en.sh
[ -f "/etc/lesslinux/branding/branding.${lang}.sh" ] && . /etc/lesslinux/branding/branding.${lang}.sh

this_version=` cat /etc/lesslinux/updater/version.txt `
base_url=` cat /etc/lesslinux/updater/baseurl.txt ` 
WGET='/static/bin/wget'
[ -x /usr/bin/wget ] && WGET='/usr/bin/wget'

if [ "$1" = "--quiet" ] ; then
	echo "Skipping question, start searching..."
else
	/usr/bin/zenity --question --text "$updater_ready_question" || exit 1
fi

# Importiere the key
/usr/bin/gpg --import /etc/lesslinux/updater/updatekey.asc

# Create update folder
mkdir -m 0755 /tmp/lesslinux.update

# Download the update script - needs setting the SMACK context
echo internet > /proc/self/attr/current

for fname in updater.tbz updater.tbz.asc ; do
    # Since we validate afterwards, do not check certificates for now
    $WGET -T 3 --no-check-certificate -U LessLinuxUpdater -O /tmp/lesslinux.update/${fname} "${base_url}/${this_version}/${fname}"
    retval=$?
    if [ "$retval" -gt 0 ] ; then
	[ "$1" = "--quiet" ] || /usr/bin/zenity --error --text "$updater_download_failed"
	exit 1
    fi
done
echo _ > /proc/self/attr/current

# Prüfung der Signatur
if /usr/bin/gpg --verify /tmp/lesslinux.update/updater.tbz.asc ; then
    echo "===> Signatur OK, fahre fort"
    # Signatur war gut? Na dann starten wir das Script...
    cd /tmp/lesslinux.update
    tar xjf updater.tbz
    if [ "$1" = "--quiet" ] ; then
	/static/bin/ash RUNME.sh --quiet
    else
	/static/bin/ash RUNME.sh
    fi
else
    [ "$1" = "--quiet" ] || /usr/bin/zenity --error --text "$updater_signature_failed"
    exit 1
fi

		
