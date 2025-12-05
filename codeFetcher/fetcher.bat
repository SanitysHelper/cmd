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
        set /A count+=1
    )
) else (
    echo (no directories saved yet)
)

REM Menu: [0] = Enter new directory, [1..N] = existing dirs
echo [0] = Enter new directory
if %count% GTR 0 (
    for /L %%I in (0,1,%count%-1) do (
        set /A idx=%%I+1
        for /f "delims=" %%P in ("!DIR_%%I!") do (
            echo [!idx!] = %%P
        )
    )
) else (
    echo (no saved directories yet beyond [0])
)
echo.

:ASK_INDEX
set "choice="
set /P "choice=Enter directory index: "

REM default to 0 (new) if blank
if "%choice%"=="" (
    set "choice=0"
)

REM 0 => new directory
if "%choice%"=="0" goto NEW_DIR

REM try to match an existing index (1..count)
set "ROOT="
if %count% GTR 0 (
    for /L %%I in (0,1,%count%-1) do (
        set /A idx=%%I+1
        if "%choice%"=="!idx!" (
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
            REM Skipping binary-ish file
            >nul echo Skipping binary file: %%~nxF
        )
    )
)

echo.
echo Done writing "%OUTFILE%".
echo.

REM ==========================================================
REM  OPTIONAL COPY TO CLIPBOARD
REM ==========================================================
set "ans="
set /P "ans=Press ENTER to copy dump to clipboard, or type anything then ENTER to skip: "

if "%ans%"=="" (
    echo Copying contents to clipboard...
    powershell -NoProfile -Command "Get-Content -Raw '%OUTFILE%' | Set-Clipboard" >nul 2>&1

    if errorlevel 1 (
        echo ⚠️ Could not copy automatically.
        echo You can open "%OUTFILE%" and copy from there.
    ) else (
        echo ✅ Dump copied to clipboard.
        echo You can paste it directly into ChatGPT.
    )
) else (
    echo Clipboard copy skipped.
    echo Dump is saved at:
    echo   "%OUTFILE%"
)

echo.
pause
endlocal
