{
    AWS
    Copyright (C) 2013-2014 by mdbs99

    See the file LICENSE.txt, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
}
unit aws_s3;

{$i aws.inc}

interface

uses
  //rtl
  classes,
  sysutils,
  //synapse
  httpsend,
  synacode,
  synautil,
  ssl_openssl,
  //aws
  aws_sys,
  aws_client;

type
  ES3Error = class(Exception);

  IS3Response = IAWSResponse;

  IS3Object = interface(IInterface)
    function Name: string;
  end;

  IS3Objects = interface(IInterface)
    function Get(const AName, AFileName: string): IS3Object;
    function Get(const AName: string; AStream: TStream): IS3Object;
    procedure Delete(const AName: string);
    function Put(const AName, ContentType, AFileName: string; const Resources: string): IS3Object;
    function Put(const AName, ContentType: string; AStream: TStream; const Resources: string): IS3Object;
  end;

  IS3Bucket = interface(IInterface)
    function Name: string;
    function Objects: IS3Objects;
  end;

  IS3Buckets = interface(IInterface)
    function Check(const AName: string): Boolean;
    function Get(const AName, Resources: string): IS3Bucket;
    procedure Delete(const AName, Resources: string);
    function Put(const AName, Resources: string): IS3Bucket;
    { TODO : Return a Bucket list }
    function All: IS3Response;
  end;

  IS3Region = interface(IInterface)
    function Client: IAWSClient;
    function IsOnline: Boolean;
    function Buckets: IS3Buckets;
  end;

  TS3Objects = class sealed(TInterfacedObject, IS3Objects)
  private
    FBucket: IS3Bucket;
  public
    constructor Create(Bucket: IS3Bucket);
    function Get(const AName, AFileName: string): IS3Object;
    function Get(const AName: string; AStream: TStream): IS3Object;
    procedure Delete(const AName: string);
    function Put(const AName, ContentType, AFileName: string; const Resources: string): IS3Object;
    function Put(const AName, ContentType: string; AStream: TStream; const Resources: string): IS3Object;
  end;

  TS3Region = class;

  TS3Bucket = class sealed(TInterfacedObject, IS3Bucket)
  private
    FName: string;
  public
    constructor Create(const AName: string);
    function Name: string;
    function Objects: IS3Objects;
  end;

  TS3Buckets = class sealed(TInterfacedObject, IS3Buckets)
  private
    FRegion: IS3Region;
  public
    constructor Create(Region: IS3Region);
    function Check(const AName: string): Boolean;
    function Get(const AName, Resources: string): IS3Bucket;
    procedure Delete(const AName, Resources: string);
    function Put(const AName, Resources: string): IS3Bucket;
    function All: IS3Response;
  end;

  TS3Region = class sealed(TInterfacedObject, IS3Region)
  private
    FClient: IAWSClient;
    FBuckets: IS3Buckets;
  public
    constructor Create(AClient: IAWSClient);
    function Client: IAWSClient;
    function IsOnline: Boolean;
    function Buckets: IS3Buckets;
  end;


 /////////////////////////////////////////////////////////////////////////////
 //                         DEPRECATED                                      //
 /////////////////////////////////////////////////////////////////////////////

  TAWSS3Client = class
  private const
    S3_URL = 's3.amazonaws.com';
  private
    FHTTP: THTTPSend;
    FAccessKeyId: AnsiString;
    FSecretKey: AnsiString;
    FUseSSL: Boolean;
    procedure SetAuthHeader(AVerb, AContentMD5, AContentType,
      CanonicalizedAmzHeaders, CanonicalizedResource: string);
    function Send(const AVerb, ABucket, AQuery: string): Integer;
  public
    constructor Create; deprecated;
    destructor Destroy; override;

    // SERVICE
    function GETService: Integer;

    // BUCKET
    function HEADBucket(const ABucket: string): Boolean;
    function GETBucket(const ABucket, ASubResources: string): Integer; overload;
    function PUTBucket(const ABucket, ASubResources: string): Integer;
    function DELETEBucket(const ABucket, ASubResources: string): Integer;

    // OBJECT
    function PUTObject(const ABucket, AContentType, AObjectName: string; AStream: TStream): Integer; overload;
    function PUTObject(const ABucket, AContentType, AObjectName, AFileName: string): Integer; overload;
    function GETObject(const ABucket, AObjectName, AFileName: string): Integer;
    function GETObject(const ABucket, AObjectName: string; AStream: TStream): Integer;
    function DELETEObject(const ABucket, AObjectName: string): Integer;

    // Utilities
    function PUTFolder(const ABucket, ANewFolder: string): Integer;
    function DELETEFolder(const ABucket, AFolderName: string): Integer;

    // Properties
    property HTTP: THTTPSend read FHTTP;
    property AccessKeyId: AnsiString read FAccessKeyId write FAccessKeyId;
    property SecretKey: AnsiString read FSecretKey write FSecretKey;
    property UseSSL: Boolean read FUseSSL write FUseSSL;
  end;
