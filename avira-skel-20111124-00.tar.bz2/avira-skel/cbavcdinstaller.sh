#!/bin/bash
# encoding: utf-8

# Copyright: Mattias Schlenker 2010
# License:   GPL v2, v3, BSD, MIT, X11 - whichever suits your needs

copysource=""
if [ -d "/lesslinux/cdrom/lesslinux" ] ; then 
	copysource="/lesslinux/cdrom"
elif [ -d "/lesslinux/toram/lesslinux" ] ; then
	copysource="/lesslinux/toram"
elif [ -d "/lesslinux/isoloop/lesslinux" ] ; then
	copysource="/lesslinux/isoloop"
fi
if [ -z "$copysource" ] ; then
	echo '***> '"Quellordner nicht gefunden, Installation nicht möglich"'!'
	exit 1
fi

installtarget="$1"

umount "${installtarget}" > /dev/null 2>&1
for i in 1 2 3 4 5 6 7 8 9 ; do
	umount "${installtarget}${i}" > /dev/null 2>&1
done

if cat /proc/mounts | awk '{print $1}' | grep -q "${installtarget}" ; then
	echo '***> '"Das gewählte Ziellaufwerk befindet sich noch im Zugriff"
	echo '     '"Installation nicht möglich"'!'
	exit 1
fi

echo "===> Lösche USB-Laufwerk"
dd if=/dev/zero bs=1048576 count=4 of=${installtarget}

echo "===> Schreibe Bootsektor"
# dd if=/usr/share/syslinux/mbr.bin of=${installtarget}
dd if=/etc/lesslinux/mbr384.dd of=${installtarget}
mdev -s

echo "===> Erstelle Dateisystem"
# mkfs.msdos -F32 "${installtarget}1"
mdev -s
devicesize=` parted -sm ${installtarget} unit B print | head -n2 | tail -n1 | awk -F ':' '{print $2}' | sed 's/B//' `
partstart=` parted -sm ${installtarget} unit B print | tail -n1 | awk -F ':' '{print $2}'  | sed 's/B//' `
partend=` parted -sm ${installtarget} unit B print | tail -n1 | awk -F ':' '{print $3}'  | sed 's/B//' ` 
calcend=` expr $devicesize - 16777217 ` 
# calculate end of first partition, beginning of second partition
firstend=` expr $devicesize - 150994945 `
secondstart=` expr $devicesize - 150994944 `

# echo parted -s ${installtarget} unit B resize 1 $partstart $calcend
# parted -s ${installtarget} unit B resize 1 $partstart $calcend
parted -s ${installtarget} unit B rm 1
parted -s ${installtarget} unit B mkpart primary fat32 $partstart $firstend
parted -s ${installtarget} unit B set 1 lba  on
parted -s ${installtarget} unit B mkpart primary ext2 $secondstart $calcend
parted -s ${installtarget} unit B set 2 boot on

sleep 2
partprobe ${installtarget}
mdev -s
sleep 2
mkfs.msdos -F32 "${installtarget}1"
mkfs.ext3 "${installtarget}2"

echo "===> Kopiere Bootdateien und schreibe Bootloader"
mkdir /lesslinux/install_target > /dev/null 2>&1
mount -t ext3 ${installtarget}2 /lesslinux/install_target
tar -C "${copysource}" -cvf - boot | tar -C /lesslinux/install_target -xf -
extlinux --install /lesslinux/install_target/boot/isolinux
umount /lesslinux/install_target
mount -t vfat ${installtarget}1 /lesslinux/install_target

echo "===> Kopiere Systemdateien"
tar -C "${copysource}" -cvf - lesslinux | tar -C /lesslinux/install_target -xf -
echo "===> Kopiere Virensignaturen"
tar -C "${copysource}" -cvf - avupdate | tar -C /lesslinux/install_target -xf -
tar -C "${copysource}" -cvf - avupdate.bat liesmich.html pdf GPL.txt haftung.txt lizenzen | tar -C /lesslinux/install_target -xf -
mkdir /lesslinux/install_target/antivir
tar -C /AntiVir -cvf - . | tar -C /lesslinux/install_target/antivir -xf -
echo "===> Erstelle Auslagerungsdatei - dieser Vorgang kann bis zu 15 Minuten dauern"
freespace=` df -k | grep /lesslinux/install_target | awk '{print $4}' ` 
if [ "$freespace" -gt 524288 ] && [ "$freespace" -lt 1835008 ] ; then
	count=$(( $freespace / 1024 - 256 ))
	dd if=/dev/zero bs=1M count=$count of=/lesslinux/install_target/antivir/swap.img
elif [ "$freespace" -gt 1835007 ] ; then
	count=1536
	dd if=/dev/zero bs=1M count=$count of=/lesslinux/install_target/antivir/swap.img
else
	echo 'Nicht genügend Platz für Auslagerungsspeicher...'
fi
echo "===> Schließe die Installation ab - Bitte etwas Geduld"
umount "${installtarget}1"
echo "===> Fertig"'!'
