#!/bin/sh
# Author           : Michal Wrobel ( wrobel@task.gda.pl )
# Created On       : 2005.01.01
# Last Modified By : Michal Wrobel ( wrobel@task.gda.pl )
# Last Modified On : 2005.05.11
# Version          : 0.1.1
#
# Description      :
# Program wyszukuj±cy inne systemy operacyjne, aby dodaæ je lilo
#
# Licensed under GPL (see /usr/share/common-licenses/GPL for more details
# or contact # the Free Software Foundation for a copy)



DISKSDIR="/media/dyski"
WINFILE="/tmp/lilo.windows.part.$$"

CHECK=""
NOTMOUNT=""
WINCOUNT=1

for LS in `ls $DISKSDIR`; do 
	if [ -e $DISKSDIR/$LS/ls ]; then
		WIN=`grep -i "win" $DISKSDIR/$LS/ls`
		if [ "$WIN" ]; then
			echo -en "other=/dev/$LS\n\tlabel=win$WINCOUNT\n" >> $WINFILE
			WINCOUNT=$(($WINCOUNT+1))
		fi

		ETC=`grep -E "^etc/" $DISKSDIR/$LS/ls`
		if [ "$ETC" ]; then
			CHECK="$DISKSDIR/$LS $CHECK"
			NOTMOUNT="$LS $NOTMOUNT"
			mount $DISKSDIR/$LS
		fi

		BOOT=`grep -E "^boot/" $DISKSDIR/$LS/ls`
		if [ "$BOOT" ]; then
			CHECK="$DISKSDIR/$LS $CHECK"
			NOTMOUNT="$LS $NOTMOUNT"
			mount $DISKSDIR/$LS
		fi
	else
		WIN=`ls -1 $DISKSDIR/$LS | grep -i "win"`
		if [ "$WIN" ]; then
			echo -en "other=/dev/$LS\n\tlabel=win$WINCOUNT\n" >> $WINFILE
			WINCOUNT=$(($WINCOUNT+1))
		fi
		
		ETC=`ls -1 $DISKSDIR/$LS | grep -E "^etc$" `
		if [ "$ETC" ]; then
			CHECK="$DISKSDIR/$LS $CHECK"
		fi

		BOOT=`ls -1 $DISKSDIR/$LS | grep -E "^boot$" `
		if [ "$BOOT" ]; then
			CHECK="$DISKSDIR/$LS $CHECK"
		fi

	fi
done

cdlcenter-bootloader.pl $CHECK $WINFILE

#for UMOUNT in $NOTMOUNT; do
#	umount $DISKSDIR/$UMOUNT
#done

rm $WINFILE
