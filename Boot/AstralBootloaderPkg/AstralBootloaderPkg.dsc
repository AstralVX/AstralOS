[Defines]
    DSC_SPECIFICATION                      = 1.28
    PLATFORM_NAME                          = AstralBootloaderPkg
    PLATFORM_GUID                          = 37f41453-f3e6-4b17-8f17-9dc6fef20e1c
    PLATFORM_VERSION                       = 1.00
    OUTPUT_DIRECTORY                       = Build/AstralBootloaderPkg
    SUPPORTED_ARCHITECTURES                = X64
    BUILD_TARGETS                          = DEBUG
    SKUID_IDENTIFIER                       = DEFAULT

[Components]
    ../AstralOS/Boot/AstralBootloaderPkg/Application/AstralBootloader/AstralBootloader.inf

[LibraryClasses]
    BaseLib|MdePkg/Library/BaseLib/BaseLib.inf
    UefiApplicationEntryPoint|MdePkg/Library/UefiApplicationEntryPoint/UefiApplicationEntryPoint.inf
    BaseMemoryLib|MdePkg/Library/BaseMemoryLib/BaseMemoryLib.inf
    CacheMaintenanceLib|MdePkg/Library/BaseCacheMaintenanceLib/BaseCacheMaintenanceLib.inf
    DebugPrintErrorLevelLib|MdePkg/Library/BaseDebugPrintErrorLevelLib/BaseDebugPrintErrorLevelLib.inf
    DevicePathLib|MdePkg/Library/UefiDevicePathLib/UefiDevicePathLib.inf
    MemoryAllocationLib|MdePkg/Library/UefiMemoryAllocationLib/UefiMemoryAllocationLib.inf
    PcdLib|MdePkg/Library/BasePcdLibNull/BasePcdLibNull.inf
    PrintLib|MdePkg/Library/BasePrintLib/BasePrintLib.inf
    UefiBootServicesTableLib|MdePkg/Library/UefiBootServicesTableLib/UefiBootServicesTableLib.inf
    UefiCpuLib|UefiCpuPkg/Library/BaseUefiCpuLib/BaseUefiCpuLib.inf
    UefiDriverEntryPoint|MdePkg/Library/UefiDriverEntryPoint/UefiDriverEntryPoint.inf
    UefiLib|MdePkg/Library/UefiLib/UefiLib.inf
    UefiRuntimeLib|MdePkg/Library/UefiRuntimeLib/UefiRuntimeLib.inf
    UefiRuntimeServicesTableLib|MdePkg/Library/UefiRuntimeServicesTableLib/UefiRuntimeServicesTableLib.inf
    IoLib|MdePkg/Library/BaseIoLibIntrinsic/BaseIoLibIntrinsicSev.inf
    SerialPortLib|MdePkg/Library/BaseSerialPortLibNull/BaseSerialPortLibNull.inf
#    !if $(TARGET) == RELEASE
#        DebugLib|MdePkg/Library/BaseDebugLibNull/BaseDebugLibNull.inf
#    !else
#        !ifdef $(DEBUG_ON_SERIAL_PORT)
#            SerialPortLib|PcAtChipsetPkg/Library/SerialIoLib/SerialIoLib.inf
#            DebugLib|MdePkg/Library/BaseDebugLibSerialPort/BaseDebugLibSerialPort.inf
#        !else
#            DebugLib|MdePkg/Library/UefiDebugLibConOut/UefiDebugLibConOut.inf
#        !endif
#    !endif

    DebugLib|MdePkg/Library/BaseDebugLibSerialPort/BaseDebugLibSerialPort.inf

[PcdsFixedAtBuild]
    # Enable EDK2 debug features based on the TARGET configuration.
    # https://github.com/tianocore/tianocore.github.io/wiki/EDK-II-Debugging
    #!if $(TARGET) == RELEASE
    #    # No debug code such as DEBUG() / ASSERT(). They will be removed.
    #    gEfiMdePkgTokenSpaceGuid.PcdDebugPrintErrorLevel|0x0
    #    gEfiMdePkgTokenSpaceGuid.PcdDebugPropertyMask|0x0
    #!else
    #    # Define DEBUG_ERROR | DEBUG_VERBOSE | DEBUG_INFO | DEBUG_WARN to enable
    #    # logging at those levels. Also, define DEBUG_PROPERTY_ASSERT_DEADLOOP_ENABLED
    #    # and such. Assertion failure will call CpuDeadLoop.
    #    gEfiMdePkgTokenSpaceGuid.PcdDebugPrintErrorLevel|0x80400042
    #    gEfiMdePkgTokenSpaceGuid.PcdDebugPropertyMask|0x2f
    #!endif

    gEfiMdePkgTokenSpaceGuid.PcdDebugPrintErrorLevel|0x80080046