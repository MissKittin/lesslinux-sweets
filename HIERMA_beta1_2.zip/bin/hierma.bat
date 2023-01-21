@ECHO off

REM This script checks if it is being run in the same directory.
IF NOT EXIST HIERMA.BAT GOTO NOTFOUND

ECHO If you formatted your hard disk under Linux, the MBR needs to be
ECHO overwritten at this point so your operating system will boot after
ECHO completing Setup. If you don't do this now and your OS fails to boot,
ECHO you must boot from a startup disk pertaining to the exact version of
ECHO your operating system.
ECHO.
@CHOICE /C:YNC Do you want to overwrite the MBR now
IF ERRORLEVEL 3 GOTO EXIT
IF ERRORLEVEL 2 GOTO EXECUTE
IF ERRORLEVEL 1 GOTO MBR

:MBR
ECHO Writing the MBR...
FDISK.EXE /MBR
ECHO Which boot disk are you using?
ECHO F = FreeDOS
ECHO W = Windows 9x
CHOICE /C:FW
IF ERRORLEVEL 2 GOTO WIN
IF ERRORLEVEL 1 GOTO FREEDOS

:FREEDOS
SYS.COM A: C:
GOTO EXECUTE

:WIN
SYS.COM A: C: /K IO.SYS
GOTO EXECUTE

:EXECUTE
REM Assuming this batch file is being run from the setup directory!
DEL FDISK.EXE
DEL SYS.COM
DEL CHOICE.EXE

REM Below the echo command is a special line for HIERMA to replace with your
REM required setup command, using GNU sed. DO NOT MODIFY!
@ECHO ON
<REPLACE>
GOTO EXIT
@ECHO OFF

:NOTFOUND
ECHO You must change the working directory to your setup path to run this script.

:EXIT
@ECHO OFF
