@echo THIS PROGRAM WILL UNINSTALL DIRECT X VERSION 7 FOR WIN 98.
@echo  IT MUST BE RUN FROM THE BASIC DOS MODE AND NOT FROM
@echo A DOS PROMPT WITHIN A WINDOWS SESSION.
@echo PRESS ANY KEY TO CONTINUE, OR PRESS Ctrl+C to CANCEL.
@PAUSE > NUL 
@echo.
@echo "This script will remove Direct X from your computer."
@echo To be run from basic DOS mode only!
echo.
Echo "USE AT YOUR OWN RISK!" ALLOW SEVERAL MINUTES FOR IT TO COMPLETE.
Echo.
@echo PRESS ANY KEY TO CONTINUE, OR PRESS Ctrl+C TO CANCEL.
@PAUSE > NUL
@echo.
@echo NOW PROCESSING YOUR REQUEST, PLEASE WAIT FOR COMPLETION.
%WINBOOTDIR%\Command\Attrib -H -S -R /S %WINBOOTDIR%\*.* 
CD %WINBOOTDIR%\System
del c:\windows\system\ddr*.*
del c:\windows\system\ddhelp.exe 
del c:\windows\system\dpwsock.dll 
del c:\windows\system\dpserial.dll 
del c:\windows\system\dsound*.*
del c:\windows\system\dplay.dll 
del c:\windows\system\dinput*.* 
del c:\windows\system\d3d*.* 
del c:\windows\system\dplayx.dll 
del c:\windows\system\dpmodemx.dll 
del c:\windows\system\dpwsockx.dll 
del c:\windows\system\vjoyd.vxd 
del c:\windows\system\joy.cpl 
del c:\windows\system\dplaysvr.exe 
del c:\windows\system\dmusic16.dll
del c:\windows\system\dmusic32.dll 
del c:\windows\system\dmusic.dll  
del c:\windows\system\dmstyle.dll  
del c:\windows\system\dmsynth.dll 

CD %WINBOOTDIR%\SYSBCKP
del c:\windows\sysbckp\ddhelp.exe 
del c:\windows\sysbckp\ddraw*.*
del c:\windows\sysbckp\dsound*.*
del c:\windows\sysbckp\dinput*.*
del c:\windows\sysbckp\d3d*.*
del c:\windows\sysbckp\dplayx.dll 
del c:\windows\sysbckp\dpmodemx.dll 
del c:\windows\sysbckp\dpwsockx.dll 
 
Echo "Direct X has been removed from your computer."
