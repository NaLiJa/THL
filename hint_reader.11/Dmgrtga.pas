
unit Dmgrtga;

{===============================================================}
{ Targa-Bilder-Konverter der DMGrafik.dll                       }
{ Copyright (C) 1991 - 1996 Detlef Meister                      }
{								}
               Interface
{								}
{===============================================================}

uses Windows;

{==============================================	öffentliche TGA-Funktionen}
function LoadTheTGA: boolean;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses DMGBasic, SysUtils;

{==============================================	lokale Typen und Konstanten}

{----------------------------------------------	TGA-Header}
type
pTGAHeader	= ^tTGAHeader;
tTGAHeader	= packed record
		  IDlen		: byte;
                  CMapType	: byte;
                  SubType	: byte;
                  B3            : word;
                  MapLen	: word;
                  MapEntrySize	: byte;
                  B8            : byte;
                  B9	        : byte;
                  B10           : byte;
                  B11	        : byte;
                  Width		: word;
                  Height	: word;
                  Flags1	: byte;
                  Flags2	: byte;
end {record tTGAHeader};
{----------------------------------------------	Umrechnung für 16bpp-Bilder}
const
c5to8bits       : array[0..31] of Byte
                = (  0,   8,  16,  24,  32,  41,  49,  57,
                    65,  74,  82,  90,  98, 106, 115, 123,
                   131, 139, 148, 156, 164, 172, 180, 189,
                   197, 205, 213, 222, 230, 238, 246, 255);

{==============================================	lokale Hilfsfunktionen}

{----------------------------------------------	GetHeader}
function GetHeader(TGAHeader: pTGAHeader): boolean;
var
i               : integer;
PixelSize       : byte;
InterlaceType   : byte;
begin
  Result := false;
  with DMGS
  do begin
     {--------- den Header einlesen}
     rGelesen := Stream.Read(TGAHeader^, sizeof(tTGAHeader));
     if (rGelesen <> sizeof(tTGAHeader))
     then begin
          mg_LastError := MGERR_READERROR;
          rError := true;
          exit;
     end;
     rOffset :=  sizeof(tTGAHeader);
     {--------- die nötigen Werte berechnen}
     with TGAHeader^
     do begin
        if (Flags1 = 15) then Flags1 := 16;
        BPP           := Flags1 AND 7;          {muß durch 8 teilbar sein}
        PixelSize     := Flags1 SHR 3;
        InterlaceType := Flags2 SHR 6;
        {------ Header testen}
        if (MapLen > 0)                         {diese Version: nur 24/32 bpp}
        OR (PixelSize < 2) OR (PixelSize > 4)
        OR (BPP <> 0)
        OR (InterlaceType <> 0)                 {diese Version: kein Interlace}
        OR (SubType <> 2) AND (SubType <> 10)   {diese Version: nur 24/32 bpp}
        then begin
             mg_LastError := MGERR_WRONGFORM;
             exit;
        end;
        {------ ID überlesen}
        for i := 0 to IDlen - 1 do GetStreamByte;
     end {with TGAHeader^};
     if rError
     then mg_LastError := MGERR_READERROR
     else Result := true;
  end {with DMGS};
end {function GetHeader};
{----------------------------------------------	Expand}
function Expand(PixelSize: byte; Coding: boolean): boolean;
var
BlkCnt          : smallint;
RleCnt          : smallint;
i               : integer;
j               : byte;
ImagePixel      : array[1..4] of byte;
{----------------------------------------------	Subprocedure ReadPixel}
procedure ReadPixel;
var
i               : integer;
begin
  for i := 1 to PixelSize do ImagePixel[i] := GetStreamByte;
end {procedure ReadPixel};
{----------------------------------------------	Subprocedure ReadRLEPixel}
procedure ReadRLEPixel;
var
i               : integer;
ImageByte       : byte;
begin
  {------------ gepackter PixelBlock}
  if (RleCnt > 0)
  then begin
       dec(RleCnt);
       exit;
  end {gepackter PixelBlock};
  {------------ neuen Block bearbeiten}
  dec(BlkCnt);
  if (BlkCnt < 0)
  then begin
       ImageByte := GetStreamByte;
       {------- neuer gepackter Block}
       if (ImageByte AND $80 <> 0)
       then begin
            RleCnt := smallint(ImageByte AND $7f);
            BlkCnt := 0;
       end {neuer gepackter Block}
       {------- neuer ungepackter Block}
       else begin
            BlkCnt := smallint(ImageByte AND $7f);
       end {neuer ungepackter Block};
  end {if (BlkCnt < 0)};
  for i := 1 to PixelSize do ImagePixel[i] := GetStreamByte;
end {procedure ReadRLEPixel};
{----------------------------------------------	MainFunction Expand}
begin
  with DMGS
  do begin
     Result := false;
     BlkCnt := 0;
     RleCnt := 0;
     {--------- Einlese-Methode}
     case PixelSize of

          {---- 16bpp}
          2   :
          repeat
            if (Coding) then ReadRlePixel else ReadPixel;
            i := ImagePixel[1] + (ImagePixel[2] SHL 8);
            j := c5to8bits[i AND $1f];
            SetExpandByte(j);
            i := i SHR 5;
            j := c5to8bits[i AND $1f];
            SetExpandByte(j);
            i := i SHR 5;
            j := c5to8bits[i AND $1f];
            SetExpandByte(j);
          until rError OR wError OR bAbort;

          {---- 24/32bpp}
          3, 4:
          repeat
            if (Coding) then ReadRlePixel else ReadPixel;
            for i := 1 to 3 do SetExpandByte(ImagePixel[i]);
          until rError OR wError OR bAbort;

     end {case};
     {--------- Puffer leeren}
     SetExpandByte(Flush_Buffer);
     if bAbort
     then mg_LastError := MGERR_CANCEL
     else Result := true;
  end {with DMGS};
