#!/bin/bash
# Name             : Instalator cdlinux.pl
# Author           : Maciej Kosmulski ( barnim@tmc.gda.pl )
# Created On       : 2003.06.29
# Last Modified By : Michal Wrobel ( wrobel@task.gda.pl )
# Last Modified On : 2005.01.24
# Version          : 0.8.0
#
# Description      :
# Program do instalacji systemu cdlinux.pl na dysku twardym.
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)

TITLE="Instalator cdlinux.pl na dysku twardym"
MNTPLC="/media/dyski"
KERNEL=`uname -r`
CDDIR="/mnt/cdrom"
LOG="/var/log/cdlcenter-hdinstall.log"
DEVICEMAP="/tmp/tmp2/boot/grub/device.map"

# tymczasowy katalog do podmontowania partycji na ktorej ma byc instalowany system
TMPMNT=/tmp/tmp2

if [ -n "`grep ma³y /etc/cdlcenter/wersja`" ]; then 
	kimjestem="maly" 
else
	kimjestem="duzy" 
fi
	

partId (){
	dysk_id=`echo $partycja | tr [:digit:] " "`
	dysk_id=`grep $dysk_id $DEVICEMAP | cut -f 1`
	part_id=`echo $partycja | sed "s#[^0-9]*\(.*\)#\1#"`
	part_id=$(($part_id-1))
	part_id=`echo $dysk_id | sed "s#)#,$part_id)#"`
}

# tworzy plik do wyliczania procent dla wersji maly
cat <<'EOF' > /tmp/procenty-maly
#!/bin/bash
wynik=0
#liczba plikow w dystrybucji:
ilemabyc=38507
while [ $wynik -le 100 ] ; do
    sleep 4
    ilejest=`find /tmp/tmp2 | wc -l`
    let wynik=ilejest*100/ilemabyc
    if [ $wynik -ge 100 ] ; then
	wynik=100
	echo $wynik
	exit 0
    fi
    echo $wynik
done
EOF
chmod +x /tmp/procenty-maly

# tworzy plik do wyliczania procent dla wersji duzy
cat <<'EOF' > /tmp/procenty-duzy
#!/bin/bash
wynik=0
#liczba plikow w dystrybucji:
ilemabyc=84721
while [ $wynik -le 100 ] ; do
    sleep 4
    ilejest=`find /tmp/tmp2 | wc -l`
    let wynik=ilejest*100/ilemabyc
    if [ $wynik -ge 100 ] ; then
	wynik=100
	echo $wynik
	exit 0
    fi
    echo $wynik
done
EOF
chmod +x /tmp/procenty-duzy

# tworzy plik do kopiowania dysków dla wersji maly
cat <<EOF > /tmp/kopiuj
#!/bin/bash
mkdir $TMPMNT/sys >>$LOG 2>>$LOG
cd $TMPMNT >>$LOG 2>>$LOG
cp -dpR /bin $TMPMNT >>$LOG 2>>$LOG
cp -dpR /boot $TMPMNT >>$LOG 2>>$LOG
cp -dpR /dev $TMPMNT >>$LOG 2>>$LOG
cp -dpR /etc $TMPMNT >>$LOG 2>>$LOG
cp -dpR /home $TMPMNT >>$LOG 2>>$LOG
cp -dpR $CDDIR/isolinux $TMPMNT >>$LOG 2>>$LOG
cp -dpR /lib $TMPMNT >>$LOG 2>>$LOG
cp -dpR /root $TMPMNT >>$LOG 2>>$LOG
cp -dpR /sbin $TMPMNT  >>$LOG 2>>$LOG
cp -dpR /usr $TMPMNT >>$LOG 2>>$LOG
cp -dpR /var $TMPMNT >>$LOG 2>>$LOG
cp -dpRx /mnt $TMPMNT >>$LOG 2>>$LOG
cp -dpRx /media $TMPMNT >>$LOG 2>>$LOG

cp /bin/colrm $TMPMNT/bin >>$LOG 2>>$LOG
EOF
chmod +x /tmp/kopiuj


