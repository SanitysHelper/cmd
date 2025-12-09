@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0cmdBrowser.ps1" %*
