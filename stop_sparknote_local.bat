@echo off
setlocal

echo Stopping local Python processes that may be serving Sparknote...
taskkill /F /IM python.exe /T >nul 2>nul

echo Done.
exit /b 0