function helpme {
    echo -e "Sk³adnia: cdlcenter-hdinstall.sh [OPCJE]"
    echo -e "Program instaluje dystrybucjê cdlinux.pl z p³yty CD na dysk twardy"
    echo -e "\nObowi±zkowe opcje:"
    echo -e "  -p PATH \t gdzie PATH to nazwa pliku urz±dzenia partycji, na której\n ma zostaæ zainstalowany system (np. /dev/hda6)"
    echo -e "  -f FS \t gdzie FS okre¶la system plików, jaki ma zostaæ utworzony\n na partycji (dostêpne ext2 lub ext3)"
    echo -e "  -m DYSK \t dysk w którego sektorze MBR zostanie zainstalowane LILO"
    echo -e "\nDodatkowe opcje:"
    echo -e "  -l \t\t po instalacji uruchamia lilo"
    echo -e "  -r \t\t po instalacji uruchamia ponownie komputer"
    echo -e "  -g \t\t instalacja w trybie graficznym (o ile to mo¿liwe)"
    exit 0
}

while getopts m:p:f:hlrg WYBOR 2>/dev/null
    do
	case $WYBOR in
	    p) partycja=$OPTARG;;
	    f) fs=$OPTARG;;
	    m) MBR=$OPTARG;;
	    l) LILO="YES";;
	    r) REBOOT="YES";;
	    g) GUI="YES";;
	    h) helpme;;
	    ?) echo -e "Nieznana opcja! Napisz cdlcenter-hdinstall.sh -h aby uzyskaæ pomoc" ; exit;;
	    *) echo -e "Brak opcji! Napisz cdlcenter-hdinstall.sh -h aby uzyskaæ pomoc"
	esac	
    done

# upewniamy siê ;)
if [ "$UID" != 0 ] ; then
    echo -e "Musisz byæ superu¿ytkownikiem (root), aby uruchomiæ ten skrypt!"
    exit 0;
fi

if [ "$GUI" == "YES" ] ; then
    if [ "$DISPLAY" == "" ] ; then
	DIALOG="/usr/bin/dialog --aspect 60 --ok-label "Tak" --cancel-label "Nie" "
    else
        DIALOG="/usr/bin/Xdialog --ok-label "Tak" --cancel-label "Nie" "
    fi
fi

# sprawdzamy czy jest plyta i w ktorym napedzie 

if [ -f $CDDIR/cdlinux.pl.img ] ; then
        CDFOUND=0
else
	if [ "$GUI" == "YES" ] ; then	
		$DIALOG --title  "UWAGA!!!" \
		--no-cancel --ok-label "OK" --backtitle "$TITLE" \
		--infobox "Instalacja na dysk twardy jest mo¿liwa przy starcie z p³yty." 0 0
	fi
fi

# sprawdzamy czy partycja na ktorej chcemy instalowac jest zamontowana
# jesli tak, to odmontowujemy (bo wcale nie musi byc w /media/dyski)
mntcheck=`mount | grep $partycja`
if [ -n "$mntcheck" ] ; then
    if [ !`umount $partycja` ] ; then
	echo -e "B³±d przy odmontowywaniu partycji $partycja"
	echo -e "\nPonowienie instalacji powinno pomóc :-)"
	exit 1
    fi 
fi

if [ "$GUI" == "YES" ] ; then
    /tmp/procenty-$kimjestem | $DIALOG --title "$TITLE" --backtitle "$TITLE" --gauge "Kopiowanie plików na twardy dysk, proszê czekaæ..." 8 60 0 & 
    mkfs.$fs $partycja >> $LOG 2>&1
    mkdir $TMPMNT 2>/dev/null
    mount $partycja $TMPMNT/

   # Kopiowanie plikow na dysk twardy
    mkdir $TMPMNT/tmp
    mkdir $TMPMNT/proc
    /tmp/kopiuj
    kill $!
else
    echo -e "Tworzenie systemu plików na partycji: $partycja\n"
    mkfs.$fs $partycja
    mkdir $TMPMNT 2>/dev/null
    mount $partycja $TMPMNT/

   # Kopiowanie plikow na dysk twardy
    mkdir $TMPMNT/tmp
    mkdir $TMPMNT/proc
    echo -e "Kopiowanie plików na twardy dysk, proszê czekaæ..."
    /tmp/kopiuj
fi

chmod a+wxt $TMPMNT/tmp
chmod 555 $TMPMNT/proc

