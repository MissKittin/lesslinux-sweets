#!/bin/bash

batt_state=`cat /proc/acip/battery/BAT1/state | grep 'charging state' | awk '{print $3}' `   
if [ $batt_state = "discharging" ] ; then
	zenity --warning --text "Bitte stecken Sie Ihr Notebook an die Stromversorgung an, bevor Sie mit der Arbeit mit der Notfall-CD beginnen!" 
fi