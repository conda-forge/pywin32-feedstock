setlocal enabledelayedexpansion
REM NOTE: this calls python files directly during the build process, relying on your file associations.
REM    when building this recipe, you need to associate python files with C:\aroot\stage\pythonw.exe for best results.

set UCRT_BUILD=1

if %UCRT_BUILD%==1 (
    powershell.exe -ExecutionPolicy Unrestricted -Command "& {Invoke-WebRequest -Uri https://download.microsoft.com/download/B/6/4/B645F2C9-715A-4EAB-B561-CC0C9779C249/Outlook2010MAPIHeaders.EXE -OutFile Outlook2010MAPIHeaders.EXE}"
    Outlook2010MAPIHeaders.EXE /T:%CD%\Outlook2010MAPIHeaderFiles /C /Q
    pushd %CD%\Outlook2010MAPIHeaderFiles
        bsdtar -xf OUTLOO~1.EXE
    popd
    set "INCLUDE=%INCLUDE%%CD%\Outlook2010MAPIHeaderFiles;"
)

%PYTHON% setup.py install
if %errorlevel% neq 1 exit /b 1

:: below here, we copy MFC and ATL redistributable DLLs into places that should be on PATH
set VC_PATH=x86
if "%ARCH%"=="64" (
    set VC_PATH=x64
)

if %UCRT_BUILD%==1 (
    set MSC_VER=14
) else (
    set MSC_VER=10
    if %PY_VER% == 2.7 (
        set MSC_VER=9
        if "%ARCH%"=="64" (
            set VC_PATH=amd64
        )
    )
)

:: Fix for https://sourceforge.net/p/pywin32/mailman/message/29498528/
:: although on that bug report Glenn Linderman claims this fix does
:: not work, it seems to work fine. I attempted a fix in the source
:: code (and the upstream developers have clearly thought about it)
:: but the fact is win32api auto-imports pywintypes??.dll as can be
:: seen from:
:: ntldd.exe /c/aroot/stage/Lib/site-packages/win32/win32api.pyd
::         pywintypes36.dll => not found
:: due to: win32/src/PyWinTypes.h:
:: define PYWINTYPES_EXPORT __declspec(dllimport)
:: .. and ..
:: pragma comment(lib,"pywintypes.lib")
::  .. and then (at least): win32/src/win32apimodule.cpp
:: PYWINTYPES_EXPORT PyObject *PyWin_NewUnicode(PyObject *self, PyObject *args);
:: therefore copying is the only recourse. At first glance, it may
:: seem that moving these DLLs would work, but _win32sysloader.cpp
:: expects to find two DLLs in site-packages/pywin32_system32
:: My attempted fix is in import-pywintypes-from-win32api.patch
:: An actual fix would be to make win32api a Python module that
:: first imports pywintypes and after that imports _win32api.
copy %PREFIX%\Lib\site-packages\pywin32_system32\*.dll %PREFIX%\Lib\site-packages\win32\

robocopy "C:\Program Files (x86)\Microsoft Visual Studio %MSC_VER%.0\VC\redist\%VC_PATH%\Microsoft.VC%MSC_VER%0.MFC" "%LIBRARY_BIN%" *.dll /E
:: UCRT has no ATL dlls: https://msdn.microsoft.com/en-us/library/ms235284(v=vs.140).aspx
if %UCRT_BUILD%==1 goto no_atl_dlls
robocopy "C:\Program Files (x86)\Microsoft Visual Studio %MSC_VER%.0\VC\redist\%VC_PATH%\Microsoft.VC%MSC_VER%0.ATL" "%LIBRARY_BIN%" *.dll /E
:no_atl_dlls

if %PY3K%==1 (
   del %PREFIX%\Lib\lib2to3\*.pickle
)

:: I have no idea why sometimes, at random, these do not get copied. They are neccesary!
copy %PREFIX%\Lib\site-packages\pywin32_system32\*.dll %LIBRARY_BIN%\
