@echo off

setlocal enabledelayedexpansion

REM BG EE: Baldur.exe
REM BG2 EE: Baldur.exe
REM IWD EE: Icewind.exe
REM Torment EE: Torment.exe
REM BG : BGMain2.exe
REM BG2 : BGMain.exe
REM IWD: IDMain.exe
REM Torment: Torment.exe

REM Check for original executables (BGMain2.exe is for BG and BGMain.exe is for BG2)
if exist "BGMain2.exe" (set "TARGET_EXE=BGMain2.exe" & goto :next)
if exist "BGMain.exe" (set "TARGET_EXE=BGMain.exe" & goto :next)
if exist "IDMain.exe" (set "TARGET_EXE=IDMain.exe" & goto :next)
if exist "Torment.exe" (set "TARGET_EXE=Torment.exe" & goto :next)

REM Check for EE executables
if exist "Baldur.exe" (set "TARGET_EXE=Baldur.exe" & goto :next)
if exist "Baldur2.exe" (set "TARGET_EXE=Baldur2.exe" & goto :next)
if exist "Icewind.exe" (set "TARGET_EXE=Icewind.exe" & goto :next)
if exist "Torment.exe" (set "TARGET_EXE=Torment.exe" & goto :next)

echo No matching executable found. Exiting...
exit /b 1

:next

REM Check if the executable is 32-bit
for /f %%G in ('powershell -NoProfile -Command "(get-content '%TARGET_EXE%' -totalcount 50) | select-string -Pattern 'PE..L' -Quiet"') do ( set "IS32EXE=%%G" )
REM Check if the executable is 64-bit
for /f %%G in ('powershell -NoProfile -Command "(get-content '%TARGET_EXE%' -totalcount 50) | select-string -Pattern 'PE..d' -Quiet"') do ( set "IS64EXE=%%G" )

REM Check for 32-bit target executable
if "%IS32EXE%"=="True" (
    set "DLL_NAME=BetterRandom_x86.dll"
    set "SETDLL=setdll_x86.exe"
    REM Additional actions for 32-bit executable...
)

REM Check for 64-bit target executable
if "%IS64EXE%"=="True" (
    set "DLL_NAME=BetterRandom_x64.dll"
    set "SETDLL=setdll_x64.exe"
    REM Additional actions for 64-bit executable...
)


REM Prompt user for action
echo 1. Add better random library to %TARGET_EXE%
echo 2. Remove better random library from %TARGET_EXE%
set /p "ACTION=Enter action number (1 or 2): "


REM Process user's choice
if "!ACTION!"=="1" (
    REM Inject the BetterRandom library using setdll.exe
    %SETDLL% /d:%DLL_NAME% %TARGET_EXE%
) else if "!ACTION!"=="2" (
    REM Remove the BetterRandom libary using setdll.exe
    echo %SETDLL%
    %SETDLL% /r %TARGET_EXE%
) else (
    echo Invalid action number. Exiting...
)

endlocal
