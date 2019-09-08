unit main;

interface
uses DDDK;
function _DriverEntry(pOurDriver:PDriverObject; pOurRegistry:PUnicodeString):NTSTATUS; stdcall;

implementation
procedure DriverUnload(pOurDriver:PDriverObject); stdcall;
begin
end;

function _DriverEntry(pOurDriver:PDriverObject; pOurRegistry:PUnicodeString):NTSTATUS; stdcall;
begin
  DbgPrint('Hello, world!', []);
  pOurDriver^.DriverUnload:= @DriverUnload;
  Result:= STATUS_SUCCESS;
end;
end.
