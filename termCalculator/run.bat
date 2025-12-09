@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0termCalculator.ps1" %*
