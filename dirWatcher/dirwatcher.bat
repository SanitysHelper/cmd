@echo off
setlocal EnableDelayedExpansion

rem ==========================================================
rem  CONFIG
rem ==========================================================
set "SCRIPT_DIR=%~dp0"
set "DIRLIST=%SCRIPT_DIR%watchDirectories.txt"
set "BATLIST=%SCRIPT_DIR%watchTargets.txt"

rem ==========================================================
rem  CHOOSE DIRECTORY
rem ==========================================================
echo ===============================================
echo   Directory Watcher - Select Watch Directory
echo ===============================================
echo.

echo [0] New directory
set /a idx=1
if exist "%DIRLIST%" (
  for /f "usebackq delims=" %%D in ("%DIRLIST%") do (
    rem Skip blank lines or corrupted 'ECHO is off.' entries
    if not "%%D"=="" if /I not "%%D"=="ECHO is off." (
      set "DIR_!idx!=%%D"
      echo [!idx!] %%D
      set /a idx+=1
    )
  )
) else (
  echo (no directories saved yet)
)
echo.
set /p "DIR_CHOICE=Select a directory by number (0 for new): "

if "%DIR_CHOICE%"=="0" (
  echo Enter the full path of the directory you want to watch:
  set /p "WATCH_DIR=Directory path: "
  if not exist "!WATCH_DIR!" (
    echo [WARN] Directory does not exist. Create it? (Y/N)
    set /p "MKDIR_CHOICE=> "
    if /i "!MKDIR_CHOICE!"=="Y" mkdir "!WATCH_DIR!"
  )
  >>"%DIRLIST%" echo !WATCH_DIR!
) else (
  for /f "tokens=1* delims==" %%A in ('set DIR_%DIR_CHOICE% 2^>nul') do set "WATCH_DIR=%%B"
)

if not defined WATCH_DIR (
  echo [ERROR] No valid directory selected.
  pause
  exit /b 1
)

echo Watching directory: "!WATCH_DIR!"
echo.

rem ==========================================================
rem  CHOOSE TARGET BAT
rem ==========================================================
echo ===============================================
echo   Select Target .BAT to Run on Change
echo ===============================================
echo.
echo [0] New target .bat
set /a tidx=1
if exist "%BATLIST%" (
  for /f "usebackq delims=" %%B in ("%BATLIST%") do (
    rem Skip blank or corrupted entries
    if not "%%B"=="" if /I not "%%B"=="ECHO is off." (
      set "BAT_!tidx!=%%B"
      echo [!tidx!] %%B
      set /a tidx+=1
    )
  )
) else (
  echo (no targets saved yet)
)
echo.
set /p "BAT_CHOICE=Select a .bat by number (0 for new): "

if "%BAT_CHOICE%"=="0" (
  echo Enter full path of the .bat file to run:
  set /p "TARGET_BAT=> "
  >>"%BATLIST%" echo !TARGET_BAT!
) else (
  for /f "tokens=1* delims==" %%A in ('set BAT_%BAT_CHOICE% 2^>nul') do set "TARGET_BAT=%%B"
)

if not defined TARGET_BAT (
  echo [ERROR] No valid target .bat selected.
  pause
  exit /b 1
)

echo Target batch file: "!TARGET_BAT!"
echo.

rem ==========================================================
rem  ASK SILENT MODE
rem ==========================================================
echo Run silently (hidden window)? [Y/N]
set /p "SILENT_MODE=> "
set "PY_SILENT=False"
if /i "%SILENT_MODE%"=="Y" set "PY_SILENT=True"
echo Silent mode: %PY_SILENT%
echo.

rem ==========================================================
rem  FIND PYTHON
rem ==========================================================
set "PY_CMD="
where py >nul 2>&1 && set "PY_CMD=py"
if not defined PY_CMD where python >nul 2>&1 && set "PY_CMD=python"
if not defined PY_CMD (
  echo [ERROR] Python not found in PATH.
  pause
  exit /b 1
)

rem ==========================================================
rem  WRITE TEMP PYTHON FILE
rem ==========================================================
set "PYFILE=%TEMP%\dirwatch_%RANDOM%.py"
> "%PYFILE%"  echo import os, time, subprocess
>>"%PYFILE%" echo.
>>"%PYFILE%" echo WATCH_DIR = r"%WATCH_DIR%"
>>"%PYFILE%" echo TARGET_BAT = r"%TARGET_BAT%"
>>"%PYFILE%" echo SILENT = %PY_SILENT%
>>"%PYFILE%" echo.
>>"%PYFILE%" echo def snapshot():
>>"%PYFILE%" echo     state = {}
>>"%PYFILE%" echo     for root, _, files in os.walk(WATCH_DIR):
>>"%PYFILE%" echo         for name in files:
>>"%PYFILE%" echo             path = os.path.join(root, name)
>>"%PYFILE%" echo             try:
>>"%PYFILE%" echo                 st = os.stat(path)
>>"%PYFILE%" echo                 state[path] = (st.st_mtime, st.st_size)
>>"%PYFILE%" echo             except OSError:
>>"%PYFILE%" echo                 pass
>>"%PYFILE%" echo     return state
>>"%PYFILE%" echo.
>>"%PYFILE%" echo def run_bat():
>>"%PYFILE%" echo     try:
>>"%PYFILE%" echo         if SILENT:
>>"%PYFILE%" echo             si = subprocess.STARTUPINFO()
>>"%PYFILE%" echo             si.dwFlags = getattr(subprocess, "STARTF_USESHOWWINDOW", 1)
>>"%PYFILE%" echo             subprocess.Popen(
>>"%PYFILE%" echo                 ["cmd", "/c", TARGET_BAT],
>>"%PYFILE%" echo                 startupinfo=si,
>>"%PYFILE%" echo                 stdout=subprocess.DEVNULL,
>>"%PYFILE%" echo                 stderr=subprocess.DEVNULL
>>"%PYFILE%" echo             )
>>"%PYFILE%" echo         else:
>>"%PYFILE%" echo             subprocess.Popen(["cmd", "/c", TARGET_BAT])
>>"%PYFILE%" echo     except Exception as e:
>>"%PYFILE%" echo         print("Error launching target:", e)
>>"%PYFILE%" echo.
>>"%PYFILE%" echo def main():
>>"%PYFILE%" echo     print(f"Watching: {WATCH_DIR}")
>>"%PYFILE%" echo     print(f"Target:   {TARGET_BAT}")
>>"%PYFILE%" echo     print(f"Silent:   {SILENT}")
>>"%PYFILE%" echo     prev = snapshot()
>>"%PYFILE%" echo     while True:
>>"%PYFILE%" echo         time.sleep(1)
>>"%PYFILE%" echo         curr = snapshot()
>>"%PYFILE%" echo         if curr == prev:
>>"%PYFILE%" echo             continue
>>"%PYFILE%" echo         print("Change detected, running batch...")
>>"%PYFILE%" echo         run_bat()
>>"%PYFILE%" echo         prev = curr
>>"%PYFILE%" echo.
>>"%PYFILE%" echo if __name__ == "__main__":
>>"%PYFILE%" echo     try:
>>"%PYFILE%" echo         main()
>>"%PYFILE%" echo     except KeyboardInterrupt:
>>"%PYFILE%" echo         print("[EXIT] Watcher stopped by user.")

rem ==========================================================
rem  RUN PYTHON WATCHER
rem ==========================================================
echo [BOOT] Starting Python watcher...
"%PY_CMD%" "%PYFILE%"

del "%PYFILE%" >nul 2>&1
endlocal
exit /b
