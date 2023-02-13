#!/usr/bin/ruby
# encoding: utf-8

require 'gtk2'
require 'vte'
require "rexml/document"
require 'retrieveDriveDetails'
require 'screenStartCheck' 
require 'screenSelectInitial'
require 'functionsSmart'
require 'functionsClone'
require 'functionsClean'
require 'functionsChntpw'
require 'functionsPhotorec'
require 'functionsVirus'
require 'optparse'
require 'functionsLanguage'

@simulate = Array.new
@deco = true
opts = OptionParser.new 
opts.on('-s', '--simulate', :REQUIRED ) { |i| i.split(",").each { |j| @simulate.push(j) } }
opts.on('--no-deco') { @deco = false } 
opts.parse!

@virus_scanner = "clamav"
@virus_scanner = "kaspersky" if system("test -x /opt/kaspersky/kav4ws/bin/kav4ws-kavscanner")

LANGUAGE = ENV['LANGUAGE'][0..1]
LOCSTRINGS = {
	"de" => {
		"win_title" => "NotfallDreinull",
		"back" => "Zurück",
		"forw" => "Weiter",
		"cancel" => "Abbrechen",
		"reboot" => "Neu starten",
		"reread" => "Neu einlesen",
		"details" => "Details anzeigen",
		"header_image" => "NotfallCD30.png",
		"missing_log" => "Protokolldatei fehlt - mögliche Ursache: Abbruch des Virenscans",
		"discharging" => "Bitte schließen Sie ein Ladegerät an Ihr Notebook an! Falls Sie kein Ladegerät anschließen, besteht im Falle eines leeren Akkus das Risiko von Datenverlust.",
		 "lowmemory" => "Ihr Computer verfügt über weniger als 768MB Arbeitsspeicher. Ein USB-Stick oder eine SD-Karte als Auslagerungsspeicher ist zwingend erforderlich! Bitte schließen Sie einen USB-Stick an, klicken Sie auf \"Neu einlesen\" und wählen Sie dann den Stick aus, der benutzt werden soll.",
		"smart_aborting" => "Der Selbsttest wird abgebrochen",
		"select_title" => "Welches Problem haben Sie?",
		"select_one" => "Windows startet nicht oder stürzt ab",
		"select_two" => "Wichtige Dateien wurden versehentlich gelöscht",
		"select_three" => "Ich habe mein Windows-Passwort vergessen",
		"select_four" => "Ich habe den Verdacht, dass mein Computer einen Virus hat",
		"select_five" => "Ich muss Windows neu installieren oder will meinen Computer verkaufen",
		"select_six" => "Ich muss möglichst schnell meine Daten sichern oder möchte eine Sicherung zurückspielen" ,
		"wlan_not_found" => "Es wurde keine nutzbare WLAN-Schnittstelle gefunden. Die Virenprüfung findet ohne Signaturupdate statt.",
		"wlan_connecting" => "Stelle WLAN-Verbindung her...",
		"clean_partition_select" => "Wählen Sie hier die Partition aus, auf der sich Windows befindet. Die anderen Partitionen sollten Sie nicht auswählen, da sonst persönliche Dateien und Sicherungen verloren gehen könnten. Klicken Sie auf \"Weiter\".",
		"clean_drive_select" => "Wählen Sie hier den Datenträger aus, den Sie löschen möchten. Alle Daten darauf werden unwiederbringlich vernichtet. Klicken Sie auf \"Weiter\".",
		"clean_fast" => "Klicken Sie hier, um die Festplatte für eine frische Windows-Installation optimal vorzubereiten.",
		"clean_good" => "Klicken Sie hier, falls Sie den Computer verkaufen wollen und die Inhalte der Festplatte sicher löschen möchten.",
		"clean_select_part" => "Auswahl der Laufwerke",
		"clean_part_desc" => "Wählen Sie hier die Partition aus, auf der sich Windows befindet. Die anderen Partitionen sollten Sie nicht auswählen, da sonst persönliche Dateien und Sicherungen verloren gehen könnten. Klicken Sie dann auf \"Weiter\".",
		"clean_progress_head" => "Löschen von Datenträgern",
		"clean_done_head" => "Löschen abgeschlossen",
		"clean_done_desc" => "Das Löschen der gewählten Laufwerke ist abgeschlossen. Klicken Sie auf \"Neu starten\", um Ihren Computer neu zu starten.",
		"clean_no_selection" => "Bitte Laufwerke zum Löschen auswählen!",
		"clean_fast_message" => "Die Schnellöschung wird einige Minuten dauern. Nach der Schnelllöschung ist es meist möglich, Teile der überschriebenen Daten wieder herzustellen. Verwenden Sie die Schnelllöschung daher nicht, wenn Sie einen Computer weitergeben möchten.",
		"clean_good_message" => "Die sichere Löschung wird einige Stunden dauern. Nach der sicheren Löschung ist es nach heutigem Stand der Technik unmöglich, die überschriebenen Daten wiederherzustellen. Klicken Sie auf \"OK\", wenn Sie die ausgewählten Laufwerke unwiederbringlich löschen wollen.",
		"clean_no_clean" => "Keine Löschung",
		"clean_done" => "Löschung abgeschlossen",
		"clone_header" => "Ich möchte eine Festplatte kopieren oder eine Sicherung zurückspielen",
		"clone_desc" => "Mit dieser Funktion lässt sich eine gesamte Festplatte Eins zu Eins auf eine zweite Festplatte kopieren oder zurückspielen. Auf diese Weise können Sie zum Beispiel mit Windows und allen Programmen auf eine neue Festplatte umziehen.",
		"clone_desc2" => "Wählen Sie jetzt zunächst die Quelle aus. Falls es sich um ein externes Laufwerk handelt, schließen Sie es jetzt an, und klicken Sie auf \"Neu einlesen\". Anschließend wählen Sie das Laufwerk nach einem Klick auf den Pfeil aus.",
		"clone_tgt_head" => "Auswahl des Ziellaufwerks",
		"clone_tgt_desc" => "Wählen Sie jetzt das Ziellaufwerk aus. Falls es sich um ein externes Laufwerk handelt, schließen Sie es jetzt an, und klicken Sie auf \"Neu einlesen\". Anschließend wählen Sie das Laufwerk nach einem Klick auf den Pfeil aus.",
		"clone_tgt_warn" => "Achtung: Alle Dateien auf dem Ziellaufwerk gehen verloren. Außerdem muss es mindestens so groß sein wie das Quelllaufwerk.",
		"clone_progress_head" => "Klonen einer Festplatte",
		"clone_progress_warn" => "Je nach Größe der Festplatte kann der Klonvorgang mehrere Stunden dauern. Bitte brechen Sie ihn nicht ab.",
		"clone_in_progress" => "Klonen läuft...", 
		"clone_finished" => "Klonen abgeschlossen",
		"clone_fin_desc" => "Die Festplatte wurde erfolgreich kopiert. Entfernen Sie nun das Ziel-Laufwerk mit der Komplett-Sicherung, und verwahren Sie es an einem sicheren Ort. Falls Sie eine Komplett-Sicherung zurückgespielt haben, klicken Sie auf „Neu starten“, um Windows zu starten.",
		"clone_further" => "Falls Sie eine Komplett-Sicherung erstellt haben, gibt es zwei Möglichkeiten:\n\n1. Ist Windows beschädigt, kehren Sie zum Hauptmenü zurück und klicken auf \"Windows startet nicht oder stürzt ab\".\n\n2. Ist die Festplatte beschädigt, tauschen Sie sie nun aus. Starten Sie danach die Notfall-CD, um die Komplett-Sicherung zurückzuspielen. Diesmal wählen Sie die Festplatte mit der Sicherung als Quell- und die neue Festplatte als Ziel-Laufwerk. Eine Anleitung zum Festplattentausch finden Sie hier:",
		"clone_show_manual" => "Anleitung Festplattentausch anzeigen",
		"clone_manual_path" => "/lesslinux/cdrom/Anleitungen/Festplattentausch.pdf", 
		"clone_error_read" => "Es ist ein Fehler beim Einlesen der Laufwerke aufgetreten. Bitte gehen Sie zurück und starten Sie diese Aufgabe erneut.",
		"clone_warn_noparts" => "Das Quelllaufwerk enthält keine Partitionstabelle und ist größer als das Ziellaufwerk - es ist möglich, dass beim Kopieren Daten verloren gehen.",
		"clone_warn_bigger" => "Die letzte Partition des Quellaufwerkes liegt hinter dem Ende des Ziellaufwerkes. Es ist möglich, dass beim Kopieren Daten dieser Partition verloren gehen. Wir empfehlen, das Klonen abzubrechen und die letzte Partition des Quelllaufwerkes zunächst zu verkleinern.",
		"clone_warn_destroy" => "Wenn Sie auf \"OK\" klicken, werden alle Daten auf dem Ziellaufwerk überschrieben. Klicken Sie auf \"Abbrechen\" um zurück zur Laufwerksauswahl zu gelangen.",
		"restore_select_source" => "Auf welchem Laufwerk wollen Sie nach den verlorenen Daten suchen? Falls sich diese Daten auf einem externen Laufwerk befanden, schließen Sie dieses jetzt an und klicken auf \"Neu einlesen\". Anschließend wählen Sie das Laufwerk nach einem Klick auf den Pfeil aus. Das gesamte Laufwerk wird durchsucht.",
		"restore_types_head" => "Auswahl der Dateitypen",
		"restore_types_desc" => "Nach welchen Dateitypen soll gesucht werden?",
		"restore_types_office" => "Office-Dokumente (auch OpenOffice, PDF und RTF)",
		"restore_types_image" => "Fotos und Bilder",
		"restore_types_video" => "Videos",
		"restore_types_music" => "Musik",
		"restore_types_mbox" => "Email-Postfächer (beispielsweise von Outlook)",
		"restore_types_arch" => "Gepackte Dateien (.zip, .rar, .7z, .iso)",
		"restore_types_every" => "alle wiederherstellbaren Dateien",
		"restore_tgt_head" => "Auswahl des Ziellaufwerkes",
		"restore_tgt_desc" => "Auf welchem Laufwerk sollen die gefundenen Dateien gespeichert werden? Da alle zu Ihrer Auswahl passenden Dateien wiederhergestellt werden, wird die Datenmenge möglicherweise sehr groß. Das Ziellaufwerk sollte daher über ausreichend Speicherplatz verfügen.",
		"restore_tgt_desc2" => "Beachten Sie, dass Quell- und Ziellaufwerk nicht gleich sein dürfen. Das Quelllaufwerk wird deshalb an dieser Stelle nicht angezeigt.",
		"restore_tgt_desc3" => "Falls Sie die Daten auf einem externen Laufwerk wiederherstellen möchten, schließen Sie es jetzt an, und klicken Sie auf \"Neu einlesen\". Anschließend wählen Sie das Laufwerk nach einem Klick auf den Pfeil aus.",
		"restore_prog_head" => "Suche nach Dateien", 
		"restore_no_types" => "Bitte Dateitypen zur Suche auswählen!",
		"restore_no_target" => "Kein Ziellaufwerk angegeben! Bitte schließen Sie ein Laufwerk an und drücken Sie dann den Knopf \"Neu einlesen\".",
		"restore_running" => "Wiederherstellung läuft", 
		"restore_count" => "%COUNT% Dateien wiederhergestellt", 
		"restore_finished_head" => "Dateien wiederhergestellt",
		"restore_finished_desc" => "Die Wiederherstellung der Dateien ist abgeschlossen. Sie finden Ihre Daten nun auf dem Ziellaufwerk in fortlaufend nummerierten Ordnern \"Recovery\".",
		"restore_space_warn" => "Der Platz auf dem Ziellaufwerk reicht nicht aus. Sie können ein weiteres USB-Laufwerk anschließen, auf welches dann Daten umkopiert werden. Klicken Sie anschließend auf \"OK\". Klicken Sie auf \"Abbrechen\", wenn Sie den Suchlauf abbrechen möchten.",
		"restore_new_target" => "Wählen Sie das Laufwerk, auf welches Daten umkopiert werden sollen. Es werden nur Laufwerke mit wenigstens 1GB freiem Speicher angezeigt.",
		"restore_all_warn" => "Wenn Sie keine Auswahl treffen, sucht PhotoRec nach allen ihm bekannten Dateitypen, auch nicht in der Liste verzeichnete. Dies benötigt viel Platz auf dem Ziellaufwerk und erschwert die spätere Sortierung. Klicken auf \"OK\", um nach allen Dateitypen zu suchen oder auf \"Abbrechen\", um zur Auswahl zurückzukehren.",
		"restore_tgt_combo" => "%VENDOR% %MODEL% %DEVICE% %ATTACHED% Partition: %PART%%LABEL% Frei %FREESPACE%",
		"chntpw_win_select" => "Von welcher Windows-Installation soll die Passwort-Datei bearbeitet werden?",
		"chntpw_user_head" => "Auswahl des Benutzerkontos",
		"chntpw_user_select" =>   "Wählen Sie das Benutzerkonto aus, dessen Passwort zurückgesetzt werden soll. Nach dem Zurücksetzen des Passwortes können Sie sich ohne Passworteingabe anmelden.",
		"chntpw_not_found" => "Keine Windows-Installation gefunden",
		"chntpw_success_title" => "Windows-Passwort zurückgesetzt",
		"chntpw_success_long" => "Ihr Windows-Passwort wurde erfolgreich zurückgesetzt.",
		"smart_fail_start" => "Windows startet, stürzt aber ab oder friert ein",
		"smart_fail_ntldr" => "Windows startet nicht, es erscheint \"NTLDR fehlt\"",
		"smart_fail_noos"   => "Windows startet nicht. Es erscheinen Meldungen wie \"No operating System found\", \"Kein System gefunden\" oder \"Please insert a bootable media\"",
		"smart_read_head" => "Auslesen des Festplattenzustandes",
		"smart_read_desc" => "Oft ist eine defekte Festplatte Ursache des Problems. Um einen vollständigen Test aller Festplatten (SMART-Test) zu starten, klicken Sie bitte auf \"Weiter\". Dieser Test kann mehrere Stunden dauern.",
		"smart_prog_head" => "Analyse des Festplattenzustandes",
		"smart_prog_desc" => "Der gesamte Test kann mehrere Stunden dauern. Sie können die Prüfung jederzeit abbrechen, dann besteht allerdings die Gefahr, dass nicht alle Fehler erkannt werden.",
		"smart_error_head" => "Fehler gefunden",
		"smart_error_desc" => "Bei der Festplattenanalyse wurden Fehler gefunden. Um Datenverlusten vorzubeugen, empfehlen wir, den Inhalt der Festplatte jetzt auf eine andere Festplatte zu sichern. Diese können Sie später mit dem Menüpunkt \"Ich muss möglichst schnell meine Daten sichern oder möchte eine Sicherung zurückspielen\" auf eine neue Festplatte kopieren. Es werden nur Zielplatten angezeigt, die mindestens genau so groß sind, wie der beschädigte Datenträger. Bitte wählen Sie die Zielplatte aus und klicken Sie dann auf \"Weiter\".",
		"smart_save_head" => "Erstellen einer Datensicherung",
		"smart_save_desc" => "Es werden nun alle defekten Festplatten auf die ausgewählten Ziellaufwerke geklont. Dieser Vorgang kann einige Stunden dauern.",
		"smart_fini_head" => "Sichern abgeschlossen",
		"smart_fini_desc" => "Das Klonen der fehlerhaften Festplatte ist abgeschlossen. Sie können das Ziellaufwerk nun statt der defekten Festplatte in Ihren Computer einbauen oder die Sicherung später zurückspielen. Klicken Sie auf \"Weiter\", um Ihren Computer neu zu starten.",
		"smart_ok_head" => "Festplattenprüfung abgeschlossen",
		"smart_ok_desc" => "Der Festplatten-Test hat keine Hinweise auf Hardware-Fehler gefunden.",
		"smart_ok_desc2" => "Da auch Fehler im Dateisystem dieses Problem verursachen können, sorgt die Notfall-CD dafür, dass beim nächsten Windows-Start alle Festplatten automatisch untersucht werden.",
		"smart_fsck" => "Dateisystemüberprüfung vormerken",
		"smart_info_nosmart" => "Dieses Laufwerk verfügt über keine SMART-Funktionalität.",
		"smart_info_notest" => "Dieses Laufwerk verfügt über SMART-Funktionalität, aber es wurde noch nie ein Selbsttest durchgeführt.",
		"smart_info_shorttest" => "Dieses Laufwerk verfügt über SMART-Funktionalität, aber es wurden in letzter Zeit nur kurze Selbsttests durchgeführt.",
		"smart_info_longtest" => "Dieses Laufwerk verfügt über SMART-Funktionalität und es wurden bereits lange Selbsttests durchgeführt.",
		"smart_info_bad" => "Das Protokoll des Laufwerkes enthält Hinweise auf defekte/realloziierte Sektoren.",
		"smart_info_verybad" => "Beim Selbsttest wurden Probleme festgestellt, die auf einen baldigen Totalausfall der Festplatte hinweisen.",
		"smart_test_remain" => "Verbleibende Testdauer: ca. %COUNT% Minuten",
		"smart_test_finished" => "Der Selbsttest ist abgeschlossen",
		"smart_clone_desc" => "Diese Festplatte klonen - Auswahl des Ziellaufwerkes:",
		"smart_warn_nosrc" => "Bitte wählen Sie ein Quelllaufwerk zum Klonen aus!", 
		"smart_warn_notgt" => "Bitte stecken Sie ein Ziellaufwerk an, das wenigstens die Größe des defekten Quellaufwerkes hat und klicken Sie anschließend auf \"Neu einlesen\".",
		"smart_warn_multtgt" => "Zu mehreren Quelllaufwerken wurde dasselbe Ziellaufwerk ausgewählt! Bitte ändern Sie Ihre Auswahl.",
		"smart_clone_finished" => "Das Klonen ist abgeschlossen.",
		"smart_clone_progress" => "Klonen läuft...",
		"smart_clone_nonempty" => "Das Ziellaufwerk %TARGET% ist nicht ganz leer. Drücken Sie \"Abbrechen\", um eine andere Festplatte auszuwählen oder die auf dieser Festplatte enthaltenen Daten auf einem anderen Rechner zu sichern. Falls Sie diese Festplatte erneut anschließen, benutzen Sie bitte den Knopf \"Neu einlesen\" um die Laufwerksliste zu aktualisieren.",
		"smart_ntldr_head" => "Fehlermeldung \"NTLDR fehlt\"",
		"smart_ntldr_desc" => "Die Meldung \"NTLDR fehlt\" kann verschiedene Ursachen haben. Meist lässt sich das Problem aber leicht beheben. Da die Notfall-CD dies nicht automatisch erledigen kann, müssen Sie selbst tätig werden. Befolgen Sie dazu einfach die entsprechende Anleitung für Ihre Windows-Version. Die können Sie sich hier anzeigen lassen oder auf einem anderen Computer ausdrucken. In diesem Fall finden Sie die Hilfe-Texte im Ordner \"Anleitungen\" auf der CD. Bevor Sie die Anleitung durchführen, starten Sie Ihren Computer per Klick auf \"Neu starten\" neu.",
		"smart_ntldr_xp" => "Windows XP",
		"smart_ntldr_xpbutt" => "Anleitung für Windows XP anzeigen",
		"smart_ntldr_xpfile" => "/lesslinux/cdrom/Anleitungen/XP-Startprobleme.pdf",
		"smart_ntldr_vista7" => "Windows Vista und Windows 7",
		"smart_ntldr_vista7butt" => "Anleitung für Windows Vista und Windows 7 anzeigen",
		"smart_ntldr_vista7file" => "/lesslinux/cdrom/Anleitungen/Vista- und 7-Reparatur.pdf",
		"smart_ntldr_cont" => "Falls die Anleitung bei Ihnen nicht hilft, kann auch ein Festplatten-Problem vorliegen. Klicken Sie zum Überprüfen auf Weiter.",
		"smart_ntldr_folder" =>  "Diese Anleitungen finden Sie auch im Ordner \"Anleitungen\" auf der CD.",
		"smart_noos_head" => "Startbereich der Festplatte beschädigt",
		"smart_noos_desc" => "Windows startet nicht. Es erscheint: \"No operating System found\", \"Kein System gefunden\" oder \"Please insert a bootable media\". Fehlermeldungen wie diese erscheinen, wenn der Startbereich der Festplatte beschädigt ist. Dies kann die Notfall-CD beheben. Klicken Sie auf Weiter.",
		"smart_mbr_done" => "Startinformationen wurden wiederhergestellt",
		"smart_mbr_desc" => "Die Startinformationen wurden wiederhergestellt. Klicken Sie auf \"Neu starten\".",
		"smart_mbr_desc2" => "Achtung: Sollte Ihr Windows noch immer nicht starten, müssen Sie es neu installieren. Kehren Sie dazu an diese Stelle zurück, und befolgen Sie die entsprechende Anleitung für Ihre Windows-Version. Die können Sie sich direkt hier anzeigen lassen oder auf einem anderen Computer ausdrucken. In diesem Fall finden Sie die Hilfe-Texte im Ordner \"Anleitungen\" auf der CD.",
		"smart_inst_xpbutt" => "Anleitung Neuinstallation Windows XP anzeigen",
		"smart_inst_xpfile" => "/lesslinux/cdrom/Anleitungen/XP-Neuinstallation.pdf",
		"smart_inst_7butt" => "Anleitung Neuinstallation Vista/7 anzeigen",
		"smart_inst_7file" => "/lesslinux/cdrom/Anleitungen/Neuinstallation-Vista-7.pdf",
		"smart_inst_backup" => "Vor der Neuinstallation sollten Sie Ihre persönlichen Dateien sichern. Wie das geht, ist in der folgenden Anleitung beschrieben.",
		"smart_inst_bubutt" => "Anleitung Daten sichern anzeigen",
		"smart_inst_bufile" => "/lesslinux/cdrom/Anleitungen/Dateien sichern.pdf",
		"smart_mbr_fail" => "Wiederherstellung der Startinformationen fehlgeschlagen",
		"smart_mbr_fail_desc" => "Die Startinformationen konnten nicht wiederhergestellt werden. Ursache ist eine beschädigte Partitionstabelle oder fehlgeschlagener Zugriff auf die als aktiv markierte Partition. Eventuell müssen Sie Windows neu installieren. Befolgen Sie dazu die entsprechende Anleitung für Ihre Windows-Version. Die können Sie sich direkt hier anzeigen lassen oder auf einem anderen Computer ausdrucken. In diesem Fall finden Sie die Hilfe-Texte im Ordner \"Anleitungen\" auf der CD.",
		"smart_ntfsfix" => "Die Prüfung der NTFS-Laufwerke findet beim nächsten Windows-Start statt.",
		"smart_mbrwarn" => "Beim Schreiben des Bootsektors werden möglicherweise installierte Bootmanager überschrieben. Klicken Sie auf \"OK\" um fortzufahren, auf \"Abbrechen\", um den Bootsektor unangetastet zu lassen.",
		"virus_check_head" => "Überprüfung auf Virenbefall",
		"virus_nonet" => "Es wurde keine Internetverbindung gefunden. Bitte tragen Sie die Zugangsdaten für Ihr WLAN ein oder wählen Sie \"Ohne Signatur-Aktualisierung fortfahren\".",
		"virus_net_continue" => "Klicken Sie anschließend auf \"Weiter\" um die Aktualisierung der Virensignaturen zu starten.",
		"virus_essid" =>"WLAN",
		"virus_key" => "Kennwort",
		"virus_nosigupdate" => "Ohne Signatur-Aktualisierung fortfahren",
		"virus_sigupdate" => "Aktualisierung der Virensignaturen",
		"virus_search_head" => "Suche nach Viren und anderer Schadsoftware",
		"virus_opts_head" => "Optionen für die Suche nach Viren",
		"virus_opts_arch" => "Sollen Archive nach Schadsoftware durchsucht werden? Dies verlangsamt die Suche und birgt das Risiko von Suchabbrüchen, steigert jedoch die Erkennungsrate.",
		"virus_opts_arch_yes" => "Ja, Archive durchsuchen",
		"virus_opts_arch_no" => "Nein, Archive ignorieren",
		"virus_opts_found" => "Wie soll nach einem Fund von Schadsoftware vorgegangen werden?",
		"virus_opts_found_lax" => "Reparieren, nichts tun wenn Reparatur nicht möglich",
		"virus_opts_found_del" => "Reparieren, infizierte Datei löschen wenn Reparatur nicht möglich",
		"virus_opts_found_show" => "Funde nur anzeigen",
		"virus_scan_cancel" => "Virenscan abgebrochen",
		"virus_cancel_desc" => "Die Suche nach Schadsoftware wurde abgebrochen. Falls Sie den Abbruch nicht selbst durchgeführt haben, ist eine wahrscheinliche Ursache das Entpacken einer großen Archivdatei, für die nicht genug Arbeitsspeicher zur Verfügung stand. Probieren Sie in diesem Fall die Virensuche erneut, schalten Sie aber die Untersuchung von Archivdateien ab.",
		"virus_sigup_running" => "Die Aktualisierung der Virensignaturen läuft",
		"virus_sigup_done" => "Die Aktualisierung der Virensignaturen ist abgeschlossen" ,
		"virus_sigup_noneed" =>  "Die Virensignaturen sind bereits auf dem neuesten Stand.",
		"virus_sigup_failed" =>  "Die Aktualisierung der Virensignaturen ist fehlgeschlagen. Mögliche Ursachen sind Netzwerkprobleme oder ein Abbruch durch den Benutzer.",
		"virus_scan_running" => "Die Überprüfung auf Schadsoftware läuft",
		"virus_scan_done" => "Die Überprüfung auf Schadsoftware ist abgeschlossen",
		"virus_summ_head" => "Virusscan abgeschlossen",
		"virus_summ_desc" => "Der Virenscan ist abgeschlossen. Insgesamt wurden %M% Dateien untersucht. %N% Dateien wiesen Schädlingsbefall auf, davon konnten %O% Dateien repariert werden. Bei %P% Dateien war keine Reparatur möglich.",
		"virus_summ_infect" => "Der Virenscan ist abgeschlossen. Das folgende Textfeld zeigt infizierte Dateien an. Ist das Feld leer, wurde keine Schadsoftware gefunden.",
		"virus_summ_empty" => "Noch nicht initialisiert"
	},
	"es" => {
		"win_title" => "RescueThreeZero",
                "back" => "Atrás",
                "forw" => "Continuar",
                "cancel" => "Cancelar",
                "reboot" => "Reiniciar",
                "reread" => "Actualizar",
                "details" => "Mostrar detalles",
                "header_image" => "NotfallCD30_es.png",
                "missing_log" => "Pérdida del archivo log – Posible causa: el escaneo antivirus fue cancelado.",
                "discharging" => "¡Por favor, conecte un cargador para el portátil! De no hacerlo, si se apaga el equipo puede sufrir una pérdida de datos.",
                 "lowmemory" => "Su ordenador tiene menos de 768 Mb de RAM. Es imprescindible usar una memoria USB o una tarjeta de memoria SD adicional. Por favor, introduzca una memoria USB, haga click en \"Actualizar\" y escoja la memoria que deba ser utilizada.",
                "smart_aborting" => "Se aborta el autodiagnóstico",
                "select_title" => "¿Qué problema tienes?",
                "select_one" => "Windows no se inicia o se bloquea",
                "select_two" => "Se han borrado archivos importantes por error",
                "select_three" => "He olvidado mi contraseña de Windows",
                "select_four" => "Sospecho que mi equipo tiene un virus",
                "select_five" => "Tengo que reinstalar Windows o quiero vender mi ordenador",
                # "select_six" => " Tengo que guardar mis datos lo más rápido posible o quiero volver a un guardado anterior",
                "select_six" => "Quiero hacer un backup del disco duro que contiene Windows, o pasar su contenido a una unidad nueva.",
		"wlan_not_found" => "No se ha encontrado una interfaz inalámbrica. La detección de virus se realizará sin actualización de firmas.",
                "wlan_connecting" => "Punto de acceso inalámbrico...",
                "clean_partition_select" => "A continuación seleccionar la partición donde está instalado Windows. Si escoge otra partición podrá perder archivos y copias de seguridad personales. Haga click en \"Siguiente\".",
                "clean_drive_select" => "Seleccione el disco que desea borrar. Todos los datos que contiene serán eliminados definitivamente. Haga click en \"Siguiente\".",
                "clean_fast" => "Haga click aquí para preparar al disco duro para una instalación óptima de un Windows actual.",
                "clean_good" => "Si desea vender el ordenador, haga click aquí para borrar el contenido del disco duro de forma segura.",
                "clean_select_part" => "Elección de la unidad.",
                "clean_part_desc" => " A continuación seleccionar la partición donde está instalado Windows. Si escoge otra partición podrá perder archivos y copias de seguridad personales. Haga click en \"Siguiente\".",
                "clean_progress_head" => "Supresión de volúmenes",
                "clean_done_head" => "Borrado completado",
                "clean_done_desc" => "Se ha completado el borrado de la unidad seleccionada. Haga click en \"Reiniciar\" para reiniciar el equipo.",
                "clean_no_selection" => "¡Por favor, elija la unidad a borrar!",
                "clean_fast_message" => "El proceso de borrado durará varios minutos. Después del borrado rápido, generalmente, es posible volver a restaurar parte de los datos sobrescritos. No utilice usted el borrado rápido si quiere vender su ordenador a otras personas.",
                "clean_good_message" => "El borrado seguro tardará varias horas. Después del borrado seguro es imposible recupera los datos sobrescritos. Haga click en \"OK\" si desea eliminar definitivamente las unidades seleccionadas.",
                "clean_no_clean" => "No debe borrarse",
                "clean_done" => "Borrado competo",
                "clone_header" => "Quiero copiar un disco o volver a un guardado anterior",
                "clone_desc" => "Esta caracteristica permite copier el contenido del disco duro en otra unidad. De esta forma se puede mover, por ejemplo, el contenido de la partición que tiene el sistema y los programas a una unidad nueva.",
                "clone_desc2" => "Ahora, seleccione el disco de origen. Si se trata de un disco externo, conéctelo ahora y haga click en \"Actualizar\". A continuación, seleccione la unidad con un click en la flecha.",
                "clone_tgt_head" => "Selección de la unidad de destino",
                "clone_tgt_desc" => "Ahora, seleccione la unidad de destino. Si se trata de un disco duro externo, conéctelo ahora y haga click en \"Actualizar\". A continuación, seleccione la unidad con un click en la flecha.",
                "clone_tgt_warn" => "Nota: Se perderán todos los archivos contenidos en la unidad de destino. Además, esta debe tener, como mínimo, el mismo tamaño que la unidad de origen.",
                "clone_progress_head" => "Para clonar un disco",
                "clone_progress_warn" => "Dependiendo del tamaño del disco, la clonación puede tardar varias horas. Por favor, no detenga el proceso.",
                "clone_in_progress" => "Progreso de clonación...", 
                "clone_finished" => "Clonación completa",
                "clone_fin_desc" => "La unidad se ha clonado con éxito. Ahora, retire el disco de destino con la copia de seguridad completa y guárdela en un lugar seguro. Si ha restaurado una copia de seguridad completa, haga click en \"Reiniciar\" para reiniciar Windows.",
                # "clone_further" => "Si crea una copia de seguridad completa, hay dos posibilidades: \n\n1. Windows está dañado, volver al menú principal y hacer click en \"Windows no se inicia o se bloquea\". \n\n2. Si el dico duro está dañado, es hora de sustituirlo. Después de cambiarlo, ejecute el disco de rescate para reinstalar la copia de seguridad. Esta vez, seleccione la unidad con copia de seguridad como origen y el nuevo disco como destino de la restauración. La guía para la sustitución del disco se puede encontrar en:",
                "clone_further" => "Si ha creado un clon del disco duro por problemas con el sistema operativo o con el propio disco tiene dos opciones: \n\n1. Si Windows está dañado, vuelva al menú principal y haga click en \"Windows no se inicia o se bloquea\". \n\n2. Si su disco duro está dañado y quiere sustituirlo por otro puede emplear el procedimiento anterior para restaurar el clon que ha creado en una unidad nueva. Solo necesita marcar la unidad donde se encuentra este como origen y el nuevo disco como destino. La guía para hacerlo se puede encontrar en:",
		"clone_show_manual" => "Guía para cambiar el disco duro",
                "clone_manual_path" =>  "/lesslinux/cdrom/Manual/practico.pdf", 
		"clone_manual_page" =>  9,
                "clone_error_read" => "Se ha producido un error al leer los discos. Por favor, vuelva atrás y comience la tarea de nuevo.",
                "clone_warn_noparts" => "La unidad de origen no contiene tabla de particiones y es mayor que la unidad de destino. Es posible que se pierda información al copiar datos.",
                "clone_warn_bigger" => "La última partición de la unidad de origen es mayor que la última partición de la unidad de destino. Es posible que se pierda información al copiar los datos. Por favor, vuelva atrás y reduzca el tamaño de la última partición del disco de origen antes de proceder con la copia.",
                "clone_warn_destroy" => "Haga click en \"Aceptar\" para sobreescribir todos los datos en la niudad de destino. Haga click en \"Cancelar\" para volver a la selección de unidades.",
                "restore_select_source" => "¿En qué unidad busco los datos perdidos? Si estos se encuentran en un disco externo, conéctelo y haga click en \"Actualizar\". A continuación, seleccione la unidad con un click en la flecha. Se buscará en toda la unidad.",
                "restore_types_head" => "Selección de tipos de archivo",
                "restore_types_desc" => "¿Qué tipos de archivo se deben buscar?",
                "restore_types_office" => "Documentos ofimáticos (como OpenOffice, Pdf y rtf)",
                "restore_types_image" => "Fotos e imágenes",
                "restore_types_video" => "Vídeos",
                "restore_types_music" => "Música",
                "restore_types_mbox" => "Cuentas de correo electrónico (como Outlook)",
                "restore_types_arch" => "Archivos comprimidos (.zip, .rar, .7z, .ISO)",
                "restore_types_every" => "Todos los archivos recuperables",
                "restore_tgt_head" => "Selección de la unidad de destino",
                "restore_tgt_desc" => "¿En qué unidad se guardarán los archivos encontrados? Dado que el volumen de archivos encontrados puede ser muy grande, la unidad de destino debería tener espacio suficiente.",
                "restore_tgt_desc2" => "Tenga en cuenta que la unidad de origen y la de destino no pueden ser la misma. Por este motivo, la unidad de origen no aparece aquí.",
                "restore_tgt_desc3" => "Si desea copiar los datos encontrados en un disco externo, conéctelo ahora y haga click en \"Actualizar\". A continuación, seleccione la unidad con un click en.",
                "restore_prog_head" => "Buscar archivos", 
                "restore_no_types" => "Por favor, seleccione los tipos de archivo a buscar",
                "restore_no_target" => "No ha seleccionado una unidad de destino. Por favor, conéctela y, luego, haga click en \"Actualizar\".",
                "restore_running" => "Recuperación en curso", 
                "restore_count" => "%COUNT% Archivos restaurados", 
                "restore_finished_head" => "Archivos restaurados",
                "restore_finished_desc" => "La restauración de los archivos se ha completado. Los podrá encontrar en la unidad de destino selecionada, almacenados en carpetas numeradas consecutivamente \"Recovery\".",
                "restore_space_warn" => "El espacio en la unidad de destino es insuficiente. Puede conectar otro disco mediante USB para guardar el resto de los archivos. Haga click en \"Aceptar\". Haga click en \"Cancelar\" si desea detener la búsqueda.",
                "restore_new_target" => "Seleccione la unidad donde se copiarán los archivos restantes. Solo mostrar las unidades con 1 Gb o más de capacidad.",
                "restore_all_warn" => " Si no escoge tipos concretos de archivos, Photorec buscará ficheros de todos los formatos en todos los sitios. Esto requiere mucho espacio en la unidad de destino y dificultará posteriormente ordenar los archivos recuperados. Haga click en \"Aceptar\" para buscar todos los formatos de archivo, o en \"Cancelar\"para volver a la selección.",
		"restore_tgt_combo" => "%VENDOR% %MODEL% %DEVICE% %ATTACHED% partición: %PART%%LABEL% Libre %FREESPACE%",
                "chntpw_win_select" => "¿Desde qué instalación de Windows debe ser generado el fichero de la contraseña?",
                "chntpw_user_head" => "Selección de la cuenta de usuario",
                "chntpw_user_select" =>   "Seleccione la cuenta de usuario cuya contraseña se restablecerá. Después de hacerlo, podrá acceder a esta cuenta sin utilizar ninguna contraseña.",
                "chntpw_not_found" => "No se encuentra la instalación de Windows",
                "chntpw_success_title" => "Restablecimiento de la contraseña de Windows",
                "chntpw_success_long" => "Su contraseña de Windows se restableció con éxito.",
                "smart_fail_start" => "Windows se inicia, se cae o se bloquea.",
                "smart_fail_ntldr" => "Windows no arranca, aparece \"Falta NTLDR\"",
                "smart_fail_noos"   => "Windows no se inicia. Aparecen mensajes como \"No se encuentra el sistema operativo\", \"No System\" o \"Por favor, inserte un dispositivo de inicio\"",
                "smart_read_head" => "Lectura del estado del disco duro",
                "smart_read_desc" => "A menudo, el problema se debe a que el disco duro está dañado. Para iniciar una prueba completa de todas las unidades de disco (SMART-test), haga click en  \"Siguiente\".Esta prueba puede tardar varias horas.",
                "smart_prog_head" => "Análisis del disco duro",
                "smart_prog_desc" => "El examen completo puede durar varias horas. Puede detener la prueba en cualquier momento, pero se corre el riesgo de no detectar todos los posibles errores.",
                "smart_error_head" => "Se ha encontrado un error",
                "smart_error_desc" => "Cuando se encuentran errores en el disco duro. Para evitar la pérdida de datos, se recomienda que guarde ahora el contenido del disco duro en otra unidad. Los datos se podrán copiar en un nuevo disco duro más tarde utilizando la opción de menú \"Tengo que guardar mis datos lo más rápido posible o quiero volver a un guardado anterior\". Se mostrarán solo las unidades de destino que tengan, por lo menos, la misma capacidad que el disco de origen dañado. Por favor, seleccione el disco de destino y haga click en \"Siguiente\".",
                "smart_save_head" => "Crear una copia de seguridad",
                "smart_save_desc" => "Ahora, todo el contenido del disco duro dañado se copiará a la unidad de destino. Este proceso puede tardar varias horas.",
                "smart_fini_head" => "Copia de seguridad completa",
                "smart_fini_desc" => "La clonación del diso duro dañado se ha completado. Ahora, puede utilizar la unidad de destino en lugar del disco duro dañado de su ordenador, o instalar más tarde la nueva unidad. Haga click en \"Siguiente\", para reiniciar el equipo.",
                "smart_ok_head" => "Comprobación de disco completada",
                "smart_ok_desc" => "La comprobación del disco no encontró ninguna evidencia de un error de hardware.",
                "smart_ok_desc2" => "Dado que este problema puede causar errores en el sistema de archivos, el CD de recuperación efectuará un examen de todos los discos durante el próximo inicio de Windows.",
                "smart_fsck" => "Anotar la comprobación del sistema de archivos",
                "smart_info_nosmart" => "Esta unidad no tiene la funcionalidad SMART.",
                "smart_info_notest" => "Esta unidad tiene la capacidad SMART, pero nunca se llevó a cabo una prueba automática.",
                "smart_info_shorttest" => "Esta unidad tiene la capacidad SMART, pero se ha realizado recientemente una prueba corta.",
                "smart_info_longtest" => "Esta unidad tiene la capacidad SMART y ya se ha realizado una prueba automática completa.",
                "smart_info_bad" => "El informe de la unidad contiene evidencias de sectores defectuosos.",
                "smart_info_verybad" => "Se detectaron problemas en el test, lo que indica un fallo inminente de la unidad de disco duro.",
                "smart_test_remain" => "Tiempo restante de la prueba: ca. %COUNT% minutos",
                "smart_test_finished" => "El autodiagnóstico se ha completado",
                "smart_clone_desc" => "Clonación del disco duro – Selección de la unidad de destino:",
                "smart_warn_nosrc" => "¡Por favor, seleccione una unidad de origen para la clonación!", 
                "smart_warn_notgt" => "Por favor, utilice un disco de destino que tenga, por lo menos, el tamaño de la unidad de origen, y haga click en \"Actualizar\".",
                "smart_warn_multtgt" => "¡Se eligieron diversas unidades de origen para la misma unidad de destino! Por favor, escoja otro disco.",
                "smart_clone_finished" => "Clonación completa.",
                "smart_clone_progress" => "Progreso de clonación...",
                "smart_clone_nonempty" => "El disco de destino %TARGET% no está completamente vacío. Pulse \"Cancelar\" para seleccionar una unidad diferente o copie los datos contenidos en este disco en otra unidad. Si conecta el disco duro, por favor, utilice el botón \"Volver a examinar\" para actualizar la lista de unidades.",
                "smart_ntldr_head" => "Mensaje de error \"Falta NTLDR\"",
                "smart_ntldr_desc" => "el mensaje \"Falta NTLDR \" puede tener diferentes causas. Generalmente, este problema se soluciona con facilidad. Ya que el CD de recuperación no puede hacerlo de manera automática, tiene que hacerlo usted mismo. Simplemente, siga las instrucciones específicas para su versión de Windows. Estas se pueden visualizar aquí mismo, o hacerlo desde otro ordenador. En este caso, puede encontrar los archivos de ayuda en el apartado \"¿Cómo?\" del CD. Antes de seguir estas indicaciones, reinicie el ordenador con un click en \"Reiniciar\".",
                "smart_ntldr_xp" => "Windows XP",
                "smart_ntldr_xpbutt" => "Mostrar las instrucciones para Windows XP",
                "smart_ntldr_xpfile" =>  "/lesslinux/cdrom/Manual/practico.pdf",
		"smart_ntldr_xppage" => 3,
                "smart_ntldr_vista7" => "Windows Vista y Windows 7",
                "smart_ntldr_vista7butt" => "Mostrar las instrucciones para Windows Vista y Windows 7",
                "smart_ntldr_vista7file" =>  "/lesslinux/cdrom/Manual/practico.pdf",
		"smart_ntldr_vista7page" => 3,
                "smart_ntldr_cont" => "Si estas instrucciones no le ayudan puede haber un problema en el disco duro. Para comprobarlo, haga click en Siguiente.",
                "smart_ntldr_folder" =>  "estas instrucciones también se pueden encontrar en la carpeta \"¿Cómo?\" en el CD.",
                "smart_noos_head" => "Área de inicio del disco duro dañada ",
                "smart_noos_desc" => "Windows no se inicia. Verá: \"No se encuentra el sistema operativo\", \"No System\" o \"Por favor, inserte un dispositivo de inicio\".Anuncios de error como este aparecen cuando el área de inicio del disco duro está dañada. Esto lo puede solucionar el CD de recuperación. Haga click en Siguiente.",
                "smart_mbr_done" => "La información de inicio ha sido restaurada",
                "smart_mbr_desc" => "La información de arranque ha sido recuperada. Haga click en \"Reiniciar\".",
                "smart_mbr_desc2" => "Precaución: Si Windows sigue sin arrancar, es necesario volver a instalarlo. Vuelva atrás a este punto y siga las instrucciones correspondientes a su versión de Windows. Estas se pueden visualizar aquí mismo, o hacerlo desde otro ordenador. En este caso, puede encontrar los archivos de ayuda en el apartado \"¿Cómo?\" en el CD.",
                "smart_inst_xpbutt" => "Guía de reinstalación de Windows XP",
                "smart_inst_xpfile" =>  "/lesslinux/cdrom/Manual/practico.pdf",
		"smart_inst_xppage" =>  4,
                "smart_inst_7butt" => "Mostrar el manual de reinstalación de Windows Vista / Windows 7",
                "smart_inst_7file" =>  "/lesslinux/cdrom/Manual/practico.pdf",
		"smart_inst_7page" =>  4,
                "smart_inst_backup" => "Antes de volver a instalar, debe hacer una copia de seguridad de sus archivos personales. En las instrucciones se describe cómo hacer esto.",
                "smart_inst_bubutt" => "Manual de visualización de datos",
                "smart_inst_bufile" => "/lesslinux/cdrom/Manual/practico.pdf",
		"smart_inst_bupage" => 5,
                "smart_mbr_fail" => "La recuperación de los datos de inicio ha fallado ",
                "smart_mbr_fail_desc" => "Los datos de inicio no se pueden recuperar. La causa es bien una tabla de particiones dañada o un fallo de acceso a la partición activa. Es posible que tenga que instalar Windows de nuevo. Siga las instrucciones específicas para su versión de Windows. Estas se pueden visualizar aquí mismo, o hacerlo desde otro ordenador. En este caso, puede encontrar los archivos de ayuda en el apartado \"¿Cómo?\" en el CD.",
                "smart_ntfsfix" => "Se llevará a cabo un análisis de las unidades NTFS al iniciar Windows.",
                "smart_mbrwarn" => "Al escribir de nuevo el sector de arranque es posible que se sobreescriba el gestor de arranque. Haga click en \"Aceptar\" para continuar, o a \"Cancelar\", para dejar intacto el sector de arranque.",
                "virus_check_head" => "Comprobación de virus",
                "virus_nonet" => "No se encuentra la conexión a Internet. Por favor, introduzca los datos de acceso para la red inalámbrica o seleccione \"Continuar sin actualización de firmas de virus\".",
                "virus_net_continue" => "Luego, haga click en \"Siguiente\" para actualizar las firmas de virus.",
                "virus_essid" =>"WLAN",
                "virus_key" => "Contraseña",
                "virus_nosigupdate" => "Continuar sin actualización de firmas",
                "virus_sigupdate" => "Actualización de firmas de virus",
                "virus_search_head" => "Analizar en busca de virus y otro software malicioso",
                "virus_opts_head" => "Opciones de búsqeuda de virus",
                "virus_opts_arch" => "¿Realizar escaneo de archivos en busca de malware? Esto ralentiza la búsqueda y conlleva el riesgo de interrupciones en la misma. Sin embargo, aumenta la tasa de detección.",
                "virus_opts_arch_yes" => "Sí, acceder a los archivos",
                "virus_opts_arch_no" => "No, ignorar archivo",
                "virus_opts_found" => "¿Cómo debe proceder al encontrar software malicioso? ",
                "virus_opts_found_lax" => "Reparar, no hacer nada si no es posible la reparación ",
                "virus_opts_found_del" => "Eliminar los archivos infectados",
                "virus_opts_found_show" => "Sólo mostrar los resultados",
                "virus_scan_cancel" => "Detección de virus abortada",
                "virus_cancel_desc" => "La búsqueda de software malicioso ha sido cancelada. Si no la ha cancelado usted mismo, es posible que el sistema se haya parado por no tener suficiente memoria para descomprimir un fichero de gran tamaño. En este caso, pruebe de nuevo con la búsqueda de virus, pero desactive la búsqueda de archivos.",
                "virus_sigup_running" => "Está ejecutándose la actualización de las firmas de ",
                "virus_sigup_done" => "La actualización de firmas de virus se ha completado" ,
                "virus_sigup_noneed" =>  "Las firmas de virus ya están actualizadas.",
                "virus_sigup_failed" =>  "No se ha actualizado la base da datos de firmas de virus. Es posible que se deba a un fallo en la red o a restricciones por parte del usuario.",
                "virus_scan_running" => "Ejecutando comprobación de software malicioso",
                "virus_scan_done" => "Se ha completado la comprobación de software malicioso",
                "virus_summ_head" => "Detección de virus completa",
                "virus_summ_desc" => "La búsqueda de virus se ha completado. En total se analizaron %M% ficheros. %N% ficheros estaban infectados, de ellos %O% ficheros se han podido reparar. En %P% ficheros no fue posible la reparación. Se han borrado %Q% archivos.",
                "virus_summ_infect" => "Se ha completado la búsqueda de virus. El cuadro siguiente muestra los archivos infectados. Si el campo está vacío no se encontró software malicioso.",
                "virus_summ_empty" => "No se ha iniciado"
	}
}