/////////////////////////////////////////////////////////////////////////////

implementation

{ TS3Objects }

constructor TS3Objects.Create(Bucket: IS3Bucket);
begin
  SetWeak(@FBucket, Bucket);
end;

function TS3Objects.Get(const AName, AFileName: string): IS3Object;
begin
  Result := nil;
end;

function TS3Objects.Get(const AName: string; AStream: TStream): IS3Object;
begin
  Result := nil;
end;

procedure TS3Objects.Delete(const AName: string);
begin

end;

function TS3Objects.Put(const AName, ContentType, AFileName: string;
  const Resources: string): IS3Object;
begin
  Result := nil;
end;

function TS3Objects.Put(const AName, ContentType: string; AStream: TStream;
  const Resources: string): IS3Object;
begin
  Result := nil;
end;

{ TS3Bucket }

constructor TS3Bucket.Create(const AName: string);
begin
  FName := AName;
end;

function TS3Bucket.Name: string;
begin
  Result := FName;
end;

function TS3Bucket.Objects: IS3Objects;
begin
  Result := nil;
end;

{ TS3Buckets }

constructor TS3Buckets.Create(Region: IS3Region);
begin
  SetWeak(@FRegion, Region);
end;

function TS3Buckets.Check(const AName: string): Boolean;
begin
  Result := FRegion.Client.Send(
    TAWSRequest.Create(
      'HEAD', AName, '', '', '', '', '/' + AName + '/'
    )
  ).ResultCode = 200;
end;

function TS3Buckets.Get(const AName, Resources: string): IS3Bucket;
var
  Res: IAWSResponse;
begin
  Res := FRegion.Client.Send(
    TAWSRequest.Create(
      'GET', AName, Resources, '', '', '', '/' + AName + '/' + Resources
    )
  );
  if 200 <> Res.ResultCode then
    raise ES3Error.CreateFmt('Get error: %d', [Res.ResultCode]);
  Result := TS3Bucket.Create(AName);
end;

procedure TS3Buckets.Delete(const AName, Resources: string);
var
  Res: IAWSResponse;
begin
  Res := FRegion.Client.Send(
    TAWSRequest.Create(
      'DELETE', AName, Resources, '', '', '', '/' + AName + Resources
    )
  );
  if 204 <> Res.ResultCode then
    raise ES3Error.CreateFmt('Delete error: %d', [Res.ResultCode]);
end;

function TS3Buckets.Put(const AName, Resources: string): IS3Bucket;
var
  Res: IAWSResponse;
begin
  Res := FRegion.Client.Send(
    TAWSRequest.Create(
      'PUT', AName, Resources, '', '', '', '/' + AName + Resources
    )
  );
  if 200 <> Res.ResultCode then
    raise ES3Error.CreateFmt('Put error: %d', [Res.ResultCode]);
  Result := TS3Bucket.Create(AName);
end;

function TS3Buckets.All: IS3Response;
begin
  Result := FRegion.Client.Send(TAWSRequest.Create('GET', '', '', '', '', '', '/'));
end;

{ TS3Region }

constructor TS3Region.Create(AClient: IAWSClient);
begin
  inherited Create;
  FClient := AClient;
  FBuckets := TS3Buckets.Create(Self);
end;

function TS3Region.Client: IAWSClient;
begin
  Result := FClient;
end;

function TS3Region.IsOnline: Boolean;
begin
  Result := Client.Send(
    TAWSRequest.Create(
      'GET', '', '', '', '', '', '/'
    )
  ).ResultCode = 200;
end;

function TS3Region.Buckets: IS3Buckets;
begin
  Result := FBuckets;
end;

{ TAWSS3Client }

procedure TAWSS3Client.SetAuthHeader(AVerb, AContentMD5, AContentType,
  CanonicalizedAmzHeaders, CanonicalizedResource: string);
var
  Header: string;
  HeaderBase64: string;
  DateFmt: string;
begin
  DateFmt := RFC822DateTime(Now);

  Header := AVerb + #10
     + AContentMD5 + #10
     + AContentType + #10
     + DateFmt + #10
     + CanonicalizedAmzHeaders
     + CanonicalizedResource;

  HeaderBase64 := EncodeBase64(HMAC_SHA1(Header, FSecretKey));

  FHTTP.Headers.Add('Date: ' + DateFmt);
  FHTTP.Headers.Add('Authorization: AWS ' + FAccessKeyId + ':' + HeaderBase64);
