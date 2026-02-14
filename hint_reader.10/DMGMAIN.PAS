
unit DMGMain;

{===============================================================}
{ Hauptunit der DMGrafik.dll                                    }
{ Copyright (C) 1991 - 1996 Detlef Meister                      }
{								}
               Interface
{								}
{===============================================================}

uses Windows;

{==============================================	exportierte Main-Funktionen}
function  mg_GrafikVersion: word; stdcall;
procedure mg_GrafikFehler(Win: tHandle; Tit, Zus: pChar; Err: word); stdcall;
function  mg_GetLastError: word; stdcall;
function  mg_LoadThePicture(Name: pChar; InMem: bool): pBitmapInfo; stdcall;
function  mg_CheckFormat(Extension: pChar): Bool; stdcall;
procedure mg_SetTheCallBack(CallBack: tFarProc); stdcall;
procedure mg_FreeTheDIB(pBMI: pBitmapInfo); stdcall;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses DMGBasic, DMGrBMP, DMGrGIF, DMGrJPEG, DMGrPCX, DMGrTGA, SysUtils;
{$ifdef Is_DMGrafik_DLL}
  {$R DMGVersn.res}
  {$R DMGIcons.res}
{$endif}
{$R DMGError.res}

{==============================================	private Funktionen}

{----------------------------------------------	GetFormatTyp}
function GetFormatTyp(Extension: PChar): tBildFormat;
var
Buf             : string;
begin
  Buf := AnsiLowerCase(StrPas(Extension));
  if (Buf = '.bmp') OR (Buf = '.dib') OR (Buf = '.rle') then Result := tbf_BMP
  else if (Buf = '.jpg') then Result := tbf_JPG
  else if (Buf = '.tga') then Result := tbf_TGA
  else if (Buf = '.pcx') then Result := tbf_PCX
  else if (Buf = '.gif') then Result := tbf_GIF
  else Result := tbf_Unknown;
end {function GetFormatTyp};

{==============================================	Exportierte Main-Funktionen}

{----------------------------------------------	mg_GrafikVersion}
function mg_GrafikVersion: word;
begin
  Result := DMG_Version;
end {function mg_GrafikVersion};
{----------------------------------------------	mg_GrafikFehler}
procedure mg_GrafikFehler(Win: tHandle; Tit, Zus: pChar; Err: word);
var
Buf             : string;
begin
  if (Err > MGERR_LAST) OR (Err < MGERR_FIRST) then exit;
  Buf := LoadStr(Err);
  if (Zus <> nil) then Buf := Buf + Zus;
  MessageBeep(mb_IconHand);
  MessageBox(Win, pChar(Buf), Tit, mb_IconHand);
end {procedure mg_GrafikFehler};
{----------------------------------------------	mg_GetLastError}
function mg_GetLastError: word;
begin
  Result := mg_LastError;
  mg_LastError := 0;
end {function mg_GetLastError};
{----------------------------------------------	mg_CheckFormat}
function mg_CheckFormat(Extension: pChar): Bool;
begin
  if (GetFormatTyp(Extension) <> tbf_Unknown)
  then mg_CheckFormat := true
  else mg_CheckFormat := false;
end {function mg_CheckFormat};
{----------------------------------------------	mg_SetTheCallBack}
procedure mg_SetTheCallBack(CallBack: tFarProc);
begin
  MulTa := CallBack;
end {procedure mg_SetTheCallBack};
{----------------------------------------------	mg_LoadThePicture}
function mg_LoadThePicture(Name: pChar; InMem: bool): pBitmapInfo;
var
Buf             : string;
bErg            : boolean;
begin
  {------------	DMGS initialisieren}
  FillChar(DMGS, sizeof(tDMGS), #0);
  mg_LastError  := 0;
  DMGS.Bildname := Name;
  InMemory      := InMem;                       {laden vom Speicher/Datei}
  {------------	Testen, ob Datei existiert}
  if FileExists(DMGS.Bildname)
  then begin
       {-------- BildFormat testen}
       Buf := ExtractFileExt(StrPas(Name));
       case GetFormatTyp(pChar(Buf)) of
            tbf_BMP:  bErg := LoadTheDIB;
            tbf_JPG:  bErg := LoadTheJPG;
            tbf_TGA:  bErg := LoadTheTGA;
            tbf_PCX:  bErg := LoadThePCX;
            tbf_GIF:  bErg := LoadTheGIF;
            else begin
                 mg_LastError := MGERR_NOTSUPPORT;
                 bErg  := false;
            end;
       end {case FormatTyp};
       {-------- Ergebnisse zurückgeben - Fehler wurde in Subroutine gesetzt}
       if bErg then Result := DMGS.pBMI else Result := nil;
  end {FileExists}
  else begin
       Result := nil;
       mg_LastError := MGERR_FILENOTFND;
  end {Datei gibt's nicht};
end {function mg_LoadThePicture};
{----------------------------------------------	mg_FreeTheDIB}
procedure mg_FreeTheDIB(pBMI: pBitmapInfo);
begin
  if (pBMI <> nil) then FreeMem(pBMI);
end {procedure mg_FreeTheDIB};

end.