## define the order of pages to follow

def page_order(last_page, radio, start_radio, showstart)
	return 1 if last_page == 0
	if last_page == 1 && radio[0].active?
		return 2
	end
	if last_page == 1 && radio[1].active?
		return 3
	end
	if last_page == 1 && radio[2].active?
		return 4
	end
	if last_page == 1 && radio[3].active? && (check_network == false || @simulate.include?("nonet"))
		return 5
	elsif last_page == 1 && radio[3].active? && check_network == true
		return 14
	end
	if last_page == 1 && radio[4].active?
		return 6
	end
	if last_page == 1 && radio[5].active?
		return 7
	end
	return 8 if last_page == 3
	return 9 if last_page == 8
	return 10 if last_page == 9
	return 11 if last_page == 10
	return 12 if last_page == 4
	return 13 if last_page == 12
	if last_page == 5 && @wlan_interface.nil? # WLAN settings
		return 15
	elsif last_page == 5
		return 14
	end
	# return 15 if last_page == 14
	return 35 if last_page == 14
	# return 16 if last_page == 15
	return 15 if last_page == 35
	return 16 if last_page == 15 && read_scan_summary(@virus_scanner) == false
	return 36 if last_page == 15 && ( @virus_delete.active? == true || @virus_kill.active? == true )
	return 37 if last_page == 15
	return 17 if last_page == 16
	return 18 if last_page == 17
	return 19 if last_page == 6
	return 20 if last_page == 19
	return 21 if last_page == 20
	return 22 if last_page == 7
	return 23 if last_page == 22
	return 24 if last_page == 23
	if last_page == 2 && start_radio[0].active?
		return 25
	elsif last_page == 2 && start_radio[1].active?
		return 31
	elsif last_page == 2 && start_radio[2].active?
		return 32
	end
	return 26 if last_page == 25
	if last_page == 26 && ( @bad_drives.size > 0 || @simulate.include?("smartfail"))
		return 27
	elsif last_page == 26
		return 30
	end
	return 27 if last_page == 26
	return 28 if last_page == 27
	return 29 if last_page == 28
	return 26 if last_page == 31
	### if last_page == 32 && @simulate.include?("ms-sys-success")
	###	return 33
	### els
	if last_page == 32
		return 34
	end
	return 1 if showstart == false
	return 0
