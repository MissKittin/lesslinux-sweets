@echo off
cd avupdate\windows
ECHO Starte Avira Updater
avupdate.exe --config=..\unix\avupdate.conf --product-file=/idx/rescuesystem_cb-linux_glibc22-en.idx --product-info-file=/idx/rescuesystem_cb-linux_glibc22-en.info.gz --skip-master-file
cd ..\..\antivir
copy /b rescue_cd.key +,,
ECHO Avira Update erfolgreich
pause
