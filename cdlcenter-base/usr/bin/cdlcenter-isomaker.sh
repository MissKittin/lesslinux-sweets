#!/bin/sh
# Author           : Maciej Kosmulski ( barnim@tmc.gda.pl ) 
# Created On       : 2004.02.11
# Last Modified By : Michal Wrobel (wrobel@task.gda.pl)
# Last Modified On : 2006.03.25
# Version          : 0.7.0
# 
# Description      : 
# Programu cdlcenter-isomaker.sh sluzy do tworzenia indywidualnych
# dystrybucji systemu cdlinux.pl.
# Przed przystapieniem do tworzenia wlasnej dystrybucji nalezy najpierw
# zainstalwoac system cdlinux.pl na dysku twardym.
# 
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details 
# or contact # the Free Software Foundation for a copy) 
#
# TODO:                      
# - poprawic obsluge i wykrywanie bledow !

TEMP=/tmp
# katalog roboczy
DIR=$TEMP/iso
# plik z logami calej operacji
LOG_FILE=$TEMP/log.isomaker
# gdzie sie miesci katalog z isolinux.tgz:
ISOLINUX_DIR=/cdlinux 

# plik wynikowy (obraz)
DEST=$1

if [ -z $DEST ] ; then
    echo -e "Sk³adnia: cdlcenter-isomaker.sh obrazcd.iso"
    echo -e "gdzie \"obrazcd.iso\" jest nazw± pliku docelowego."
    echo -e "\nUWAGA! Skrypt kasuje zawarto¶æ katalogów:"
    echo -e "/var/cache/apt/archives/"
    echo -e "/var/lib/apt/lists/\n"
    echo -e "Upewnij siê, czy uruchamiasz ten skrypt z systemu zainstalowanego na dysku !\n"
    exit 0
fi

kimjestem="maly" 

#
# Przygotowanie do tworzenia ISO
#

rm -df $LOG_FILE
#kopia etc dla bezpieczenstwa
cp -dpr /etc $TEMP

# dodanie linka do join dla kazdego runlevelu
cd $TEMP
ln -s ../init.d/join etc/rcS.d/S11join 2>> $LOG_FILE
ln -s ../init.d/yahade etc/rc2.d/S90yahade 2>> $LOG_FILE

cp $TEMP/etc/inittab.orig $TEMP/etc/inittab

# Konfiguracja reboot dla CD
cat <<EOF > $TEMP/etc/init.d/reboot
#! /bin/sh
#
# reboot        Execute the reboot command.
#
# Version:      @(#)reboot  2.75  22-Jun-1998  miquels@cistron.nl
#
PATH=/sbin:/bin:/usr/sbin:/usr/bin
echo -n "Ponowne uruchamianie komputera, proszê czekaæ... "
eject /dev/cdrom
sleep 3
reboot -d -f -i
EOF
chmod 755 $TEMP/etc/init.d/reboot

# Konfiguracja fstab
cat <<EOF > $TEMP/etc/fstab
# /etc/fstab: statyczna informacja o systemach plikow.
#
# <system plikow>       <punkt montowania>      <typ>   <opcje>         <dump>  <pass>
/dev/ram4		/               	ext2    errors=remount-ro       0       1
proc			/proc           	proc    defaults                0       0
none           /sys             sysfs    defaults                        0       0 
EOF

# czyszczenie ustawien sieci
cp $TEMP/etc/network/interfaces.orig $TEMP/etc/network/interfaces
cp $TEMP/etc/inittab.orig $TEMP/etc/inittab

# czyszczenie modules
#echo "" > $TEMP/etc/modules 2>> $LOG_FILE

# czyszczenie logow
# kasowanie archiwow apt
echo -en "Kasujê archiwa i listy apt... " | tee -a $LOG_FILE
# kasowanie list apt
cp /etc/apt/sources.list /etc/apt/sources.list.orig
> /etc/apt/sources.list
apt-get update
apt-get clean
cp /etc/apt/sources.list.orig /etc/apt/sources.list
echo -e "Zrobione!" | tee -a $LOG_FILE

#
# Koniec przygotowan
#

#
# Tworzenie drzewa zawartosci CD
#
make_squash(){
    # Tworzymy potrzebne katalogi
    if [ ! -d $DIR ]; then
	mkdir $DIR
    fi
    cd /
    # cramfs
    echo -en "Tworzê skompresowany systemu plików... " | tee -a $LOG_FILE
    echo 
    mksquashfs /bin  /boot  /dev  /etc  /home  /lib  /root  /sbin  /usr  /var $DIR/cdlinux.pl.img -no-progress
    echo -e "Zrobione!" | tee -a $LOG_FILE
    echo -en "Tworzê /isolinux... " | tee -a $LOG_FILE
    cp -dpR /isolinux $DIR 2>> $LOG_FILE
    echo -e "Zrobione!" | tee -a $LOG_FILE

}


make_squash

# Tworzenie obrazu plyty
echo -en "Tworzê obraz: \n $DEST ... " | tee -a $LOG_FILE
mkisofs -zR -o $DEST -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table $DIR 2>> $LOG_FILE
echo -e "Zrobione!" | tee -a $LOG_FILE
echo -e "Operacja zakoñczona!" | tee -a $LOG_FILE
