# CD into dir of PS1 script, as tasks.json puts us in root project
Push-Location $PSScriptRoot
[Environment]::CurrentDirectory = $PSScriptRoot

$nasmFolder = "c:\NASM"
$workingBuildFolder = "Build"
$bootloaderBinPath = "$workingBuildFolder\bootloader16.bin"
$kernelBinPath = "$workingBuildFolder\kernel16.bin"
$floppyDiskPath = "$workingBuildFolder\floppydisk.img"

# Build BIOS via nasm
$psi = New-object System.Diagnostics.ProcessStartInfo 
$psi.FileName = "$nasmFolder\nasm.exe" 
$psi.Arguments = "-f bin bootloader.asm -o $bootloaderBinPath"
$psi.CreateNoWindow = $true 
$psi.UseShellExecute = $false 
$psi.RedirectStandardOutput = $true 
$psi.RedirectStandardError = $true 
$process = New-Object System.Diagnostics.Process 
$process.StartInfo = $psi 
[void]$process.Start()
$stdout = $process.StandardOutput.ReadToEnd() 
$stderr = $process.StandardError.ReadToEnd() 
$process.WaitForExit() 
$stdout
$stderr


# Create the floppy disk to store bootloader at MBR, and kernel
$floppyDiskSize = 1.44 * 1000 * 1024
$floppyData = New-Object Byte[] $floppyDiskSize
$bootloaderBin = Get-Content $bootloaderBinPath -Encoding Byte -Raw
$kernelBin = Get-Content $kernelBinPath -Encoding Byte -Raw
for ($i = 0; $i -lt $floppyDiskSize; $i++)
{
    # Append bootloader to MBR in floppy disk, sector 0 [0-512]
    $MBR_START = 512 * 0
    if ($i -ge $MBR_START -and $i -lt ($bootloaderBin.Length))
    {
        $floppyData[$i] = $bootloaderBin[$i]
    }
    # Append kernel from sector 2 [512-n]
    $KERNEL_START = 512 * 1
    if ($i -ge $KERNEL_START -and $i -lt ($KERNEL_START + $bootloaderBin.Length))
    {
        $floppyData[$i] = $kernelBin[$i - $KERNEL_START]
    }
}

$floppyStream = [System.IO.File]::OpenWrite($floppyDiskPath)
$floppyStream.Write($floppyData, 0, $floppyData.Length)
$floppyStream.Close()


# Run the BIOS in QEMU
if ($process.ExitCode -eq 0)
{
    $params = ""
    $params += '-name "AstralOS -- legacy boot" '
    # Set booting BIOS from floppy disk
    #$params += "-drive format=raw,index=0,if=floppy,file=$bootloaderBinPath "
    $params += "-drive format=raw,index=0,if=floppy,file=$floppyDiskPath "

    $proc = ''
    try
    {
        $proc = Start-Process -FilePath "qemu-system-x86_64.exe" -NoNewWindow -Passthru -ArgumentList $params
        Wait-Process $proc.Id
    }
    finally
    {
        # Catch ctrl+c in powershell, then kill qemu
        Stop-Process $proc -Force
    }
}

