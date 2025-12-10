# weatherTest

Simple WinForms GUI that fetches current weather from Open-Meteo.

## Files
- `WeatherTest.cs` - C# WinForms source.
- `compile.bat` - builds `bin/WeatherTest.exe` with csc.
- `run.bat` - runs the app (builds first if missing).
- `bin/` - output directory (created on build).

## Requirements
- Windows with .NET Framework developer tools (csc in `%SystemRoot%\Microsoft.NET\Framework`), 4.0+ recommended.
- Internet access to reach https://open-meteo.com.

## Build
```
compile.bat
```

## Run
```
run.bat
```

## Usage
1. Enter a city name (defaults to "New York").
2. Click "Fetch Weather".
3. Weather info shows in the output box. Errors show in the status line.
