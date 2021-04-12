$nasmFolder = "c:\NASM"
$workingBuildFolder = "Build"
$binPath = "$workingBuildFolder\bios.bin"

# Cd into working dir for native binaries
$CWD = [Environment]::CurrentDirectory
Push-Location $PWD
[Environment]::CurrentDirectory = $PWD

# Build BIOS via nasm
$psi = New-object System.Diagnostics.ProcessStartInfo 
$psi.FileName = "$nasmFolder\nasm.exe" 
$psi.Arguments = "-f bin bios.asm -o $binPath"
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

# Restore working dir
Pop-Location
[Environment]::CurrentDirectory = $CWD

# Run the BIOS in QEMU
if ($process.ExitCode -eq 0)
{
    $params = ""
    $params += '-name "AstralOS -- legacy bios" '
    # Set booting BIOS from floppy disk
    $params += "-drive format=raw,index=0,if=floppy,file=$binPath "

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

