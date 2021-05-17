# AstralOS

AstralOS is a system level hobby project that will compose of a legacy `AstralBios`, legacy `AstralBootloader` and the `AstralOS`. 

## Bootloader
Floppy disk layout:

````
+---------------------- 0
|
| MBR - bootloader
|
+---------------------- 0x200
|
| 2nd stage bootloader
|
|
|+----------------------
|
| OS
|
+----------------------
````
