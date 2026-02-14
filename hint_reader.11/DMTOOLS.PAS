
unit DMTools;

{===============================================================}
{								}
        Interface
{								}
{===============================================================}

{----------------------------------------------	Units/Resources}
uses
  Forms, Windows;
  {$R DMTools.res}

{==============================================	Fehler-Konstanten}

{---------------------------------------------- StandardError}
const
MTERR_STDFIRST   =  0;
MTERR_UNKNOWN    =  MTERR_STDFIRST;
MTERR_CANCEL     =  MTERR_STDFIRST + 1;
MTERR_NOMEMORY	 =  MTERR_STDFIRST + 2;
MTERR_MEMNOTFIX	 =  MTERR_STDFIRST + 3;
MTERR_STDLAST	 =  MTERR_STDFIRST + 3;
{---------------------------------------------- ExtendedError}
const
MTERR_EXTFIRST	 = 32;
MTERR_READOPEN   = 32;
MTERR_WRITEOPEN  = 33;
MTERR_READERROR  = 34;
MTERR_WRITEERROR = 35;
MTERR_SAMEDIR    = 36;
MTERR_NOASSOCIE  = 37;
MTERR_CREATEDIR  = 38;
MTERR_RENAME     = 39;
MTERR_FILENOTFND = 40;
MTERR_NOFILEINFO = 41;
MTERR_ZEROLENGTH = 42;
MTERR_EXTLAST	 = 42;
{---------------------------------------------- ApplicationError}
const
app_FirstError   = 304;

{==============================================	Registry-Konstanten}

{--------------- Abschnitt unter HKey_Current_User}
MeisterRegistry  = 'Software\Meister Tools 95';

{==============================================	Unit-Funktionen}

{---------------------------------------------- Fehler- und Meldungsfunktionen}
procedure mt_StandardError(Fehler: word);
procedure mt_ExtendedError(Fehler: word; ExText: string);
procedure mt_ApplicationError(Fehler: word; ExText: string);
procedure mt_StartPicture;
{---------------------------------------------- String-Funktionen}
function  mt_PatternMatch(P, F: string): boolean;
function  mt_PatternMatchCS(P, F: string): boolean;
function  mt_LongToStr(Num: longint; Size: byte; Fill: char): string;
function  mt_FmtNum(Nummer: longint): string;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses
  SysUtils;


{==============================================	Lokale Konstanten}
const
Res_Bitmap      = 'DMTools_BMP';

{==============================================	Lokale Funktionen}

{----------------------------------------------	MatchPattern}
function MatchPattern(P, F: pChar; cp, cf: word): Boolean;
var
zp, zf		: char;
begin
  zp := P[cp];
  inc(cp, 1);
  while (zp <> chr(0))
  do begin
     case zp of
     '*': begin
          if (P[cp] = chr(0))
          then begin
               Result := true;
               exit;
          end {if P[cp] = 0...}
          else begin
               repeat
               if MatchPattern(P, F, cp, cf)	{rekursiv aufrufen}
               then begin
                    Result := true;
                    exit;
               end {if MatchPattern...};
               zf := F[cf];
               inc(cf, 1);
               until (zf = chr(0));
               Result := false;
               exit;
          end {else...};
     end {case '*'};
     '?': begin
          zf := F[cf];
          inc(cf, 1);
          if (zf = chr(0))
          then begin
               Result := false;
               exit;
          end {if Ende FileNameString...};
     end {case '?'};
     else {if case not '*' OR '?'}
          zf := F[cf];
          inc(cf, 1);
          if (zf <> zp)
          then begin
               Result := false;
               exit;
          end {if zp <> zf...};
     end {case...else...};
     zp := P[cp];
     inc(cp, 1);
  end {while zp <> 0...};
  if (F[cf] = chr(0))
  then Result := true
  else Result := false;
end {function MatchPattern};

{==============================================	Fehler- und Meldungsfunktionen}

{---------------------------------------------- mt_StandardError}
procedure mt_StandardError(Fehler: word);
var
Text            : string;
begin
  if (Fehler > MTErr_StdLast) OR (Fehler < MTErr_StdFirst)
  then Fehler := MTErr_Unknown;
  Text := LoadStr(Fehler);
  MessageBeep(mb_IconHand);
  Application.MessageBox(pChar(Text), pChar(Application.Title), mb_IconHand);
