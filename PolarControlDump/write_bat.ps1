$content = @"
@echo off
SET DMPPATH=%cd%\AppData\Roaming\PolarControl\Dump

SC CONFIG WerSvc START= AUTO
NET START WerSvc 2>nul
ECHO 服务启用完成

REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug" /v Debugger /f 2>nul
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework" /v DbgManagedDebugger /f 2>nul

REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\AeDebug" /v Debugger /f 2>nul
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework" /v DbgManagedDebugger /f 2>nul

ECHO 删除完成

REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\PolarControl.exe" /f
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\PolarControl.exe" /t REG_SZ /v DumpFolder /d "%DMPPATH%" /f
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\PolarControl.exe" /t REG_DWORD /v DumpCount /d 2 /f
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\PolarControl.exe" /t REG_DWORD /v DumpType /d 2 /f

ECHO 配置完成

PAUSE
"@

$outputPath = "C:\Users\jiajun.wu\Desktop\dottrace\PolarControlDump\PolarControlDump.bat"
[System.IO.File]::WriteAllText($outputPath, $content, [System.Text.Encoding]::GetEncoding('GBK'))
Write-Host "Done - file saved with GBK encoding"
