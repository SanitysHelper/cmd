@echo off
setlocal

:: ---------------------------------------------------------
:: Find Python (prefer "py", then "python")
:: ---------------------------------------------------------
set "PY_CMD="

where py >nul 2>&1
if not errorlevel 1 set "PY_CMD=py"

if not defined PY_CMD (
    where python >nul 2>&1
    if not errorlevel 1 set "PY_CMD=python"
)

if not defined PY_CMD (
    echo [ERROR] Python not found in PATH.
    pause
    exit /b 1
)

:: ---------------------------------------------------------
:: Create temporary Python script
:: ---------------------------------------------------------
set "PYFILE=%TEMP%\weather_fetch_%RANDOM%.py"

> "%PYFILE%"  echo import json
>>"%PYFILE%" echo from urllib.request import urlopen
>>"%PYFILE%" echo from datetime import datetime
>>"%PYFILE%" echo url = "https://wttr.in/?format=j1"
>>"%PYFILE%" echo resp = urlopen(url)
>>"%PYFILE%" echo data = json.load(resp)
>>"%PYFILE%" echo resp.close()
>>"%PYFILE%" echo area = data["nearest_area"][0]["areaName"][0]["value"]
>>"%PYFILE%" echo tempF = data["current_condition"][0]["temp_F"]
>>"%PYFILE%" echo condition = data["current_condition"][0]["weatherDesc"][0]["value"]
>>"%PYFILE%" echo local_dt = datetime.now().astimezone()
>>"%PYFILE%" echo tz_name = local_dt.tzname() or str(local_dt.tzinfo)
>>"%PYFILE%" echo time_str = local_dt.strftime("%%I:%%M %%p")
>>"%PYFILE%" echo print("City of connected device: " ^+ area)
>>"%PYFILE%" echo print("Temperature of " ^+ area ^+ ": " ^+ tempF ^+ " F")
>>"%PYFILE%" echo print("Current weather: " ^+ condition)
>>"%PYFILE%" echo print("Time zone of city: " ^+ tz_name)
>>"%PYFILE%" echo print("Local time in city: " ^+ time_str)

:: ---------------------------------------------------------
:: Run Python script
:: ---------------------------------------------------------
"%PY_CMD%" "%PYFILE%"
set "ERR=%ERRORLEVEL%"

:: Clean up temp file
del "%PYFILE%" >nul 2>&1

endlocal
exit /b %ERR%
