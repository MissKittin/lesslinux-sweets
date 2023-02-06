#!/bin/bash
# encoding: utf-8

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams

start_short='Start SSH daemon'
start_long='The SSH daemon is not running in the moment. Do you want to start it now to make this system accessible with WinSCP or Putty?'
started_short='SSHD started'
started_long='SSHD was started successfully.\n\nIf you did not yet set a password, open a root shell and enter the command "passwd surfer" to set the password. After this, you can use WinSCP, Putty or FileZilla to log on to this machine as user "surfer"'
stop_short='Stop SSH daemon'
stop_long='The SSH daemon is active in the moment. Do you want to stop it and terminate all active connections?'
stopped_short='SSHD stopped'
stopped_long='The SSH daemon was stopped.'

if [ "$lang" = "de" ] ; then
	start_short='SSH Daemon starten'
	start_long='Der SSH-Daemon ist nicht aktiv. Wollen Sie ihn starten und so Zugriff auf dieses System mit WinSCP oder Putty erlauben?'
	started_short='SSHD gestartet'
	started_long='SSHD wurde erfolgreich gestartet!\n\nFalls Sie noch kein Passwort für den Zugriff gesetzt haben, öffnen Sie eine Rootshell und verwenden Sie dort den Befehl "passwd surfer" um ein Passwort zu vergeben. Anschließend können Sie sich per SSH oder SCP (WinSCP liegt auf CD bei) mit dem Nutzernamen "surfer" an diesem Rechner einloggen.'
	stop_short='SSH Daemon stoppen'
	stop_long='Der SSH-Daemon ist momentan aktiv. Wollen Sie ihn stoppen und so möglicherweise alle aktiven Zugriffe trennen?'
	stopped_short='SSHD gestoppt'
	stopped_long='Der SSH-Daemon wurde gestoppt!'
elif [ "$lang" = "pl" ] ; then
	start_short='Uruchom demona SSH'
	start_long='Demon SSH w tej chwili nie działa. Czy chcesz go uruchomić, aby umożliwić dostęp do tego komputera przy pomocy WinSCP lub Putty?'
	started_short='SSHD uruchomiony'
	started_long='SSHD został pomyślnie uruchomiony.\n\nJeśli jeszcze nie ustawiłeś hasła, otwórz powłokę roota i wpisz polecenie "passwd surfer" w celu ustawienia hasła. Natępnie możesz użyć programów WinSCP, Putty lub FileZilla aby zalogować się na tym komputerze jako użytkownik "surfer"'
	stop_short='Zatrzymaj demona SSH'
	stop_long='Demon SSH w tej chwili działa. Czy chcesz go zatrzymać i zakończyć wszystkie aktywne połączenia?'
	stopped_short='SSHD zatrzymany'
	stopped_long='Demon SSH został zatrzymany.'
fi


if pidof sshd ; then
	zenity --question --title "$stop_short" --text "$stop_long" && sudo /etc/rc.d/0600-openssh.sh stop && zenity --info --title "$stopped_short" --text "$stopped_long"
else
	zenity --question --title "$start_short" --text "$start_long" && sudo /etc/rc.d/0600-openssh.sh start && zenity --info --title "$started_short" --text "$started_long"
fi
