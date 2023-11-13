@echo off
echo SmallXP Installer [Version 1.1] by DestroyTheOS
set /p driveLetter=Drive Letter: 
%driveLetter%:
(echo Creating Directory Structure... && mkdir WINDOWS && cd WINDOWS && mkdir AppPatch && mkdir Fonts && mkdir system && mkdir system32 && echo DONE && cd system32 && mkdir config && mkdir drivers && cd..) || echo FAIL 
(echo Copying Root Files... && copy C:\WINDOWS\explorer.exe %driveLetter%:\WINDOWS\ > nul && echo DONE) || echo FAIL
(echo Copying Files to AppPatch Folder... && copy C:\WINDOWS\AppPatch\drvmain.sdb %driveLetter%:\WINDOWS\AppPatch\ > nul && echo DONE) || echo FAIL
(echo Copying Windows Fonts... && copy C:\WINDOWS\Fonts\vgaoem.fon %driveLetter%:\WINDOWS\Fonts\ > nul && echo DONE) || echo FAIL && echo IMPORTANT: Unable to locate vgaoem.fon file in Fonts Directory. Please download this file at https://www.destroytheos.net/vgaoem.fon and add this manually to "%driveLetter%:\WINDOWS\Fonts".
(echo Copying Win16 Files... && copy C:\WINDOWS\Fonts\vgaoem.fon %driveLetter%:\WINDOWS\system\ > nul && echo DONE) || echo FAIL && echo IMPORTANT: Unable to locate vgaoem.fon file in Win16 Directory. Please download this file at https://www.destroytheos.net/vgaoem.fon and add this manually to "%driveLetter%:\WINDOWS\system".
echo Copying Windows System Files...
copy C:\WINDOWS\system32\advapi32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\advpack.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\atmpvcno.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\atrace.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\audiosrv.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\authz.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\basesrv.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\bootvid.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\browseui.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\comctl32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\comdlg32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\crypt32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\cryptdll.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\cryptui.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\csrsrv.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\csrss.exe %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\ctype.nls %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\c_1252.nls %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\c_437.nls %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\dnsapi.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\dpcdll.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\eventlog.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\FNTCACHE.DAT %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\gdi32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\hal.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\iertutil.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\imagehlp.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\iphlpapi.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\kdcom.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\kernel32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\locale.nls %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\lsasrv.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\lsass.exe %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\lz32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\l_intl.nls %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\mpr.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\msasn1.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\msgina.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\msprivs.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\msv1_0.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\msvcp60.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\msvcrt.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\ncobjapi.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\nddeapi.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\netapi32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\normaliz.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\ntdll.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\ntdsapi.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\ntoskrnl.exe %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\odbc32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\odbcint.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\oembios.bin %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\oembios.dat %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\oembios.sig %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\ole32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\oleaut32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\olecli32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\olecnv32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\olesvr32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\profmap.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\psapi.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\regapi.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\regsvc.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\resutils.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\rpcrt4.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\rpcss.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\rsaenh.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\samlib.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\samsrv.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\scesrv.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\secupd.dat %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\secupd.sig %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\secur32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\services.exe %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\setupapi.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\shdocvw.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\shell32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\shlwapi.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\shsvcs.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\smss.exe %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\sortkey.nls %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\sorttbls.nls %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\spoolsv.exe %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\svchost.exe %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\sxs.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\umpnpmgr.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\unicode.nls %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\url.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\urlmon.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\user32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\userenv.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\uxtheme.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\version.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\vga.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\watchdog.sys %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\win32k.sys %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\wininet.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\winlogon.exe %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\winsrv.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\winsta.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\wintrust.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\wldap32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\wow32.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\wpa.dbl %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\ws2help.dll %driveLetter%:\WINDOWS\system32\ > nul
copy C:\WINDOWS\system32\ws2_32.dll %driveLetter%:\WINDOWS\system32\ > nul
echo DONE
(echo Copying Windows Drivers... && xcopy /E /Y C:\WINDOWS\system32\drivers\*.* %driveLetter%:\WINDOWS\system32\drivers\ > nul && echo DONE) || echo FAIL
echo Copying Windows Registry...
echo DONE
echo IMPORTANT: To copy registry, you must use a bootable CD/DVD to manually copy files from the "C:\WINDOWS\system32\config" directory to "%driveLetter%:\WINDOWS\system32\config". This batch script is unable to do this automatically as the registry files are currently in use by the system.
echo.
echo Alternatively, you can download these files at https://www.destroytheos.net/xp_reg.zip and add these manually. This method may not work as each installation will be different.
echo.
echo Press any key to exit installer && pause > nul