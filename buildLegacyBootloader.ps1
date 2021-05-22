#
# Build configurations
#
$nasmFolder = "c:\NASM"
$workingBuildFolder = "build"
$bootloaderDir = "boot\legacy"
$compilerPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.16.27023\bin\Hostx86\x86\cl.exe"
$linkerPath = "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Tools\MSVC\14.16.27023\bin\Hostx86\x86\link.exe"

$bootloader1BinPath = "$workingBuildFolder\BootloaderOne16.bin"
$bootloader2BinPath = "$workingBuildFolder\BootloaderTwo16.bin"
$floppyDiskPath = "$workingBuildFolder\floppydisk.img"
$SECTOR_SIZE = 512
$kernelBinPath = "$workingBuildFolder\kernel.exe"

#
# Functions
#
function BuildWithNasm($asmFileName, $outputPath)
{
    #
    # Set working dir for native win32 exe, and cd into it to build with nasm
    #
    [Environment]::CurrentDirectory = $bootloaderDir
    set-location $bootloaderDir

    $psi = New-object System.Diagnostics.ProcessStartInfo 
    $psi.FileName = "$nasmFolder\nasm.exe" 
    $psi.Arguments = "-f bin ${asmFileName} -o ""..\\..\\$outputPath"" "
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
    
    [Environment]::CurrentDirectory = $PSScriptRoot
    set-location $PSScriptRoot
    
    if ($process.ExitCode -ne 0)
    {
        Exit 1
    }
}

function WriteToFloppy($floppyData, $dataToWrite, $offset)
{
    $written = 0
    for ($i = 0; $i -lt $floppyData.Length; $i++)
    {
        if ($i -ge $offset -and $i -lt ($offset + $dataToWrite.Length))
        {
            $floppyData[$i] = $dataToWrite[$written++]
        }
    }
}

function CompileKernel($outputPath)
{
    #
    # Compile - parse each file and generate opcode into a .obj file
    #
    $psi = New-object System.Diagnostics.ProcessStartInfo 
    $psi.FileName = $compilerPath 
    $psi.Arguments =    "/Gd " +
                        "/GS- " +                   # Ignore buffer security checks 
                        "/Fobuild\kernel.obj " +
                        "/Fm " +
                        "/TC " +
                        "/Zi " +                    # Ignore debug information format
                        "/c kernel/Kernel.c"
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
    if ($process.ExitCode -ne 0)
    {
        Exit 1
    }

    #
    # Link - linking the opcodes from the .obj together to form the .exe
    # https://docs.microsoft.com/en-us/cpp/build/reference/subsystem-specify-subsystem?view=msvc-160
    #
    $psi.FileName = $linkerPath 
    $psi.Arguments =    "/SAFESEH:NO " +                            # Don't produce table of exception handlers
                        "/FILEALIGN:0x400 " +                       # Align sections (primary option to affect file size)
                        "/BASE:0x100000 " +                         # Base address of the program stored in OptionalHeader.ImageBase
                        "/DYNAMICBASE:NO " +                        # No ASLR
                        "/DEBUG:NONE " +                            # No PDB gen'd
                        "/NODEFAULTLIB " +                          # No default libs e.g. CRT
                        "/SUBSYSTEM:NATIVE " +                      # Usuaully reversed for Windows system components
                        "/INCREMENTAL:NO " +                        # Always perform full link
                        "/OPT:NOREF,NOICF " +                       # No optimization (even unused code is included)
                        "/FIXED " +                                 # Linker does not generate a .reloc section
                        "/MAP:build\kernel.map " +                  # Output map file containing modulename/timestamp/code groups/symbols/entry point
                        "/ENTRY:_KernelEntry build\kernel.obj " +   # 
                        "/OUT:$outputPath "
    $process = New-Object System.Diagnostics.Process 
    $process.StartInfo = $psi 
    [void]$process.Start()
    $stdout = $process.StandardOutput.ReadToEnd() 
    $stderr = $process.StandardError.ReadToEnd() 
    $process.WaitForExit() 
    $stdout
    $stderr   
    if ($process.ExitCode -ne 0)
    {
        Exit 1
    }

}

# -------------------------------------------------------------------------------------
# Main
# -------------------------------------------------------------------------------------

#
# Clean out build folder
#
Remove-Item "$workingBuildFolder\*" -Force -Recurse -ErrorAction Ignore
New-Item -ItemType Directory -Force -Path $workingBuildFolder | Out-Null

#
# Build bootloader stage 1 and stage 2 via nasm
#
Write-Host 'Building bootloader stage 1 and 2'
BuildWithNasm "BootloaderOne16.asm" $bootloader1BinPath
BuildWithNasm "BootloaderTwo16.asm" $bootloader2BinPath

#
# Build kernel
#
Write-Host 'Building kernel'
CompileKernel $kernelBinPath

#
# Create the floppy disk to store bootloader at MBR, and kernel
#
Write-Host 'Creating disk image'
$floppyDiskSize = 1.44 * 1000 * 1024
$floppyData = New-Object Byte[] $floppyDiskSize
$bootloader1Bin = Get-Content $bootloader1BinPath -Encoding Byte -Raw
$bootloader2Bin = Get-Content $bootloader2BinPath -Encoding Byte -Raw

#
# Floppy disk map
#
WriteToFloppy $floppyData $bootloader1Bin 0
WriteToFloppy $floppyData $bootloader2Bin $SECTOR_SIZE

$floppyStream = [System.IO.File]::OpenWrite($floppyDiskPath)
$floppyStream.Write($floppyData, 0, $floppyData.Length)
$floppyStream.Close()

#
# Run the BIOS in QEMU
#
$params = ""
$params += '-name "AstralOS -- legacy boot" '
# Set booting BIOS from floppy disk
$params += "-drive format=raw,index=0,if=floppy,file=$floppyDiskPath "
# Enable debugging, break at POST with '-S'
$params += "-s "

$proc = ''
try
{
#$proc = Start-Process -FilePath "qemu-system-i386.exe" -NoNewWindow -Passthru -ArgumentList $params
#Wait-Process $proc.Id
    Get-ChildItem -File $kernelBinPath | Select-Object -Property Length  
}
finally
{
    # Catch ctrl+c in powershell, then kill qemu
#Stop-Process $proc -Force
}


write-host 'Bye'
Exit 0