end {function Expand};
{----------------------------------------------	Repack24}
procedure Repack24(IsBottomUp: boolean);
var
pDIBv           : pointer;
pTGAv           : pointer;
DIBoff          : longint;
y, cHei         : integer;
Proz            : longint;
begin
  with DMGS
  do begin
     {--------- Startinitialisierungen}
     wOffset := 0;                              {Anfang Expanded-Bild-Speicher}
     if IsBottomUp
     then DIBoff := cBMI - cDIBline             {Anfang des DIB}
     else DIBoff := cDIB + cBMI;                {Ende des DIB}
     cHei := pBMI^.bmiHeader.biHeight;
     ProzFaktor := 100 / cHei;
     {--------- alle Bildzeilen bearbeiten}
     for y := 1 to cHei
     do begin
        pTGAv := pWrite + wOffset;
        inc(wOffset, wLineLength);
        if IsBottomUp then inc(DIBoff, cDIBline) else dec(DIBoff, cDIBline);
        pDIBv := pChar(pBMI) + DIBoff;
        Move(pTGAv^, pDIBv^, wLineLength);
        {------ MultiTasking}
        if (MulTa <> nil)
        then begin
             Proz   := round(y * ProzFaktor);
             bAbort := TMultiTasking(MulTa)(DMG_Repack, Proz);
             if bAbort then exit;
        end {MultiTasking};
     end {alle Bildzeilen bearbeiten};
  end {with DMGS};
end {procedure Repack24};

{==============================================	Öffentliche TGA-Funktionen}

{----------------------------------------------	LoadTheTGA}
{ Eingang:                                                }
{ in DMGS.Bildname         : DateiName und Pfad           }
{ Ausgang:                                                }
{ in DMGS.pBMI             : das Bild als DIB             }
{ in mg_LastError          : Fehler bei Return = false    }
function LoadTheTGA: boolean;
var
cWid, cHei	: word;
TGAHeader	: tTGAHeader;
PixelSize       : byte;
IsBottomUp      : boolean;
Coding          : boolean;
begin
  {------------	Start-Initialisierungen}
  Result := false;
  {------------	Stream erzeugen}
  if not(GetPictureStream)
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {Fehler beim Bild laden};
  {------------	TGA-Header einlesen}
  if not(GetHeader(@TGAHeader))
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {if LeseFehler beim TGA-Header};
  {------------ TGA-Werte ermitteln und DIB-Werte berechnen}
  with TGAHeader, DMGS
  do begin
     cWid        := longint(Width);
     cHei        := longint(Height);
     BPP         := 24;
     Farben      := 1 SHL BPP AND $1ff;
     cDIB        := mg_GetDIBSize(cWid, cHei, BPP);
     cDIBLine    := cDIB DIV cHei;
     cBMI        := sizeof(TBitmapInfoHeader);
     if (BPP < 9) then cBMI := cBMI + Farben * sizeof(TRGBQuad);
     PixelSize   := Flags1 SHR 3;
     IsBottomUp  := (Flags2 AND $20 = 0);
     wLineLength := longint(Width) * 3;
     wSize       := wLineLength * longint(cHei);
     if (SubType > 8)
     then begin
          Coding := true;
          dec(SubType, 8);
     end
     else Coding := false;
  end {with TGAHeader do with DMGS do};
  {------------- IOBuffers besorgen}
  DMGS.rBufLen := DMGS.cDIBLine;
  DMGS.wBufLen := DMGS.wLineLength * 3;
  if not(GetBufferMem)
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {Fehler beim Puffer holen};
  {------------ Expanded-TGA-Speicher holen}
  if not(GetExpandedMem)
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {keinen Speicher gekriegt};
  {------------ ImageDaten dekomprimieren und Original-Bild-Speicher freigeben}
  if not(Expand(PixelSize, Coding))
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {Fehler beim dekomprimieren ImageDaten};
  FreePictureStream;
  {------------ DIB-Werte berechnen}
  with DMGS
  do begin
     {---------- Speicher für DIB holen und verriegeln}
     pBMI := mg_SetupDIB(@Palette, cWid, cHei, cDIB, cBMI, BPP);
     if (pBMI = nil)
     then begin
          ExitConvProc(MGERR_NOMEMORY);
          exit;
     end {keinen Speicher gekriegt};
  end {with DMGS};
  {------------ TGAImage in DIBImage wandeln und ExpandedMem freigeben}
  Repack24(IsBottomUp);
  if DMGS.bAbort
  then begin
       ExitConvProc(MGERR_CANCEL);
       exit;
  end {Nutzerabbruch};
  FreeExpandedMem;
  {------------- Speicher bis auf DIB freigeben}
  ExitConvProc(0);
  Result := mg_LastError = 0;
end {function LoadTheTGA};

end.
