@echo off
setlocal enabledelayedexpansion

REM ==========================================================
REM  CONFIG
REM ==========================================================
set "SCRIPT_DIR=%~dp0"
set "DIRLIST=%SCRIPT_DIR%dumpDirectories.txt"
set "OUTFILE=%SCRIPT_DIR%dump_output.txt"

del "%OUTFILE%" 2>nul

REM ==========================================================
REM  LOAD / ASK FOR DIRECTORY
REM ==========================================================
echo === Stored directories ===

set /A count=0
if exist "%DIRLIST%" (
    for /f "usebackq delims=" %%D in ("%DIRLIST%") do (
        set "DIR_!count!=%%D"
        echo [!count!] = %%D
        set /A count+=1
    )
) else (
    echo (no directories saved yet)
)

echo [%count%] = Enter new directory
echo.

:ASK_INDEX
set "choice="
set /P "choice=Enter directory index: "

if "%choice%"=="" (
    set "choice=%count%"
)

REM if choice is the "new" option:
if "%choice%"=="%count%" goto NEW_DIR

REM try to match an existing index
set "ROOT="
if %count% GTR 0 (
    for /L %%I in (0,1,%count%-1) do (
        if "%choice%"=="%%I" (
            set "ROOT=!DIR_%%I!"
        )
    )
)

if not defined ROOT (
    echo Invalid selection. Try again.
    goto ASK_INDEX
)

goto HAVE_ROOT


:NEW_DIR
echo Enter a new directory path (where the files you want to dump live).
set "ROOT="
:READ_NEW_DIR
set /P "ROOT=Directory path: "
if "%ROOT%"=="" (
    echo Please type a path.
    goto READ_NEW_DIR
)

REM strip quotes if the user typed them
set "ROOT=%ROOT:"=%"

if not exist "%ROOT%" (
    echo That path does not exist. Try again.
    set "ROOT="
    goto READ_NEW_DIR
)

REM normalize to full path
for %%P in ("%ROOT%") do set "ROOT=%%~fP"

REM append to directory list if it's not already there
set "already=0"
if exist "%DIRLIST%" (
    for /f "usebackq delims=" %%D in ("%DIRLIST%") do (
        if /I "%%D"=="%ROOT%" set "already=1"
    )
)
if "%already%"=="0" (
    echo %ROOT%>>"%DIRLIST%"
)

:HAVE_ROOT
echo.
echo Using directory: %ROOT%
echo Dump file will be: %OUTFILE%
echo.

REM ==========================================================
REM  NORMALIZE ROOT (remove trailing backslash)
REM ==========================================================
set "ROOT_NORM=%ROOT%"
if "%ROOT_NORM:~-1%"=="\" set "ROOT_NORM=%ROOT_NORM:~0,-1%"

REM ==========================================================
REM  DUMP ALL FILES (SKIP OUTFILE + BINARY TYPES)
REM ==========================================================
echo Dumping files (text-like only)...
echo.

REM Define binary extensions to skip (case-insensitive)
set "SKIPLIST=.exe .dll .bin .jpg .jpeg .png .gif .bmp .ico .zip .rar .7z .mp3 .wav .flac .ogg .m4a .pdf .doc .docx .xls .xlsx .ppt .pptx .ttf .otf .pak .obj .lib .pyc .pyo .iso .img .msi"

for /r "%ROOT%" %%F in (*) do (
    REM Skip our own output file
    if /I not "%%~fF"=="%OUTFILE%" (
        set "EXT=%%~xF"
        set "SKIP=0"
        for %%S in (%SKIPLIST%) do (
            if /I "%%S"=="!EXT!" set "SKIP=1"
        )
        if !SKIP! EQU 0 (
            set "FULL=%%~fF"
            set "REL=!FULL:%ROOT_NORM%\=!"
            >>"%OUTFILE%" echo ==========================================================
            >>"%OUTFILE%" echo path: !REL!
            >>"%OUTFILE%" echo ==========================================================
            >>"%OUTFILE%" echo(
            type "%%~fF" >>"%OUTFILE%"
            >>"%OUTFILE%" echo(
        ) else (
            echo Skipping binary file: %%~nxF >nul
        )
    )
)

echo.
echo Done writing "%OUTFILE%".
echo.

REM ==========================================================
REM  COPY TO CLIPBOARD (if possible)
REM ==========================================================
echo Trying to copy contents to clipboard...
powershell -NoProfile -Command "Get-Content -Raw '%OUTFILE%' | Set-Clipboard" >nul 2>&1

if %errorlevel%==0 (
    echo ✅ Dump copied to clipboard.
    echo You can paste it directly into ChatGPT.
) else (
    echo ⚠️ Could not copy automatically.
    echo You can open "%OUTFILE%" and copy from there.
)

echo.
pause
endlocal
