@echo off
set "TERMUI_TEST_MODE="
set "TERMUI_TEST_FILE="
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0powershell\termUI.ps1" --real %*
