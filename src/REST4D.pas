unit REST4D;

interface

uses
  System.SysUtils,
  System.Classes,
  IdGlobal,
  IdHashMessageDigest,
  System.Generics.Collections;

type

  ERESTException = class(Exception);

  TRESTCodification = class sealed
  public
    class function EncodeBase64(pValue: string): string; static;
    class function DecodeBase64(pValue: string): string; static;
    class function MD5(const pSource: string): string; static;
  end;

  TRESTMediaType = class sealed
  public
    const
    APPLICATION_ATOM_XML = 'application/atom+xml';
    APPLICATION_FORM_URLENCODED = 'application/x-www-form-urlencoded';
    APPLICATION_JSON = 'application/json';
    APPLICATION_OCTET_STREAM = 'application/octet-stream';
    APPLICATION_SVG_XML = 'application/svg+xml';
    APPLICATION_XHTML_XML = 'application/xhtml+xml';
    APPLICATION_XML = 'application/xml';
    MEDIA_TYPE_WILDCARD = '*';
    MULTIPART_FORM_DATA = 'multipart/form-data';
    TEXT_HTML = 'text/html';
    TEXT_PLAIN = 'text/plain';
    TEXT_XML = 'text/xml';
    WILDCARD = '*/*';
  end;

  TRESTCharSetType = class sealed
  public
    const
    ISO88591 = 'iso-8859-1';
    ISO88592 = 'iso-8859-2';
    ISO88593 = 'iso-8859-3';
    ISO88594 = 'iso-8859-4';
    ISO88595 = 'iso-8859-5';
    ISO88596 = 'iso-8859-6';
    ISO88597 = 'iso-8859-7';
    ISO88598 = 'iso-8859-8';
    ISO885915 = 'iso-8859-15';
    WINDOWS1250 = 'windows-1250';
    WINDOWS1251 = 'windows-1251';
    WINDOWS1252 = 'windows-1252';
    WINDOWS1254 = 'windows-1254';
    UTF8 = 'utf-8';
  end;

  TRESTStatusCode = class sealed
  public
    const
    // 2xx Success
    OK = 200;
    CREATED = 201;
    ACCEPTED = 202;
    NO_CONTENT = 204;
    // 3xx Redirection
    NOT_MODIFIED = 304;
    // 4xx Client Error
    BAD_REQUEST = 400;
    UNAUTHORIZED = 401;
    FORBIDDEN = 403;
    NOT_FOUND = 404;
    CONFLICT = 409;
    UNSUPPORTED_MEDIA_TYPE = 415;
    // 5xx Server Error
    INTERNAL_SERVER_ERROR = 500;
    NOT_IMPLEMENTED = 501;
  end;

  IRESTUserAuthenticate = interface
    ['{56A84057-56BB-4742-8ED2-6C5D47CA3E3A}']
    function GetUserName(): string;
    procedure SetUserName(const pValue: string);

    function GetPassword(): string;
    procedure SetPassword(const pValue: string);

    function GetApiKey(): string;

    property UserName: string read GetUserName write SetUserName;
    property Password: string read GetPassword write SetPassword;
    property ApiKey: string read GetApiKey;
  end;

  IRESTAuthentication = interface
    ['{8A4C9CED-3291-4A43-8634-8FF7F0500778}']
    procedure AddUser(const pUserName, pPassword: string);

    procedure RemoveUser(const pUserName, pPassword: string); overload;
    procedure RemoveUser(const pApiKey: string); overload;

    function CountUsers(): Integer;

    function UserIsValid(const pUserName, pPassword: string): Boolean; overload;
    function UserIsValid(const pApiKey: string): Boolean; overload;
  end;

  TRESTAuthenticationFactory = class sealed
  public
    class function Build(): IRESTAuthentication; static;
  end;

implementation

const
  _cBase64Code: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  _cBase64Map: array [#0 .. #127] of Integer = (
    Byte('='), 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64,
    64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 62, 64, 64, 64, 63,
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 64, 64, 64, 64, 64, 64,
    64, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 64, 64, 64, 64, 64,
    64, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 64, 64, 64, 64, 64);

type

  TRESTUserAuthenticate = class(TInterfacedObject, IRESTUserAuthenticate)
  strict private
    FUserName: string;
    FPassword: string;
    FApiKey: string;
    procedure GenerateApiKey();
  public
    constructor Create();

    function GetUserName(): string;
    procedure SetUserName(const pValue: string);

    function GetPassword(): string;
    procedure SetPassword(const pValue: string);

    function GetApiKey(): string;

    property UserName: string read GetUserName write SetUserName;
    property Password: string read GetPassword write SetPassword;
    property ApiKey: string read GetApiKey;
  end;

  TRESTAuthentication = class(TInterfacedObject, IRESTAuthentication)
  strict private
    FUsers: TDictionary<string, IRESTUserAuthenticate>;
  public
    constructor Create();
    destructor Destroy(); override;

    procedure AddUser(const pUserName, pPassword: string);

    procedure RemoveUser(const pUserName, pPassword: string); overload;
    procedure RemoveUser(const pApiKey: string); overload;

    function CountUsers(): Integer;

    function UserIsValid(const pUserName, pPassword: string): Boolean; overload;
    function UserIsValid(const pApiKey: string): Boolean; overload;
  end;

  { TRESTUserAuthenticate }

constructor TRESTUserAuthenticate.Create;
begin
  FUserName := EmptyStr;
  FPassword := EmptyStr;
  FApiKey := EmptyStr;
end;

