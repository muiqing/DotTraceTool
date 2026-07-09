@echo off
SET DMPPATH=%cd%\AppData\Roaming\PolarControl\Dump

SC CONFIG WerSvc START= AUTO
NET START WerSvc 2>nul
ECHO [OK] WER Service started.

REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug" /v Debugger /f 2>nul
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework" /v DbgManagedDebugger /f 2>nul

REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\AeDebug" /v Debugger /f 2>nul
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework" /v DbgManagedDebugger /f 2>nul

ECHO [OK] JIT Debugger removed.

REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\PolarControl.exe" /f
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\PolarControl.exe" /t REG_SZ /v DumpFolder /d "%DMPPATH%" /f
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\PolarControl.exe" /t REG_DWORD /v DumpCount /d 2 /f
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\PolarControl.exe" /t REG_DWORD /v DumpType /d 2 /f

ECHO [OK] LocalDumps config done.

PAUSE
