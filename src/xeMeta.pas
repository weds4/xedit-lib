unit xeMeta;

interface

uses
  Classes, SysUtils, Generics.Collections;

  // API METHODS
  procedure InitXEdit; cdecl;
  procedure CloseXEdit; cdecl;
  function GetResultString(str: PWideChar; maxLen: Integer): WordBool; cdecl;
  function GetResultArray(_res: PCardinal; maxLen: Integer): WordBool; cdecl;
  function GetGlobal(key: PWideChar; len: PInteger): WordBool; cdecl;
  function GetGlobals(len: PInteger): WordBool; cdecl;
  function Release(_id: Cardinal): WordBool; cdecl;
  function ResetStore: WordBool; cdecl;

  // NATIVE METHODS
  function Resolve(_id: Cardinal): IInterface;
  procedure StoreIfAssigned(var x: IInterface; var _res: PCardinal; var Success: WordBool);
  function Store(x: IInterface): Cardinal;
  function xStrCopy(source: WideString; dest: PWideChar; maxLen: Integer): WordBool;

var
  _store: TInterfaceList;
  _releasedIDs: TList<Cardinal>;
  nextID: Cardinal;
  resultStr: WideString;
  resultArray: array of Cardinal;

implementation

uses
  wbImplementation, wbInterface,
  // mte modules
  mteHelpers,
  // xelib modules
  xeConfiguration, xeMessages, xeSetup;


{******************************************************************************}
{ META METHODS
  Methods which correspond to the overall functioning of the API.
}
{******************************************************************************}

procedure InitXEdit; cdecl;
begin
  // initialize variables
  _store := TInterfaceList.Create;
  _releasedIDs := TList<Cardinal>.Create;
  _store.Add(nil);
  ExceptionMessage := '';
  resultStr := '';

  // add welcome message
  AddMessage('XEditLib v' + ProgramStatus.ProgramVersion);

  // store global values
  Globals.Values['ProgramPath'] := ExtractFilePath(ParamStr(0));
  Globals.Values['Version'] := ProgramStatus.ProgramVersion;
end;

procedure CloseXEdit; cdecl;
begin
  SaveMessages;
  settings.Free;
  _releasedIDs.Free;
  _store.Free;
  SetLength(xFiles, 0);
  xFiles := nil;
  wbFileForceClosed;
  if Assigned(wbContainerHandler) then
    wbContainerHandler._Release;
end;

function xStrCopy(source: WideString; dest: PWideChar; maxLen: Integer): WordBool;
var
  len: Integer;
begin
  Result := False;
  try
    len := Length(source);
    if len > maxLen then
      raise Exception.Create(Format('Found buffer length %d, expected %d.', [maxLen, len + 1]));
    Move(PWideChar(source)^, dest^, len * SizeOf(WideChar));
    dest[len] := #0;
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetResultString(str: PWideChar; maxLen: Integer): WordBool; cdecl;
begin
  Result := xStrCopy(resultStr, str, maxLen);
end;

{$POINTERMATH ON}
function GetResultArray(_res: PCardinal; maxLen: Integer): WordBool; cdecl;
var
  i: Integer;
begin
  Result := False;
  try
    for i := 0 to High(resultArray) do begin
      if i >= maxLen then break;
      _res[i] := resultArray[i];
    end;
    SetLength(resultArray, 0);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;
{$POINTERMATH OFF}

function GetGlobal(key: PWideChar; len: PInteger): WordBool; cdecl;
begin
  Result := False;
  try
    if Globals.IndexOfName(key) > -1 then begin
      resultStr := Globals.Values[key];
      len^ := Length(resultStr);
      Result := True;
    end;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function GetGlobals(len: PInteger): WordBool; cdecl;
begin
  Result := False;
  try
    resultStr := Globals.Text;
    len^ := Length(resultStr);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function Resolve(_id: Cardinal): IInterface;
begin
  if _id = 0 then raise Exception.Create('ERROR: Cannot resolve NULL reference.');
  Result := _store[_id];
end;

procedure StoreIfAssigned(var x: IInterface; var _res: PCardinal; var Success: WordBool);
begin
  if Assigned(x) then begin
    _res^ := Store(x);
    Success := True;
  end;
end;

function Store(x: IInterface): Cardinal;
var
  i: Integer;
begin
  if _releasedIDs.Count > 0 then begin
    i := _releasedIDs[0];
    _store[i] := x;
    _releasedIDs.Delete(0);
    Result := i;
  end
  else
    Result := _store.Add(x);
end;

function Release(_id: Cardinal): WordBool; cdecl;
begin
  Result := False;
  try
    if (_id = 0) or (_id >= Cardinal(_store.Count)) then exit;
    _store[_id] := nil;
    _releasedIDs.Add(_id);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

function ResetStore: WordBool; cdecl;
begin
  Result := False;
  try
    _store.Clear;
    _releasedIDs.Clear;
    _store.Add(nil);
    Result := True;
  except
    on x: Exception do ExceptionHandler(x);
  end;
end;

end.