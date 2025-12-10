@echo off
setlocal
echo [INFO] Building WeatherTest WinForms app
set "ROOT=%~dp0"
set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
if not exist "%CSC%" set "CSC=%SystemRoot%\Microsoft.NET\Framework\v3.5\csc.exe"
if not exist "%CSC%" (
    echo [ERROR] csc.exe not found. Install .NET Framework developer tools.
    exit /b 1
)
if not exist "%ROOT%bin" mkdir "%ROOT%bin"
pushd "%ROOT%"
"%CSC%" /nologo /t:winexe /platform:anycpu ^
    /out:bin\WeatherTest.exe ^
    /r:System.Windows.Forms.dll,System.Drawing.dll,System.Web.Extensions.dll ^
    WeatherTest.cs
set "BUILD_EXIT=%ERRORLEVEL%"
popd
if not "%BUILD_EXIT%"=="0" (
    echo [ERROR] Build failed with exit code %BUILD_EXIT%.
    exit /b %BUILD_EXIT%
)
echo [INFO] Build succeeded: %ROOT%bin\WeatherTest.exe
endlocal