end

# define if buttons back/forw are visible

def back_forw_visible(screen)
	if screen == 1 || screen == 2 || screen == 28
		return false 
	end
	return true
end

window = Gtk::Window.new
window.border_width = 10
window.window_position = Gtk::Window::POS_CENTER_ALWAYS

if @deco == false
	window.deletable = false
	window.decorated = false
	window.allow_grow = false
	window.allow_shrink = false
end
window.title = extract_lang_string("win_title")
window.signal_connect('delete_event') { false }
window.signal_connect('destroy') { 
	system("rm /var/run/lesslinux/assistant_running")
	Gtk.main_quit
}

screens = Array.new
prog_path = Array.new

# Container for buttons
icon_theme = Gtk::IconTheme.default
buttonbox = Gtk::HBox.new(false, 5)
back_button = Gtk::Button.new extract_lang_string("back")
back_button.image = Gtk::Image.new(icon_theme.load_icon("gtk-go-back-ltr", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
forw_button = Gtk::Button.new extract_lang_string("forw")
forw_button.image = Gtk::Image.new(icon_theme.load_icon("gtk-go-forward-ltr", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
## stop_button = Gtk::Button.new("Abbrechen")
## stop_button.image = Gtk::Image.new(icon_theme.load_icon("gtk-cancel", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
## buttonbox.pack_start_defaults stop_button
buttonbox.pack_start_defaults back_button
buttonbox.pack_start_defaults forw_button
reboot_button = Gtk::Button.new extract_lang_string("reboot")
reboot_button.signal_connect("clicked") { 
	system("rm /var/run/lesslinux/assistant_running")
	Gtk.main_quit
}
reboot_box = Gtk::HBox.new(false, 5)
reboot_button.image = Gtk::Image.new(icon_theme.load_icon("stock_refresh", 24, Gtk::IconTheme::LOOKUP_GENERIC_FALLBACK))
reboot_box.pack_start_defaults reboot_button
reboot_box.hide_all
bgimg = Gtk::Image.new extract_lang_string("header_image")

# container for warnings upon start
screens[0], showstart, skipstart, swap_combo, swap_button = get_start_screen(forw_button, @simulate)
screens[1], radio_buttons, choose_buttons = get_chooser_screen(forw_button, @simulate)
screens[2], radio_failure, button_failure = get_failure_screen(forw_button, @simulate)
screens[3], photorec_combo, photorec_reread = get_photorec_screen(forw_button, @simulate)
screens[4], chntpw_combo  		= get_chntpw_screen(forw_button, @simulate)
screens[5], wlan_combo, wlan_key, skip_wlan = get_virus_screen(forw_button, @simulate)
screens[6], clean_combo, clean_buttons   = get_clean_screen(forw_button, @simulate)
screens[7], rest_source, rest_src_reread = get_restore_screen(forw_button, @simulate)
screens[8], photorec_ftypes, m_ftypes   = get_photorec_types_screen(forw_button, @simulate)
screens[9], photorec_tgt_combo, photorec_tgt_reread = get_photorec_target_screen(forw_button, @simulate)
screens[10], photorec_vte, photorec_prog = get_photorec_prog_screen(forw_button, @simulate)
screens[11] 				= get_photorec_finish_screen(forw_button, @simulate)
screens[12], user_combo   		= get_chntpw_user_screen(forw_button, @simulate)
screens[13]               		= get_chntpw_finish_screen(forw_button, @simulate)
screens[14], upd_vte, upd_progbar      	= get_virus_sig_screen(forw_button, @simulate)
screens[15], scan_vte, scan_progbar	= get_virus_scan_screen(forw_button, @simulate)
screens[16]               		= get_virus_results_screen(forw_button, @simulate)
screens[17], repair_vte   		= get_virus_repair_screen(forw_button, @simulate)
screens[18]               		= get_virus_finish_screen(forw_button, @simulate)
screens[19], drive_box, clean_drives_desc = get_clean_drives(forw_button, @simulate)
screens[20], clean_panel 		= get_clean_progress_screen(forw_button, @simulate)
screens[21]               		= get_clean_finish_screen(forw_button, @simulate)
screens[22], rest_targets, rest_tgt_reread = get_restore_target_screen(forw_button, @simulate)
screens[23], restore_vte, rest_tgt_prog, rest_stop = get_restore_progress_screen(forw_button, @simulate)
screens[24]              	 	= get_restore_finish_screen(forw_button, @simulate)
screens[25], smart_panel		= get_smart_overview_screen(forw_button, @simulate)
screens[26], smart_vte, smart_pgbar, smart_stop = get_smart_progress_screen(forw_button, @simulate)
screens[27], smart_clone_panel, smart_tgt_reread = get_smart_fail_screen(forw_button, @simulate)
screens[28], clone_vte, clone_pgbar, clone_stop	= get_smart_clone_screen(forw_button, @simulate)
screens[29]				= get_smart_finish_screen(forw_button, @simulate)
screens[30], ntfsfix_button		= get_smart_ok_screen(forw_button, @simulate)
screens[31]				= get_ntldr_screen(forw_button, @simulate)
screens[32]				= get_noos_screen(forw_button, @simulate)
screens[33]				= get_noos_repaired_screen(forw_button, @simulate)
screens[34]				= get_noos_failure_screen(forw_button, @simulate)
screens[35], virus_archive, @virus_delete, @virus_kill = get_virus_options_screen(@virus_scanner)
screens[36], virus_del_panel, virus_del_summary	= get_virus_summary_screen
screens[37], virus_list_field		= get_virus_list_screen

clone_source_drives = Array.new
clone_target_drives = Array.new
clone_source_metas = Hash.new
clone_target_metas = Hash.new
clean_checkboxes = Hash.new
clean_pgbars = Hash.new
clean_vtes = Hash.new
chntpw_parts = Array.new 
nt_users = Array.new
photorec_drives = Array.new
photorec_targets = Array.new
smart_src_checks = Hash.new
smart_tgt_drives = Hash.new 
smart_tgt_combos = Hash.new
swap_sticks = Array.new

@bad_drives = Hash.new
@wlan_interface = nil
current_drivelist = nil

fixed = Gtk::Fixed.new
fixed.put(bgimg, 0, 0)
screens.each { |s| fixed.put(s, 15, 110) }
fixed.put(buttonbox, 440, 395)
fixed.put(reboot_box, 490, 395)

system("touch /var/run/lesslinux/assistant_running")
window.set_size_request(600, 440)
window.border_width = 0
window.add(fixed)
window.show_all
screens.each { |s| s.hide_all }

current_page = 0
current_page = 1 if showstart == false

# DEBUG
# current_page = 6

if current_page == 1
	buttonbox.hide_all
	reboot_box.show_all
else
	reboot_box.hide_all
end
screens[current_page].show_all

back_button.signal_connect("clicked") {
	screens.each { |s| s.hide_all }
	screens[1].show_all
	buttonbox.hide_all
	reboot_box.show_all
	current_page = 1
	prog_path = [ ] 
	back_button.sensitive = true
	forw_button.sensitive = true
}

choose_buttons[0].signal_connect("clicked") {
	next_screen = 2
	moveon = true
	buttonbox.show_all
	forw_button.sensitive = false
	reboot_box.hide_all
	if moveon == true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		# prog_path.push(next_screen) unless prog_path[-1] == next_screen
	end
}

choose_buttons[1].signal_connect("clicked") {
	reboot_box.hide_all
	next_screen = 3 
	photorec_drives = fill_photorec_combo(photorec_combo, AllDrives.new(true, false, false))
	forw_button.sensitive = true
	forw_button.sensitive = false if photorec_drives.size < 1 
	moveon = true
	buttonbox.show_all
	if moveon == true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		# prog_path.push(next_screen) unless prog_path[-1] == next_screen
	end
}

choose_buttons[2].signal_connect("clicked") {
	reboot_box.hide_all
	next_screen = 4
	current_drivelist = AllDrives.new(true, false, false)
	sysparts = find_win_sysparts(current_drivelist)
	chntpw_parts = fill_chntpw_combo(chntpw_combo, sysparts) 
	if chntpw_parts.size < 1
		forw_button.sensitive = false
	end
	moveon = true
	buttonbox.show_all
	if moveon == true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		# prog_path.push(next_screen) unless prog_path[-1] == next_screen
	end
}

choose_buttons[3].signal_connect("clicked") {
	reboot_box.hide_all
	next_screen = 14
	if check_network == false || @simulate.include?("nonet")
		next_screen = 5
		@wlan_interface = fill_wlan_combo(wlan_combo, get_networks)
		skip_wlan.active = true if @wlan_interface.nil?
	end
	moveon = true
	buttonbox.show_all
	if moveon == true && next_screen == 5
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		# prog_path.push(next_screen) unless prog_path[-1] == next_screen
		dialog_nonet(window) if @wlan_interface.nil?
	else
		puts "Geeeh... moving to 14"
		puts "Geeeh... current page " + current_page.to_s
		puts "Geeeh... prog path " + prog_path.join(", ")
		puts "Geeeh... " +  skip_wlan.active?.to_s
		if skip_wlan.active? == false && check_network == false && ( prog_path.include?(5) || current_page == 5 )
			puts "Geeeh... connecting!"
			window_net_connect(window, wlan_combo.active_text, wlan_key.text, [ forw_button, back_button] )
			screens.each { |s| s.hide_all }
			screens[next_screen].show_all
			prog_path.push(current_page) unless prog_path[-1] == current_page
			current_page = next_screen
			puts prog_path.join(" - ") + " + " + current_page.to_s
			run_virus_signature_update(upd_vte, upd_progbar, [ forw_button, back_button], @virus_scanner, window)
			next_screen = 35
			buttonbox.show_all
			screens.each { |s| s.hide_all }
			screens[next_screen].show_all
			prog_path.push(current_page) unless prog_path[-1] == current_page
			current_page = next_screen
			puts prog_path.join(" - ") + " + " + current_page.to_s
		elsif skip_wlan.active? == true
			next_screen = 15
			buttonbox.hide_all
			screens.each { |s| s.hide_all }
			screens[next_screen].show_all
			prog_path.push(current_page) unless prog_path[-1] == current_page
			current_page = next_screen
			puts prog_path.join(" - ") + " + " + current_page.to_s
			run_virusscan(scan_vte, scan_progbar, [ forw_button, back_button], @virus_scanner, virus_archive, @virus_delete, @virus_kill)
			next_screen = page_order(current_page, radio_buttons, radio_failure, skipstart)
			begin
				virus_list_field.buffer.text = File.new("/tmp/kaspersky_infected.log", "r").read
			rescue
				virus_list_field.buffer.text = extract_lang_string("missing_log")
			end
			virus_del_summary.text = virus_human_stats(@virus_scanner)
			reboot_box.show_all
			moveon = true
		else
			buttonbox.hide_all
			screens.each { |s| s.hide_all }
			screens[next_screen].show_all
			prog_path.push(current_page) unless prog_path[-1] == current_page
			current_page = next_screen
			puts prog_path.join(" - ") + " + " + current_page.to_s
			run_virus_signature_update(upd_vte, upd_progbar, [ forw_button, back_button], @virus_scanner, window)
			next_screen = 35
			buttonbox.show_all
			screens.each { |s| s.hide_all }
			screens[next_screen].show_all
			prog_path.push(current_page) unless prog_path[-1] == current_page
			current_page = next_screen
			puts prog_path.join(" - ") + " + " + current_page.to_s
		end
	end
}

choose_buttons[4].signal_connect("clicked") {
	buttonbox.show_all
	forw_button.sensitive = false
	reboot_box.hide_all
	next_screen = 6
	moveon = true
	# buttonbox.hide_all
	if moveon == true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		# prog_path.push(next_screen) unless prog_path[-1] == next_screen
	end
}

choose_buttons[5].signal_connect("clicked") {
	reboot_box.hide_all
	next_screen = 7
	clone_source_drives, clone_source_metas = reread_full_drives(rest_source, [])
	moveon = true
	buttonbox.show_all
	if moveon == true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		# prog_path.push(next_screen) unless prog_path[-1] == next_screen
	end
}

button_failure[0].signal_connect("clicked") {
	next_screen = 25
	forw_button.sensitive = true
	current_drivelist = AllDrives.new(false, false, false)
	smart_res, smart_available, smart_types, smart_bad, smart_reallocated, smart_seek = smart_short_summary(current_drivelist)
	fill_smart_info(current_drivelist, smart_res, smart_available, smart_types, smart_bad, smart_reallocated, smart_seek, smart_panel)
	moveon = true
	buttonbox.show_all
	if moveon == true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		# prog_path.push(next_screen) unless prog_path[-1] == next_screen
	end
}

button_failure[1].signal_connect("clicked") {
	forw_button.sensitive = true
	next_screen = 31
	moveon = true
	buttonbox.show_all
	if moveon == true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		# prog_path.push(next_screen) unless prog_path[-1] == next_screen
	end
}

button_failure[2].signal_connect("clicked") {
	forw_button.sensitive = true
	next_screen = 32
	moveon = true
	buttonbox.show_all
	if moveon == true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		# prog_path.push(next_screen) unless prog_path[-1] == next_screen
	end
}

clean_buttons[0].signal_connect("clicked") {
	forw_button.sensitive = true
	next_screen = 19
	method = "fast"
	clean_drives_desc.text = extract_lang_string("clean_partition_select")
	clean_combo[0].active = true
	clean_checkboxes, current_drivelist = fill_clean_list(drive_box, method)
	# clean_pgbars, clean_vtes = fill_clean_pgbars(clean_panel, method, current_drivelist, clean_checkboxes)
	buttonbox.show_all
	moveon = true
	if moveon == true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		# prog_path.push(next_screen) unless prog_path[-1] == next_screen
	end
	
}

clean_buttons[1].signal_connect("clicked") {
	forw_button.sensitive = true
	next_screen = 19
	method = "full"
	clean_drives_desc.text = extract_lang_string("clean_drive_select")
	clean_combo[1].active = true
	clean_checkboxes, current_drivelist = fill_clean_list(drive_box, method)
	# clean_pgbars, clean_vtes = fill_clean_pgbars(clean_panel, method, current_drivelist, clean_checkboxes)
	buttonbox.show_all
	moveon = true
	if moveon == true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		# prog_path.push(next_screen) unless prog_path[-1] == next_screen
	end
}

forw_button.signal_connect("clicked") {
	puts prog_path.join(", ")
	moveon = false
	next_screen = page_order(current_page, radio_buttons, radio_failure, skipstart)
	if next_screen == 1 && skipstart == false
		create_swap(swap_sticks[swap_combo.active])
		buttonbox.hide_all
		reboot_box.show_all
		moveon = true
	elsif next_screen == 1
		buttonbox.hide_all
		reboot_box.show_all
		moveon = true
	elsif next_screen == 7
		clone_source_drives, clone_source_metas = reread_full_drives(rest_source, [])
		moveon = true
	elsif next_screen == 22 
		clone_target_drives, clone_target_metas = reread_full_drives(rest_targets, [ clone_source_drives[rest_source.active] ])
		moveon = true
	elsif next_screen == 23
		msg = ""
		puts clone_source_metas[clone_source_drives[rest_source.active]].last_partend.to_s
		# puts clone_source_drives[rest_source.active]
		# puts clone_source_drives
		# puts rest_source.active
		# puts clone_target_metas[clone_target_drives[rest_targets.active]].size.to_s
		moveon = dialog_clone_compare(window, clone_target_metas[clone_target_drives[rest_targets.active]], 
			clone_source_metas[clone_source_drives[rest_source.active]])
		### moveon = false
		if moveon == true
			back_button.sensitive = false
			forw_button.sensitive = false
			buttonbox.hide_all
			restore_finished = false
			screens.each { |s| s.hide_all }
			screens[next_screen].show_all
			prog_path.push(current_page)
			current_page = next_screen
			rest_stop.sensitive = true
			rest_tgt_prog.text = extract_lang_string("clone_in_progress")
			restore_vte.fork_command("ddrescue", ["ddrescue", "--force", 
				clone_source_drives[rest_source.active], clone_target_drives[rest_targets.active]  ])
			restore_vte.signal_connect("child_exited") { 
				restore_finished = true
			}
			while restore_finished == false
				rest_tgt_prog.pulse
				while (Gtk.events_pending?)
					Gtk.main_iteration
				end
				sleep 0.1
			end
			rest_tgt_prog.fraction = 100
			next_screen = 24
			reboot_box.hide_all
			buttonbox.show_all
			forw_button.sensitive = false
			back_button.sensitive = true
		end
	elsif next_screen == 19
		method = "fast"
		method = "full" if clean_combo[1].active?
		if method == "fast"
			clean_drives_desc.text = extract_lang_string("clean_partition_select")
		else
			clean_drives_desc.text = extract_lang_string("clean_drive_select")
		end
		clean_checkboxes, current_drivelist = fill_clean_list(drive_box, method)
		# clean_pgbars, clean_vtes = fill_clean_pgbars(clean_panel, method, current_drivelist)
		moveon = true
	elsif next_screen == 20
		method = "fast"
		method = "full" if clean_combo[1].active?
		cleancount = 0
		clean_checkboxes.each { |k,v|
			if v.active?
				puts "Clean  " + k
				cleancount += 1
			else
				puts "Ignore " + k
 			end
		}
		clean_pgbars, clean_vtes = fill_clean_pgbars(clean_panel, method, current_drivelist, clean_checkboxes)
		if cleancount < 1
			dialog_empty_clean(window)
			moveon = false
		else	
			buttonbox.hide_all
			moveon = dialog_clean_warn(window, method)
			if moveon == true
				screens.each { |s| s.hide_all }
				screens[next_screen].show_all
				prog_path.push(current_page) unless prog_path[-1] == current_page
				current_page = next_screen
				run_clean(method, clean_pgbars, clean_vtes, current_drivelist, clean_checkboxes, back_button, forw_button)
				reboot_box.show_all
				next_screen = 21
			end
		end
	elsif next_screen == 21 
		moveon = true
	elsif next_screen == 4
		current_drivelist = AllDrives.new(false, false, false)
		sysparts = find_win_sysparts(current_drivelist)
		chntpw_parts = fill_chntpw_combo(chntpw_combo, sysparts) 
		if chntpw_parts.size < 1
			forw_button.sensitive = false
		end
		moveon = true
	elsif next_screen == 12	
		puts chntpw_parts[chntpw_combo.active]
		nt_users = get_nt_users(chntpw_parts[chntpw_combo.active], current_drivelist)
		fill_ntuser_combo(user_combo, nt_users)
		moveon = true
	elsif next_screen == 13
		puts nt_users[user_combo.active][0]
		### system("bash ./run_chntpw.sh")
		run_chntpw(chntpw_parts[chntpw_combo.active], nt_users[user_combo.active], current_drivelist)
		# back_button.sensitive = false
		buttonbox.hide_all
		reboot_box.show_all
		moveon = true
	elsif next_screen == 3
		photorec_drives = fill_photorec_combo(photorec_combo, AllDrives.new(false, false, false))
		forw_button.sensitive = false if photorec_drives.size < 1 
		moveon = true
	elsif next_screen == 8
		moveon = true
	elsif next_screen == 9
		types_selected = false
		photorec_ftypes.each { |t| 
			puts t.active?.to_s
			types_selected = true if t.active? == true
		}
		if types_selected == false
			moveon = dialog_photorec_allornothing(window)
		else
			moveon = true
			current_drivelist = AllDrives.new(true, false, false)
			photorec_targets = fill_photorec_targets(photorec_tgt_combo, current_drivelist, 
				photorec_drives[photorec_combo.active], 1_000_000_000)
			
		end
	elsif next_screen == 10
		if photorec_targets.size < 1
			dialog_photorec_notarget(window)
			moveon = false
		else
			moveon = true
			buttonbox.hide_all
			screens.each { |s| s.hide_all }
			screens[next_screen].show_all
			prog_path.push(current_page) unless prog_path[-1] == current_page
			current_page = next_screen
			run_photorec(photorec_drives[photorec_combo.active], get_photorec_categories(photorec_ftypes, m_ftypes),
				photorec_targets[photorec_tgt_combo.active], current_drivelist, 
				photorec_vte, forw_button, photorec_prog, window)
			next_screen = 11
			reboot_box.show_all
		end
	elsif next_screen == 5
		@wlan_interface = fill_wlan_combo(wlan_combo, get_networks)
		skip_wlan.active = true if @wlan_interface.nil?
		moveon = true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		dialog_nonet(window) if @wlan_interface.nil?
		# puts prog_path.join(" - ") + " + " + current_page.to_s
	elsif next_screen == 14 # && prog_path[-1] == 5
		puts "Geeeh... moving to 14"
		puts "Geeeh... current page " + current_page.to_s
		puts "Geeeh... prog path " + prog_path.join(", ")
		puts "Geeeh... " +  skip_wlan.active?.to_s
		if skip_wlan.active? == false && check_network == false && ( prog_path.include?(5) || current_page == 5 )
			puts "Geeeh... connecting!"
			buttonbox.hide_all
			window_net_connect(window, wlan_combo.active_text, wlan_key.text, [ forw_button, back_button] )
			screens.each { |s| s.hide_all }
			screens[next_screen].show_all
			prog_path.push(current_page) unless prog_path[-1] == current_page
			current_page = next_screen
			puts prog_path.join(" - ") + " + " + current_page.to_s
			run_virus_signature_update(upd_vte, upd_progbar, [ forw_button, back_button], @virus_scanner, window)
			next_screen = 35
			buttonbox.show_all
		elsif skip_wlan.active? == true
			next_screen = 15
			buttonbox.hide_all
			screens.each { |s| s.hide_all }
			screens[next_screen].show_all
			prog_path.push(current_page) unless prog_path[-1] == current_page
			current_page = next_screen
			puts prog_path.join(" - ") + " + " + current_page.to_s
			run_virusscan(scan_vte, scan_progbar, [ forw_button, back_button], @virus_scanner, virus_archive, @virus_delete, @virus_kill)
			next_screen = page_order(current_page, radio_buttons, radio_failure, skipstart)
			begin
				virus_list_field.buffer.text = File.new("/tmp/kaspersky_infected.log", "r").read if @virus_scanner == "kaspersky"
				virus_list_field.buffer.text = File.new("/tmp/clamscan.log", "r").read if @virus_scanner == "clamav"
			rescue
				virus_list_field.buffer.text = extract_lang_string("missing_log")
			end
			virus_del_summary.text = virus_human_stats(@virus_scanner)
			reboot_box.show_all
			moveon = true
		else
			buttonbox.hide_all
			screens.each { |s| s.hide_all }
			screens[next_screen].show_all
			prog_path.push(current_page) unless prog_path[-1] == current_page
			current_page = next_screen
			puts prog_path.join(" - ") + " + " + current_page.to_s
			run_virus_signature_update(upd_vte, upd_progbar, [ forw_button, back_button], @virus_scanner, window)
			next_screen = 35
			buttonbox.show_all
		end
		moveon = true
	elsif next_screen == 15
		buttonbox.hide_all
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		run_virusscan(scan_vte, scan_progbar, [ forw_button, back_button], @virus_scanner, virus_archive, @virus_delete, @virus_kill)
		next_screen = page_order(current_page, radio_buttons, radio_failure, skipstart)
		begin
			virus_list_field.buffer.text = File.new("/tmp/kaspersky_infected.log", "r").read
		rescue
			virus_list_field.buffer.text = extract_lang_string("missing_log")
		end
		virus_del_summary.text = virus_human_stats(@virus_scanner)
		reboot_box.show_all
		moveon = true
	elsif next_screen == 25
		current_drivelist = AllDrives.new(false, false, false)
		smart_res, smart_available, smart_types, smart_bad, smart_reallocated, smart_seek = smart_short_summary(current_drivelist)
		fill_smart_info(current_drivelist, smart_res, smart_available, smart_types, smart_bad, smart_reallocated, smart_seek, smart_panel)
		moveon = true
	elsif next_screen == 26
		smart_stop.sensitive = true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		current_drivelist = AllDrives.new(false, false, false)
		buttonbox.hide_all
		@bad_drives = run_smart_check(current_drivelist, smart_pgbar, [ forw_button, back_button])
		smart_src_checks, smart_tgt_drives, smart_tgt_combos = fill_smart_clone_panel(smart_clone_panel, current_drivelist, @bad_drives)
		next_screen = 30
		next_screen = 27 if @bad_drives.size > 0 || @simulate.include?("smartfail")
		buttonbox.show_all
		if next_screen == 30
			smart_run_ntfsfix(current_drivelist)
			# buttonbox.hide_all
			# reboot_box.show_all
			buttonbox.show_all
			reboot_box.hide_all
			forw_button.sensitive = false
		end
		moveon = true
	elsif next_screen == 27
		buttonbox.show_all
		moveon = true
	elsif next_screen == 28
		moveon = false
		src_found = false
		smart_targets = Hash.new
		smart_src_checks.each{ |k,v|
			src_found = true if v.active?
		}
		if src_found == false
			smart_no_src_dialog(window)
			moveon = false
		elsif smart_tgt_drives.to_a[0][1].size < 1
			smart_no_tgt_dialog(window)
			moveon = false
		else
			moveon = true
			smart_src_checks.each { |k,v|
				if v.active? == true
					src = k
					tgt = smart_tgt_drives[k][smart_tgt_combos[k].active]
					puts "cloning " + src + " to " +  tgt
					if smart_tgt_not_empty(tgt, current_drivelist)
						cont = smart_tgt_not_empty_dialog(window, tgt)
						smart_targets[src] = tgt if cont == true
					elsif smart_targets.has_value?(tgt)
						smart_mult_tgt_dialog(window)
						moveon = false
					else
						smart_targets[src] = tgt
					end
				end
			}
		
		end
		if moveon == true
			screens.each { |s| s.hide_all }
			screens[next_screen].show_all
			prog_path.push(current_page) unless prog_path[-1] == current_page
			current_page = next_screen
			puts prog_path.join(" - ") + " + " + current_page.to_s
			clone_stop.sensitive = true
			buttonbox.hide_all
			smart_run_ddrescue(clone_vte, clone_pgbar, smart_targets, [forw_button, back_button] )
			reboot_box.show_all
			next_screen = 29
		end
	elsif next_screen == 30
		current_drivelist = AllDrives.new(false, false, false)
		smart_run_ntfsfix(current_drivelist)
		buttonbox.hide_all
		reboot_box.show_all
		moveon = true
	elsif next_screen == 34
		# continue = dialog_bootsect_warn(window)
		continue = true
		if continue == true
			current_drivelist = AllDrives.new(false, false, false)
			bootsect_success = run_bootsect_restore(current_drivelist)
			next_screen = 33 if bootsect_success == true
		end
		buttonbox.hide_all
		reboot_box.show_all
		moveon = true
	else
		moveon = true
	end
	if moveon == true
		screens.each { |s| s.hide_all }
		screens[next_screen].show_all
		prog_path.push(current_page) unless prog_path[-1] == current_page
		current_page = next_screen
		puts prog_path.join(" - ") + " + " + current_page.to_s
		# prog_path.push(next_screen) unless prog_path[-1] == next_screen
	end
	if prog_path[-1] == 30
		run_kexec_memtest
	end
}

rest_src_reread.signal_connect("clicked") {
	clone_source_drives = reread_full_drives(rest_source, [])
}

rest_tgt_reread.signal_connect("clicked") {
	clone_target_drives = reread_full_drives(rest_targets, [ clone_source_drives[rest_source.active] ])
}

photorec_reread.signal_connect("clicked") {
	current_drivelist = AllDrives.new(false, false, false)
	photorec_drives = fill_photorec_combo(photorec_combo, current_drivelist)
}

photorec_tgt_reread.signal_connect("clicked") {
	current_drivelist = AllDrives.new(true, false, false)
	photorec_targets = fill_photorec_targets(photorec_tgt_combo, current_drivelist, photorec_drives[photorec_combo.active])
}

smart_stop.signal_connect("clicked") {
	current_drivelist = AllDrives.new(false, false, false)
	current_drivelist.drive_list.each { |k,v|
		system("smartctl -X " + k)
	}
	smart_pgbar.text = "Der Selbsttest wird abgebrochen."
	smart_stop.sensitive = false
}

smart_tgt_reread.signal_connect("clicked") {
	current_drivelist = AllDrives.new(false, false, false)
	# smart_src_checks, smart_tgt_drives, smart_tgt_combos = fill_smart_clone_panel(smart_clone_panel, current_drivelist, @bad_drives)
	smart_tgt_drives = update_smart_clone_panel(smart_tgt_combos, current_drivelist, @bad_drives)
}

swap_button.signal_connect("clicked") {
	current_drivelist = AllDrives.new(false, false, false)
	swap_sticks = reread_swap_drives(current_drivelist, swap_combo)
	if swap_sticks.size > 0
		forw_button.sensitive = true
		back_button.sensitive = true 
	end
}

clone_stop.signal_connect("clicked") {
	pid_to_kill = ` cat /var/run/lesslinux/ddrescue.pid `
	system("kill -9 " + pid_to_kill)
	system("killall -9 ddrescue")
	system("rm /var/run/lesslinux/ddrescue.log")
	system("rm /var/run/lesslinux/ddrescue.pid")
	clone_stop.sensitive = false
}

rest_stop.signal_connect("clicked") {
	rest_stop.sensitive = false
	system("killall ddrescue")
	sleep 2
	system("killall -9 ddrescue")
}

ntfsfix_button.signal_connect("clicked") {
	ntfsfix_button.sensitive = false
	current_drivelist = AllDrives.new(false, false, false)
	smart_run_ntfsfix(current_drivelist)
	dialog_ntfsfix_done(window)
}

Gtk.main
