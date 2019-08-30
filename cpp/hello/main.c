#include <wdm.h>

void Unload(PDRIVER_OBJECT pOurDriver)
{
}

NTSTATUS DriverEntry(PDRIVER_OBJECT pOurDriver, PUNICODE_STRING pOurRegistry)
{
  DbgPrint("Hello, world!");
  pOurDriver->DriverUnload = Unload;
  return STATUS_SUCCESS;
}
