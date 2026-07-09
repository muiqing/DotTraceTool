@echo off
:: ============================================
:: WER LocalDumps 配置脚本（配置文件版）
:: 配置文件: CrashDump.ini
:: ============================================
cd /d "%~dp0"

:: 检查管理员权限
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] 请以管理员身份运行此脚本！
    pause
    exit /b 1
)

:: 检查配置文件
if not exist "CrashDump.ini" (
    echo [ERROR] 未找到配置文件 CrashDump.ini
    pause
    exit /b 1
)

:: 读取配置
for /f "usebackq tokens=1,* delims==" %%a in ("CrashDump.ini") do (
    set "%%a=%%b"
)

:: 校验必填项
if not defined AppName (
    echo [ERROR] 配置缺少 AppName
    pause
    exit /b 1
)
if not defined DumpFolder (
    echo [ERROR] 配置缺少 DumpFolder
    pause
    exit /b 1
)
if not defined DumpCount (
    echo [ERROR] 配置缺少 DumpCount
    pause
    exit /b 1
)
if not defined DumpType (
    echo [ERROR] 配置缺少 DumpType
    pause
    exit /b 1
)

:: 确保 Dump 目录存在
if not exist "%DumpFolder%" mkdir "%DumpFolder%"

:: 启动 WER 服务
SC CONFIG WerSvc START= AUTO
NET START WerSvc 2>nul
ECHO [OK] WER Service started.

:: 移除 JIT Debugger
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AeDebug" /v Debugger /f 2>nul
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework" /v DbgManagedDebugger /f 2>nul
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows NT\CurrentVersion\AeDebug" /v Debugger /f 2>nul
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework" /v DbgManagedDebugger /f 2>nul
ECHO [OK] JIT Debugger removed.

:: 配置 LocalDumps
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\%AppName%" /f
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\%AppName%" /t REG_SZ /v DumpFolder /d "%DumpFolder%" /f
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\%AppName%" /t REG_DWORD /v DumpCount /d %DumpCount% /f
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting\LocalDumps\%AppName%" /t REG_DWORD /v DumpType /d %DumpType% /f

ECHO.
ECHO [OK] LocalDumps configured:
ECHO     AppName:    %AppName%
ECHO     DumpFolder: %DumpFolder%
ECHO     DumpCount:  %DumpCount%
ECHO     DumpType:   %DumpType%

PAUSE
