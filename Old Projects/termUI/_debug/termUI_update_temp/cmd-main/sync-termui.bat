@echo off
REM Sync termUI between cmd and termCalc
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-termui.ps1"
