@echo off
REM Build script for FNF Psych Engine
REM This script runs the lime build command via haxelib

cd /d "%~dp0"

REM Fix stale HAXEPATH values that break hxcpp/haxelib path resolution
if not defined HAXEPATH set "HAXEPATH=C:\HaxeToolkit\haxe"
if not exist "%HAXEPATH%" set "HAXEPATH=C:\HaxeToolkit\haxe"

haxelib run lime test windows %*
pause
