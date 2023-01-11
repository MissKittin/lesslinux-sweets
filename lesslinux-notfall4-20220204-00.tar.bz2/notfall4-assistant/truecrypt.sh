#!/bin/bash
# encoding: utf-8

zenity --info --text 'Achtung! Dieses Programm wird seit Mitte 2014 nicht weiterentwickelt und könnte Sicherheitslücken enthalten.\n\nSie sollten TrueCrypt daher nicht mehr zur Daten-Verschlüsselung einsetzen, können damit aber bestehende Container-Dateien öffnen.'
exec /usr/bin/truecrypt
