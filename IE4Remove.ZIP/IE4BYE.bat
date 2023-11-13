@echo YOU MUST RUN THIS PROGRAM IN PURE DOS MODE AND NOT IN WINDOWS.
@echo IT WILL RENAME SEVERAL FILE SO THAT WINDOWS WILL NOT DETECT THE
@echo IE4 BROWSER SO THAT WINDOWS CAN BE REINSTALLED SUCCESSFULLY.
@echo AFTER YOU RUN THIS PROGRAM, YOU WILL BE UNABLE TO BOOT TO
@echo WINDOWS, SO BE SURE YOU HAVE A BOOT DISK WITH CD ROM DRIVERS
@echo THAT WILL ENABLE YOU TO ACCESS YOUR INSTALL DISK. 
@echo.
@echo PRESS ANY KEY TO CONTINUE, OR PRESS ctrl+c to CANCEL.
@PAUSE > NULL
 
@echo Off
Echo "This script will remove Microsoft Internet Explorer from your computer."
Echo.
Echo "USE AT YOUR OWN RISK!" ALLOW SEVERAL MINUTES FOR IT TO COMPLETE.
Echo.
@echo PRESS ANY KEY TO CONTINUE, OR PRESS Ctrl+c TO CANCEL.
@PAUSE > NULL
@echo.
@echo NOW PROCESSING YOUR REQUEST, PLEASE WAIT FOR COMPLETION.
%WINBOOTDIR%\Command\Attrib -H -S -R /S %WINBOOTDIR%\*.* 
CD %WINBOOTDIR%\System
ren c:\windows\system\inetcpl.cpl inetcpl.old 
ren c:\windows\system\ole2.dll ole2.old 
ren c:\windows\system\ole32.dll ole32.old 
ren c:\windows\system\oleaut32.dll oleaut32.old 
ren c:\windows\system\olepro32.dll olepro32.old 
ren c:\windows\system\olethk32.dll olethk32.old 
ren c:\windows\system\setupwbv.dll setupwbv.old 
ren c:\windows\system\softpub.dll softpub.old 
ren c:\windows\system\stdole2.tlb stdole2.old 
ren c:\windows\system\urlmon.dll urlmon.old 
ren c:\windows\system\wininet.dll wininet.old 
ren c:\windows\system\wintrust.dll wintrust.old 
ren c:\windows\system\shdocvw.dll shdocvw.old 
ren c:\windows\system\shlwapi.dll shlwapi.old 
ren c:\windows\system\shell32.dll shell32.old 
 
CD %WINBOOTDIR%
 
ren explorer.exe explorer.old
Echo "Microsoft Internet Explorer has been removed from your computer."
