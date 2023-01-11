#!/bin/bash
# encoding: utf-8

if [ -d /sys/class/power_supply/BAT0 ] ; then
	status="Entlädt"
	if grep "Charging" /sys/class/power_supply/BAT0/status ; then
		status="Lädt"
	elif grep "Unknown" /sys/class/power_supply/BAT0/status ; then
		status="Unbekannt"
	fi
	percentage="???"
	if [ -f /sys/class/power_supply/BAT0/capacity ] ; then
		percentage=` cat /sys/class/power_supply/BAT0/capacity `
	fi
	echo "${status}, ${percentage}%"  
else 
	echo "Keine Informationen verfügbar"
fi
