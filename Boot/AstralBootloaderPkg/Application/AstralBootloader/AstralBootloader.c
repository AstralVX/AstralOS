#include "AstralBootloader.h"

EFI_STATUS
EFIAPI
UefiMain(
    IN EFI_HANDLE        ImageHandle,
    IN EFI_SYSTEM_TABLE* SystemTable
)
{
    DEBUG((EFI_D_ERROR, "Hi from bootloader!\n"));

    return EFI_SUCCESS;
}