end;

function TAWSS3Client.Send(const AVerb, ABucket, AQuery: string): Integer;
var
  URL: string;
begin
  URL := '';
  if FUseSSL then
    URL += 'HTTPs://'
  else
    URL += 'HTTP://';

  if ABucket <> '' then
    URL += ABucket + '.';

  URL += S3_URL + AQuery;
  FHTTP.HTTPMethod(AVerb, URL);
  Result := FHTTP.ResultCode;
end;

constructor TAWSS3Client.Create;
begin
  inherited Create;
  FHTTP := THTTPSend.Create;
  FHTTP.Protocol := '1.0';
end;

destructor TAWSS3Client.Destroy;
begin
  FHTTP.Free;
  inherited Destroy;
end;

function TAWSS3Client.GETService: Integer;
begin
  FHTTP.Clear;
  SetAuthHeader('GET', '', '', '', '/');
  Result := Send('GET', '', '');
end;

function TAWSS3Client.HEADBucket(const ABucket: string): Boolean;
begin
  FHTTP.Clear;
  SetAuthHeader('HEAD', '', '', '', '/' + ABucket + '/');
  Send('HEAD', ABucket, '');
  Result := FHTTP.ResultCode = 200;
end;

function TAWSS3Client.GETBucket(const ABucket, ASubResources: string): Integer;
begin
  FHTTP.Clear;
  SetAuthHeader('GET', '', '', '', '/' + ABucket + '/' + ASubResources);
  Result := Send('GET', ABucket, '/' + ASubResources);
end;

function TAWSS3Client.PUTBucket(const ABucket, ASubResources: string): Integer;
begin
  FHTTP.Clear;
  SetAuthHeader('PUT', '', '', '', '/' + ABucket + '/' + ASubResources);
  Result := Send('PUT', ABucket, '/' + ASubResources);
end;

function TAWSS3Client.DELETEBucket(const ABucket, ASubResources: string): Integer;
begin
  FHTTP.Clear;
  SetAuthHeader('DELETE', '', '', '', '/' + ABucket + ASubResources);
  Result := Send('DELETE', ABucket, ASubResources);
end;

function TAWSS3Client.PUTObject(const ABucket, AContentType,
  AObjectName: string; AStream: TStream): Integer;
begin
  FHTTP.Clear;
  SetAuthHeader('PUT', '', AContentType, '', '/' + ABucket + '/' + AObjectName);
  FHTTP.MimeType := AContentType;
  FHTTP.Document.LoadFromStream(AStream);
  Result := Send('PUT', ABucket, '/' + AObjectName);
end;

function TAWSS3Client.PUTObject(const ABucket, AContentType, AObjectName,
  AFileName: string): Integer;
var
  Buf: TFileStream;
begin
  Buf := TFileStream.Create(AFileName, fmOpenRead);
  try
    Result := PUTObject(ABucket, AContentType, AObjectName, Buf);
  finally
    Buf.Free;
  end;
end;

function TAWSS3Client.GETObject(const ABucket, AObjectName: string; AStream: TStream): Integer;
begin
  FHTTP.Clear;
  SetAuthHeader('GET', '', '', '', '/' + ABucket + '/' + AObjectName);
  Result := Send('GET', ABucket, '/' + AObjectName);
  FHTTP.Document.SaveToStream(AStream);
end;

function TAWSS3Client.GETObject(const ABucket, AObjectName, AFileName: string): Integer;
var
  Buf: TFileStream;
begin
  Buf := TFileStream.Create(AFileName, fmCreate);
  try
    Result := GetObject(ABucket, AObjectName, Buf);  // above
  finally
    Buf.Free;
  end;
  if result <> 200 then
    deleteFile(AFilename);
end;

function TAWSS3Client.DELETEObject(const ABucket, AObjectName: string): Integer;
begin
  FHTTP.Clear;
  SetAuthHeader('DELETE', '', '', '', '/' + ABucket + '/' + AObjectName);
  // seems to work
  Result := Send('DELETE', '', '/'+ABucket +'/'+AObjectName); 
end;

function TAWSS3Client.PUTFolder(const ABucket, ANewFolder: string): Integer;
var
  Buf: TMemoryStream;
begin
  Buf := TMemoryStream.Create;
  try
    // hack to synapse add Content-Length
    Buf.WriteBuffer('', 1);
    Result := PUTObject(ABucket, '', ANewFolder + '/', Buf);
  finally
    Buf.Free;
  end;
end;

function TAWSS3Client.DELETEFolder(const ABucket, AFolderName: string): Integer;
begin
  Result := DELETEObject(ABucket, AFolderName + '/');
end;

end.