procedure TRESTUserAuthenticate.GenerateApiKey;
begin
  FApiKey := TRESTCodification.MD5(FUserName + FPassword);
  if FApiKey.IsEmpty then
    raise ERESTException.Create('ApiKey is empty!');
end;

function TRESTUserAuthenticate.GetApiKey: string;
begin
  Result := FApiKey;
end;

function TRESTUserAuthenticate.GetPassword: string;
begin
  Result := FPassword;
end;

function TRESTUserAuthenticate.GetUserName: string;
begin
  Result := FUserName;
end;

procedure TRESTUserAuthenticate.SetPassword(const pValue: string);
begin
  FPassword := pValue;
  GenerateApiKey();
end;

procedure TRESTUserAuthenticate.SetUserName(const pValue: string);
begin
  FUserName := pValue;
  GenerateApiKey();
end;

{ TRESTCodification }

class function TRESTCodification.DecodeBase64(pValue: string): string;
var
  i, PadCount: Integer;
  x1, x2, x3: Byte;
begin
  Result := EmptyStr;

  if (length(pValue) < 4) or (length(pValue) mod 4 <> 0) then
    Exit;

  PadCount := 0;
  i := length(pValue);
  while (pValue[i] = '=')
    and (i > 0) do
  begin
    inc(PadCount);
    dec(i);
  end;

  Result := '';
  i := 1;
  while i <= length(pValue) - 3 do
  begin
    x1 := (_cBase64Map[pValue[i]] shl 2) or (_cBase64Map[pValue[i + 1]] shr 4);
    Result := Result + Char(x1);
    x2 := (_cBase64Map[pValue[i + 1]] shl 4) or (_cBase64Map[pValue[i + 2]] shr 2);
    Result := Result + Char(x2);
    x3 := (_cBase64Map[pValue[i + 2]] shl 6) or (_cBase64Map[pValue[i + 3]]);
    Result := Result + Char(x3);
    inc(i, 4);
  end;

  while PadCount > 0 do
  begin
    Delete(Result, length(Result), 1);
    dec(PadCount);
  end;
end;

class function TRESTCodification.EncodeBase64(pValue: string): string;
var
  i: Integer;
  x1, x2, x3, x4: Byte;
  PadCount: Integer;
begin
  PadCount := 0;

  while length(pValue) < 3 do
  begin
    pValue := pValue + #0;
    inc(PadCount);
  end;

  while (length(pValue) mod 3) <> 0 do
  begin
    pValue := pValue + #0;
    inc(PadCount);
  end;

  Result := EmptyStr;
  i := 1;

  while i <= length(pValue) - 2 do
  begin
    x1 := (Ord(pValue[i]) shr 2) and $3F;

    x2 := ((Ord(pValue[i]) shl 4) and $3F)
      or Ord(pValue[i + 1]) shr 4;

    x3 := ((Ord(pValue[i + 1]) shl 2) and $3F)
      or Ord(pValue[i + 2]) shr 6;

    x4 := Ord(pValue[i + 2]) and $3F;

    Result := Result
      + _cBase64Code[x1 + 1]
      + _cBase64Code[x2 + 1]
      + _cBase64Code[x3 + 1]
      + _cBase64Code[x4 + 1];
    inc(i, 3);
  end;

  if PadCount > 0 then
    for i := length(Result) downto 1 do
    begin
      Result[i] := '=';
      dec(PadCount);
      if PadCount = 0 then
        Break;
    end;
end;

class function TRESTCodification.MD5(const pSource: string): string;
var
  vMD5: TIdHashMessageDigest5;
begin
  Result := EmptyStr;
  if (pSource <> EmptyStr) then
    vMD5 := TIdHashMessageDigest5.Create;
  try
    Result := vMD5.HashStringAsHex(pSource, IndyTextEncoding_UTF8);
  finally
    FreeAndNil(vMD5);
  end;
end;

{ TRESTAuthentication }

procedure TRESTAuthentication.AddUser(const pUserName, pPassword: string);
var
  vUser: IRESTUserAuthenticate;
begin
  vUser := TRESTUserAuthenticate.Create;
  vUser.UserName := pUserName;
  vUser.Password := pPassword;
  FUsers.Add(vUser.ApiKey, vUser);
end;

function TRESTAuthentication.CountUsers: Integer;
begin
  Result := FUsers.Count;
end;

constructor TRESTAuthentication.Create;
begin
  FUsers := TDictionary<string, IRESTUserAuthenticate>.Create;
end;

destructor TRESTAuthentication.Destroy;
begin
  FreeAndNil(FUsers);
  inherited;
end;

procedure TRESTAuthentication.RemoveUser(const pUserName, pPassword: string);
var
  vUser: IRESTUserAuthenticate;
begin
  vUser := TRESTUserAuthenticate.Create;
  vUser.UserName := pUserName;
  vUser.Password := pPassword;
  RemoveUser(vUser.ApiKey);
end;

procedure TRESTAuthentication.RemoveUser(const pApiKey: string);
begin
  FUsers.Remove(pApiKey);
end;

function TRESTAuthentication.UserIsValid(const pApiKey: string): Boolean;
begin
  Result := FUsers.ContainsKey(pApiKey);
end;

function TRESTAuthentication.UserIsValid(const pUserName, pPassword: string): Boolean;
var
  vUser: IRESTUserAuthenticate;
begin
  vUser := TRESTUserAuthenticate.Create;
  vUser.UserName := pUserName;
  vUser.Password := pPassword;
  Result := UserIsValid(vUser.ApiKey);
end;

{ TRESTUserAuthenticationFactory }

class function TRESTAuthenticationFactory.Build: IRESTAuthentication;
begin
  Result := TRESTAuthentication.Create;
end;

end.
