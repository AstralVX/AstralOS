$edk2Path = "$env:USERPROFILE\GitHub\Edk2"
$hddPath = "$env:USERPROFILE\AstralOsHdd\"

$params = ''

$params += "-name AstralOS "

# $params += "-cpu Skylake-Client-v1 "

# UEFI BIOS
$params += "-drive if=pflash,format=raw,readonly=on,file=$edk2Path\Build\OvmfX64\DEBUG_VS2015x86\FV\OVMF_CODE.fd "
$params += "-drive if=pflash,format=raw,file=$edk2Path\Build\OvmfX64\DEBUG_VS2015x86\FV\OVMF_VARS.fd "

# HDD ESP partition
$params += "-drive file=fat:rw:$hddPath,index=0,media=disk,driver=raw "

$proc = ''
try
{
    $proc = Start-Process -FilePath "qemu-system-x86_64.exe" -WindowStyle Hidden -Passthru -ArgumentList $params
    Wait-Process $proc.Id
}
finally
{
    # Catch ctrl+c in powershell, then kill qemu
    Stop-Process $proc -Force
}