#####################################
# kasowanie join
#####################################
rm -df $TMPMNT/etc/rcS.d/*join
mv $TMPMNT/etc/init.d/join.new $TMPMNT/etc/init.d/join

####################################### 
# kasowanie reboot i tworzenie nowego # 
####################################### 
rm -df $TMPMNT/etc/init.d/reboot
cat <<EOF > $TMPMNT/etc/init.d/reboot 
#! /bin/sh 
# 
# reboot        Execute the reboot command. 
# 
# Version:      @(#)reboot  2.75  22-Jun-1998  miquels@cistron.nl 
# 
PATH=/sbin:/bin:/usr/sbin:/usr/bin 
echo -n "Ponowne uruchamianie komputera, proszê czekaæ... " 
reboot -d -f -i 
EOF
chmod 755 $TMPMNT/etc/init.d/reboot

################# 
# wpis do fstab # 
################# 
cat <<EOF > $TMPMNT/etc/fstab 
# /etc/fstab: statyczna informacja o systemach plikow. 
# 
# <system plikow>       <punkt montowania>      <typ>   <opcje>         <dump>  <pass> 
$partycja       /               $fs     errors=remount-ro               0       1 
proc            /proc           proc    defaults                        0       0 
none           /sys             sysfs    defaults                        0       0 
/dev/fd0        /media/floppy             auto    user,noauto             0       0 
EOF

grep swap /etc/fstab >> $TMPMNT/etc/fstab
grep cdrom /etc/fstab >> $TMPMNT/etc/fstab
grep dyski /etc/fstab | grep -v "$partycja" >> $TMPMNT/etc/fstab

#cdlcenter-findlilo.sh >> /tmp/lilo.conf
#cat /tmp/lilo.conf | sed "s/\/tmp\/tmp2//" > $TMPMNT/etc/lilo.conf
mv /etc/fstab /tmp/fstab.$$
cp $TMPMNT/etc/fstab /etc/
mkdir $TMPMNT/boot/grub

mkinitrd.yaird -o $TMPMNT/boot/initrd.img-$KERNEL $KERNEL
mv /tmp/fstab.$$ /etc/fstab

if [ "$LILO" = "YES" ] ; then
	grub-install --root-directory=/tmp/tmp2 $MBR >>$LOG 2>> $LOG

	dysk=`echo $partycja | tr [:digit:] " "` 
	partId

	cat <<EOF > $TMPMNT/boot/grub/menu.lst
default=0
timeout=10
splashimage=$part_id/boot/cdlinux-bootsplash.xpm.gz

title cdlinux.pl
root $part_id
kernel /boot/vmlinuz-$KERNEL
initrd /boot/initrd.img-$KERNEL	

EOF

	if [ "$GUI" == "YES" ] ; then
		$DIALOG --backtitle "Konfiguracja GRUB!" --title "$TITLE" --yesno "Czy wyszukaæ inne systemy operacyjne?" 0 0
	fi

	if [ $? -eq 0 ] ; then
		cdlcenter-bootloader.pl >> $TMPMNT/boot/grub/menu.lst
	fi

	if [ "$GUI" == "YES" ] ; then
		$DIALOG --backtitle "Konfiguracja GRUB!" --title "$TITLE" --yesno "Czy wy¶wietliæ menu programu GRUB??" 0 0
		if [ $? -eq 0 ] ; then
			if [ "$DISPLAY" == "" ] ; then
				editor $TMPMNT/boot/grub/menu.lst
			else
				leafpad $TMPMNT/boot/grub/menu.lst
			fi
		fi
	fi


	# po odpaleniu lilo odmontowuje dyski
	cd /media/dyski
	for part in *
	do
	    umount /dev/$part 2>/dev/null
	done
else
	grub-install --root-directory=/tmp/tmp2 $partycja >>$LOG 2>> $LOG

	dysk=`echo $partycja | tr [:digit:] " "` 
	partId

	cat <<EOF > $TMPMNT/boot/grub/menu.lst
default=0
timeout=10
splashimage=$part_id/boot/cdlinux-bootsplash.xpm.gz

title cdlinux.pl
root $part_id
kernel /boot/vmlinuz-$KERNEL
initrd /boot/initrd.img-$KERNEL	

EOF

fi

cd /
umount $TMPMNT >/dev/null 2>&1

if [ "$GUI" == "YES" ] ; then
    $DIALOG --title "UWAGA !!!" --ok-label "OK!" \
	--backtitle "$TITLE" \
    	--msgbox "INSTALACJA ZOSTA£A ZAKOÑCZONA POMY¦LNIE!!!" 0 0 
    else
	echo -e "\nINSTALACJA ZOSTA£A ZAKOÑCZONA POMY¦LNIE!!!"
fi


if [ "$REBOOT" = "YES" ] ; then
	reboot
else
    if [ "$GUI" == "YES" ] ; then
	$DIALOG --title "UWAGA !!!" --ok-label "OK!" \
	    --backtitle "$TITLE" \
    	    --msgbox "Teraz mo¿esz ponownie uruchomiæ komputer!" 0 0 
	else
	    echo -e "\nTeraz mo¿esz ponownie uruchomiæ komputer!\n"
    fi
fi

#clear
exit 0