end {procedure mt_StandardError};
{---------------------------------------------- mt_ExtendedError}
procedure mt_ExtendedError(Fehler: word; ExText: string);
var
Text            : string;
begin
  if (Fehler > MTErr_ExtLast) OR (Fehler < MTErr_ExtFirst)
  then mt_StandardError(MTErr_Unknown)
  else begin
       Text := LoadStr(Fehler) + #13#10 + ExText;
       MessageBeep(mb_IconHand);
       Application.MessageBox(pChar(Text), pChar(Application.Title), mb_IconHand);
  end;
end {procedure mt_ExtendedError};
{---------------------------------------------- mt_ApplicationError}
procedure mt_ApplicationError(Fehler: word; ExText: string);
var
Text            : string;
begin
  {------------- app_LastError im Programm abfangen}
  if (Fehler < app_FirstError)
  then mt_StandardError(MTErr_Unknown)
  else begin
       Text := LoadStr(Fehler) + #13#10 + ExText;
       MessageBeep(mb_IconHand);
       Application.MessageBox(pChar(Text), pChar(Application.Title), mb_IconHand);
  end;
end {procedure mt_ApplicationError};
{----------------------------------------------	mt_StartPicture}
procedure mt_StartPicture;
var
Ticks		: longint;
BM, OldBM	: hBitmap;
MDC, OldDC	: hDC;
dx, dy, ex, ey	: integer;
Bitmap          : tBitmap;
begin
  {------------ Bitmap aus der DLL laden}
  BM := LoadBitmap(HInstance, Res_Bitmap);
  if (BM = 0) then exit;			{Bitmap gibt es nicht...}
  MDC := CreateDC('DISPLAY', nil, nil, nil);
  if (MDC <> 0)
  then begin
       dx := GetDeviceCaps(MDC, HorzRes);	{Koordinaten ermitteln}
       dy := GetDeviceCaps(MDC, VertRes);
       OldDC := CreateCompatibleDC(MDC);
       if (OldDC <> 0)
       then begin
  	    OldBM := SelectObject(OldDC, BM);
            GetObject(BM, sizeof(tBitmap), @Bitmap);
            ex := Bitmap.bmWidth;
            ey := Bitmap.bmHeight;
            dx := (dx - ex) DIV 2;
            dy := (dy - ey) DIV 2;
  	    BitBlt(MDC, dx, dy, ex, ey, OldDC, 0, 0, SrcCopy);
  	    Ticks := GetTickCount;
  	    repeat until (abs(Ticks - GetTickCount) > 2000);
       	    DeleteObject(SelectObject(OldDC, OldBM));
  	    DeleteDC(OldDC);
       end {if OldDC <> 0...};
       DeleteDC(MDC);
  end {if MDC <> 0...};
end {procedure mt_StartPicture};

{==============================================	String-Funktionen}

{----------------------------------------------	mt_PatternMatch}
function mt_PatternMatch(P, F: string): boolean;
begin
  Result := MatchPattern(pChar(AnsiLowerCase(P)), pChar(AnsiLowerCase(F)), 0, 0);
end {function mt_PatternMatch};
function mt_PatternMatchCS(P, F: string): boolean;
begin
  Result := MatchPattern(pChar(P), pChar(F), 0, 0);
end {function mt_PatternMatchCS};
{----------------------------------------------	mt_LongToStr}
function mt_LongToStr(Num: longint; Size: byte; Fill: char): string;
var
Buf 		: string;
begin
  Str(Num: Size, Buf);
  if (Fill <> chr(32))
  then while (Pos(chr(32), Buf) <> 0)
  do Buf[Pos(chr(32), Buf)] := Fill;
  Result := Buf;
end {function mt_LongToStr};
{---------------------------------------------- Formatierung mit 1000'er}
function mt_FmtNum(Nummer: longint): string;
begin
  Result := FormatFloat('#,##0', StrToFloat(IntToStr(Nummer)));
end {function mt_FmtNum};

end {unit DMTools}.
