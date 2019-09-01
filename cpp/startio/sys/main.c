#include <wdm.h>

#define DEV_NAME L"\\Device\\MyDriver"
#define SYM_NAME L"\\DosDevices\\MyDriver"

char szBuffer[255]={0};

VOID StartIo(struct _DEVICE_OBJECT *pOurDevice, struct _IRP *pIrp)
{
  ULONG dwLen=0;
  PIO_STACK_LOCATION psk = IoGetCurrentIrpStackLocation(pIrp);
  switch(psk->MajorFunction){
  case IRP_MJ_READ:
    dwLen = strlen(szBuffer)+1;
    strcpy(pIrp->AssociatedIrp.SystemBuffer, szBuffer);
    DbgPrint("StartIo, IRP_MJ_READ");
    break;
  case IRP_MJ_WRITE:
    dwLen = psk->Parameters.Write.Length;
    strcpy(szBuffer, pIrp->AssociatedIrp.SystemBuffer);
    DbgPrint("StartIo, IRP_MJ_WRITE");
    DbgPrint("Buffer: %s, Length: %d", szBuffer, dwLen);
    break;
  }
  pIrp->IoStatus.Status = STATUS_SUCCESS;
  pIrp->IoStatus.Information = dwLen;
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
  IoStartNextPacket(pOurDevice, FALSE);
}

void Unload(PDRIVER_OBJECT pOurDriver)
{
  UNICODE_STRING usSymboName;
              
  RtlInitUnicodeString(&usSymboName, L"\\DosDevices\\MyDriver");
  IoDeleteSymbolicLink(&usSymboName);
  IoDeleteDevice(pOurDriver->DeviceObject);
}

NTSTATUS IrpFile(PDEVICE_OBJECT pOurDevice, PIRP pIrp)
{
  PIO_STACK_LOCATION psk = IoGetCurrentIrpStackLocation(pIrp);

  switch(psk->MajorFunction){
  case IRP_MJ_CREATE:
    DbgPrint("IRP_MJ_CREATE");
    break;
  case IRP_MJ_WRITE:
    DbgPrint("IrpFile, IRP_MJ_WRITE");
    IoMarkIrpPending(pIrp);
    IoStartPacket(pOurDevice, pIrp, 0, NULL);
    return STATUS_PENDING;
  case IRP_MJ_READ:
    DbgPrint("IrpFile, IRP_MJ_READ");
    IoMarkIrpPending(pIrp);
    IoStartPacket(pOurDevice, pIrp, 0, NULL);
    return STATUS_PENDING;
  case IRP_MJ_CLOSE:
    DbgPrint("IRP_MJ_CLOSE");
    break;
  }
  IoCompleteRequest(pIrp, IO_NO_INCREMENT);
  return STATUS_SUCCESS;
}

NTSTATUS DriverEntry(PDRIVER_OBJECT pOurDriver, PUNICODE_STRING pOurRegistry)
{
  PDEVICE_OBJECT pOurDevice=NULL;
  UNICODE_STRING usDeviceName;
  UNICODE_STRING usSymboName;
         
  pOurDriver->MajorFunction[IRP_MJ_CREATE] =
  pOurDriver->MajorFunction[IRP_MJ_WRITE] =
  pOurDriver->MajorFunction[IRP_MJ_READ] =
  pOurDriver->MajorFunction[IRP_MJ_CLOSE] = IrpFile;
  pOurDriver->DriverStartIo = StartIo;
  pOurDriver->DriverUnload = Unload;
           
  RtlInitUnicodeString(&usDeviceName, L"\\Device\\MyDriver");
  IoCreateDevice(pOurDriver, 0, &usDeviceName, FILE_DEVICE_UNKNOWN, 0, FALSE, &pOurDevice);
  RtlInitUnicodeString(&usSymboName, L"\\DosDevices\\MyDriver");
  IoCreateSymbolicLink(&usSymboName, &usDeviceName);
  pOurDevice->Flags&= ~DO_DEVICE_INITIALIZING;
  pOurDevice->Flags|= DO_BUFFERED_IO;
  return STATUS_SUCCESS;
}
