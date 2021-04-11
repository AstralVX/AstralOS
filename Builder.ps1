# EDK2 requires .bat build files
$bootloaderLog = "$env:TEMP\AstralBootloader_Builder.log"
$edk2loaderLog = "$env:TEMP\AstralBootloader_Edk2.log"

$buildProc = Start-Process -FilePath .\Boot\BuildBootloader.bat -Wait -Passthru -RedirectStandardOutput $bootloaderLog
get-content $bootloaderLog
get-content $edk2loaderLog

write-host "---------------------------"
write-host "BuildBootloader.bat exit", $buildProc.ExitCode
write-host "---------------------------"

