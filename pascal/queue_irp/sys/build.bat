del /s /q main.sys
c:\dddk\bin\dcc32.exe -Uc:\dddk\inc -B -CG -JP -$A-,C-,D-,G-,H-,I-,L-,P-,V-,W+,Y- main.pas
c:\dddk\bin\omf2d.exe main.obj
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEZwClose=_ZwClose@4 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEDbgPrint=_DbgPrint 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEExFreePool=_ExFreePool@4 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEKeSetTimer=_KeSetTimer@16 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEIoStopTimer=_IoStopTimer@4 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEIoStartTimer=_IoStartTimer@4 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEKeSetTimerEx=_KeSetTimerEx@20 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEProbeForRead=_ProbeForRead@12 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEKeCancelTimer=_KeCancelTimer@4 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEIoStartPacket=_IoStartPacket@16 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEZwOpenProcess=_ZwOpenProcess@16 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEIoDeleteDevice=_IoDeleteDevice@4 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEExAllocatePool=_ExAllocatePool@8 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEKeReleaseMutex=_KeReleaseMutex@8 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEIoCreateDevice=_IoCreateDevice@28 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEKeInitializeDpc=_KeInitializeDpc@12 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEIoStartNextPacket=_IoStartNextPacket@8 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEIoCompleteRequest=_IoCompleteRequest@8 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEKeInitializeMutex=_KeInitializeMutex@8 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEKeInitializeTimer=_KeInitializeTimer@4 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEIoInitializeTimer=_IoInitializeTimer@12 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEObDereferenceObject=_ObDereferenceObject@4 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEIoGetCurrentProcess=_IoGetCurrentProcess@0 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEInterlockedExchange=@InterlockedExchange@8 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEIoCreateSymbolicLink=_IoCreateSymbolicLink@8 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEIoDeleteSymbolicLink=_IoDeleteSymbolicLink@4 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CERtlInitUnicodeString=_RtlInitUnicodeString@8 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEPsCreateSystemThread=_PsCreateSystemThread@28 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEKeWaitForSingleObject=_KeWaitForSingleObject@20 2>nul 
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEExAllocatePoolWithTag=_ExAllocatePoolWithTag@12 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEKeDelayExecutionThread=_KeDelayExecutionThread@12 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEKeServiceDescriptorTable=_KeServiceDescriptorTable 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEExAllocatePoolWithQuota=_ExAllocatePoolWithQuota@8 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEPsTerminateSystemThread=_PsTerminateSystemThread@4 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEObReferenceObjectByHandle=_ObReferenceObjectByHandle@24 2>nul
c:\dddk\bin\omf2d.exe c:\dddk\inc\dddk.obj /U- /CEMmMapLockedPagesSpecifyCache=_MmMapLockedPagesSpecifyCache@24 2>nul
c:\dddk\bin\link.exe /NOLOGO /ALIGN:32 /BASE:0x10000 /SUBSYSTEM:NATIVE /DRIVER /FORCE:UNRESOLVED /FORCE:MULTIPLE /ENTRY:DriverEntry c:\dddk\inc\DDDK.obj C:\dddk\lib\ntoskrnl.lib main.obj /out:main.sys
del /s /q main.dcu
del /s /q main.obj