@echo off

REM ===================================================================================================================

REM Define the path to vswhere
set "VSWHERE=C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"

REM Find the path to Visual Studio
for /f "usebackq delims=" %%i in (`"%VSWHERE%" -latest -property installationPath`) do (
    set "VS_PATH=%%i"
    goto :SetEnvironment
)

:SetEnvironment
REM Check if Visual Studio was found
if "%VS_PATH%"=="" (
    echo Visual Studio not found.
    exit /b
)

REM Notify user
echo Visual Studio found at %VS_PATH%

REM ===================================================================================================================

SETLOCAL

REM Run the script to set up the environment variables
call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x64

REM Build detours
cd Detours
SET DETOURS_TARGET_PROCESSOR=X64
nmake clean
nmake
cd ..

rem Set compilation variables
set INCLUDE_PATH="Detours\include"
set LIB_PATH="Detours\lib.X64"
set OUTPUT_FILE="BetterRandom_x64.dll"
set INPUT_FILE="BetterRandom.cpp"
set LIB_FILES="detours.lib Dbghelp.lib user32.lib"

rem Compile the code using cl.exe
cl.exe /O2 /EHsc /LD /I "%INCLUDE_PATH%" /Fe:"%OUTPUT_FILE%" "%INPUT_FILE%" /link /LIBPATH:"%LIB_PATH%" "%LIB_FILES%"

ENDLOCAl

REM ===================================================================================================================

SETLOCAL

REM Run the script to set up the environment variables
call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x86

REM Build detours
cd Detours
SET DETOURS_TARGET_PROCESSOR=X86
nmake clean
nmake
cd ..

rem Set compilation variables
set INCLUDE_PATH="Detours\include"
set LIB_PATH="Detours\lib.X86"
set OUTPUT_FILE="BetterRandom_x86.dll"
set INPUT_FILE="BetterRandom.cpp"
set LIB_FILES="detours.lib Dbghelp.lib user32.lib"

rem Compile the code using cl.exe
cl.exe /O2 /EHsc /LD /I "%INCLUDE_PATH%" /Fe:"%OUTPUT_FILE%" "%INPUT_FILE%" /link /LIBPATH:"%LIB_PATH%" "%LIB_FILES%"

ENDLOCAL

REM ===================================================================================================================

REM Clear and create build directory
rmdir /S /Q build
mkdir build

REM ===================================================================================================================

REM Move final files into build directory
copy Detours\LICENSE.md build\LICENSE.Detours
copy LICENSE build\LICENSE.BetterRandom
copy README.md build
copy BetterRandom.bat build
copy Detours\bin.X64\setdll.exe build\setdll_x64.exe
copy Detours\bin.X86\setdll.exe build\setdll_x86.exe
move BetterRandom_x64.dll build
move BetterRandom_x86.dll build

REM ===================================================================================================================

REM cleanup build intermediate files
del BetterRandom_x64.exp
del BetterRandom_x86.exp
del BetterRandom_x64.lib
del BetterRandom_x86.lib
del BetterRandom.obj

REM ===================================================================================================================

REM Clean up Detours
rmdir /S /Q Detours\bin.X64
rmdir /S /Q Detours\bin.X86
rmdir /S /Q Detours\lib.X64
rmdir /S /Q Detours\bin.X86
rmdir /S /Q Detours\include
cd Detours
SETLOCAL
SET DETOURS_TARGET_PROCESSOR=X64
call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x64
nmake clean
ENDLOCAl
SETLOCAL
SET DETOURS_TARGET_PROCESSOR=X86
call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x86
nmake clean
ENDLOCAl
cd ..
