@echo off
:: EDK2 bat scripts don't play nicely with Powershell
cd %USERPROFILE%\github\edk2
set NASM_PREFIX=c:\NASM\
call edksetup.bat
:: Capture output of build process, and parent Builder.ps1 will print it out
call build -a X64 -t VS2015x86 -b DEBUG -p "..\AstralOS\Boot\AstralBootloaderPkg\AstralBootloaderPkg.dsc" > %TEMP%\AstralBootloader_Edk2.log 2>&1
