
unit Dmgrpcx;

{===============================================================}
{ PCX-Bilder-Konverter der DMGrafik.dll                         }
{ Copyright (C) 1991 - 1996 Detlef Meister                      }
{								}
               Interface
{								}
{===============================================================}

uses Windows;

{==============================================	öffentliche PCX-Funktionen}
function LoadThePCX: boolean;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses DMGBasic, SysUtils;

{==============================================	lokale Typen}

{----------------------------------------------	PCX-Header}
type
pPCXHeader	= ^tPCXHeader;
tPCXHeader	= packed record
		  ID		: byte;
                  Version	: byte;
                  Coding	: byte;
                  BitsPixel	: byte;
                  xMin		: word;
                  yMin		: word;
                  xMax		: word;
                  yMax		: word;
                  xDPI		: word;
                  yDPI		: word;
                  Colors	: array[0..15] of TRGBColor;
                  Reserved1	: byte;
                  Planes	: byte;
                  WidthBytes	: word;
                  ColorMode	: word;
                  Reserved2	: array[0..57] of byte;
end {record tPCXHeader};

{==============================================	lokale Hilfsfunktionen}

{----------------------------------------------	GetHeader}
function GetHeader(PCXHeader: pPCXHeader): boolean;
var
Palette16       : tLogPalette;
DC              : hDC;
i               : integer;
PaletteKennung  : byte;
begin
  with DMGS
  do begin
     Result := false;
     {--------- den Header einlesen}
     rGelesen := Stream.Read(PCXHeader^, sizeof(tPCXHeader));
     if (rGelesen <> sizeof(tPCXHeader))
     then begin
          mg_LastError := MGERR_READERROR;
          exit;
     end;
     {--------- Header testen}
     if (PCXHeader^.ID <> 10)
     then begin
          mg_LastError := MGERR_WRONGFORM;
          exit;
     end {unbekannter Header};
     {--------- die nötigen Werte berechnen}
     with PCXHeader^ do BPP := BitsPixel * Planes;
     Farben := (1 SHL BPP) AND $1ff;
     {--------- PCX-Format Version 3 hat keine Palette}
     if (PCXHeader^.Version = 3)
     then begin
          DC := CreateDC('Display', nil, nil, nil);
          GetSystemPaletteEntries(DC, 0, Farben, Palette16.palPalEntry);
          DeleteDC(DC);
          for i := 0 to Farben - 1
          do with Palette16.palPalEntry[i]
          do begin
             Palette[i, Red]   := peRed;
             Palette[i, Green] := peGreen;
             Palette[i, Blue]  := peBlue;
          end {for i := 0 to Farben - 1};
     end {PCX-Format Version 3}
     {--------- Extra-Palette für BPP = 8 in den letzten 769 Bytes}
     else if (BPP = 8)
     then begin
          {----- Stream-Ende minus Palette einstellen}
          Stream.Seek(-(sizeof(tRawPalette) + 1), 2);
          rGelesen := Stream.Read(PaletteKennung, sizeof(PaletteKennung));
          if (rGelesen <> sizeof(PaletteKennung))
          then begin
               mg_LastError := MGERR_READERROR;
               rError := true;
               exit;
          end;
          if (PaletteKennung <> $c)
          then begin
               mg_LastError := MGERR_WRONGFORM;
               exit;
          end {falsche PaletteKennung};
          rGelesen := Stream.Read(Palette, sizeof(tRawPalette));
          if (rGelesen <> sizeof(tRawPalette))
          then begin
               mg_LastError := MGERR_READERROR;
               rError := true;
               exit;
          end;
     end {PCX-Format 8bpp-Palette einlesen}
     {--------- Palette aus dem Header nehmen}
     else for i := 0 to Farben - 1
          do with PCXHeader^
          do begin
             Palette[i, Red]   := Colors[i, Red];
             Palette[i, Green] := Colors[i, Green];
             Palette[i, Blue]  := Colors[i, Blue];
     end {Palette aus dem Header nehmen};
     {--------- Datei auf Beginn ImageDaten einstellen}
     rOffset :=  sizeof(tPCXHeader);
     Stream.Seek(sizeof(tPCXHeader), 0);
  end {with DMGS};
  Result := true;
end {function GetHeader};
{----------------------------------------------	Expand}
function Expand(Coding: byte): boolean;
var
Zaehler, i      : byte;
ImageByte       : byte;
begin
  with DMGS
  do begin
     {--------- ImageDaten sind gepackt}
     if (Coding = 1)
     then repeat
          ImageByte := GetStreamByte;
          if (ImageByte AND $c0 = $c0)
          then begin
               Zaehler   := ImageByte AND $3f;
               ImageByte := GetStreamByte;
               for i := 1 to Zaehler do SetExpandByte(ImageByte);
          end else SetExpandByte(ImageByte);
     until rError OR wError OR bAbort
     {--------- ImageDaten sind ungepackt}
     else repeat
          ImageByte := GetStreamByte;
          SetExpandByte(ImageByte);
     until rError OR wError OR bAbort;          {rError, wError als Ende}
     {--------- Puffer leeren}
     SetExpandByte(Flush_Buffer);
     if bAbort
     then Result := false
     else Result := true;
  end {with DMGS};
end {function Expand};
{----------------------------------------------	Repack1or8}
procedure Repack1or8;
var
pDIBv, pPCXv    : pointer;
DIBoff          : longint;
y, cHei         : integer;
Proz            : longint;
begin
  with DMGS
  do begin
     {--------- Startinitialisierungen}
     wOffset := 0;                              {Anfang expanded PCX}
     DIBoff := cDIB + cBMI;
     cHei   := pBMI^.bmiHeader.biHeight;
     ProzFaktor := 100 / cHei;
     {--------- alle Bildzeilen bearbeiten}
     for y := 1 to cHei
     do begin
        {------ eine Zeile umkopieren}
        pPCXv := pWrite + wOffset;
        inc(wOffset, wLineLength);
        dec(DIBoff, cDibLine);
        pDIBv := pChar(pBMI) + DIBoff;
        Move(pPCXv^, pDIBv^, wLineLength);
        {------ MultiTasking}
        if (MulTa <> nil)
        then begin
             Proz   := round(y * ProzFaktor);
             bAbort := TMultiTasking(MulTa)(DMG_Repack, Proz);
             if bAbort then exit;
        end {MultiTasking};
     end {für alle Zeilen};
  end {with DMGS};
end {procedure Repack1or8};
{----------------------------------------------	Repack2or4}
procedure Repack2or4;
const
qMaske          = $80;
zmask1hb        = $20;
zmask2hb        = $02;
var
pDIBv, pPCXv    : ^byte;
p1, p2, p3, p4  : pByteArray;
DIBoff          : longint;
PCXZeile        : longint;
cqPix, czPix    : word;
cHei, cWid      : word;
x, y            : integer;
cqmask, czmask  : byte;
Proz            : longint;
begin
  with DMGS
  do begin
     {--------- Startinitialisierungen}
     p1 := nil;
     p2 := nil;
     p3 := nil;
     p4 := nil;
     wOffset := 0;                              {Anfang expanded PCX}
     with pBMI^.bmiHeader
     do begin
        cHei   := biHeight;
        cWid   := biWidth - 1;
     end {with pBMI^.bmiHeader};
     PCXZeile := wLineLength * BPP;             {mal Anzahl PCX-Planes}
     DIBoff   := cBMI + cDIB;
     case BPP of
          {----- bei zwei Planes nur zwei PCX-Zeilen adressieren}
          2: begin
               p1 := pByteArray(pWriteBuf);
               p2 := pByteArray(pChar(p1) + wLineLength);
             end {case 2};
          {----- bei vier Planes vier PCX-Zeilen adressieren}
          4: begin
               p1 := pByteArray(pWriteBuf);
               p2 := pByteArray(pChar(p1) + wLineLength);
               p3 := pByteArray(pChar(p2) + wLineLength);
               p4 := pByteArray(pChar(p3) + wLineLength);
             end {case 4};
     end {case BPP};
     ProzFaktor := 100 / cHei;
     dec(cHei);
     {--------- alle Bildzeilen bearbeiten}
     for y := 0 to cHei
     do begin
        {------ ganze Quellbildzeile in Puffer holen}
        pPCXv := pointer(pWrite + wOffset);
        inc(wOffset, PCXZeile);
        Move(pPCXv^, pWriteBuf^, PCXZeile);
        {------ SchreibPuffer erst löschen}
        fillchar(pReadBuf^, cDIBline, #0);
        {------ Pixelmasken und ZeilenOffsets setzen}
        cqmask := qMaske;
        case BPP of
             2: czmask := zmask1hb;
             4: czmask := qMaske;
             else czmask := 0;
        end {case BPP};
        cqPix  := 0;
        czPix  := 0;
        {------ eine Bildzeile bearbeiten}
        for x := 0 to cWid
        do begin
           case BPP of

                { vier Farben}
                2: begin
                     if (p2^[cqPix] AND cqmask <> 0)
                     then pReadBuf^[czPix] := pReadBuf^[czPix] OR czmask;
                     czmask := czmask SHR 1;
                     if (p1^[cqPix] AND cqmask <> 0)
                     then pReadBuf^[czPix] := pReadBuf^[czPix] OR czmask;
                     { Zieloffset gegebenenfalls erhöhen}
                     if (czmask = $10)
                     then czmask := zmask2hb
                     else begin
                          czmask := zmask1hb;
                          inc(czPix);
                     end {Zieloffset gegebenenfalls erhöhen};
                   end {case 2};

                { 16 Farben}
                4: begin
                     if (p4^[cqPix] AND cqmask <> 0)
                     then pReadBuf^[czPix] := pReadBuf^[czPix] OR czmask;
                     czmask := czmask SHR 1;
                     if (p3^[cqPix] AND cqmask <> 0)
                     then pReadBuf^[czPix] := pReadBuf^[czPix] OR czmask;
                     czmask := czmask SHR 1;
                     if (p2^[cqPix] AND cqmask <> 0)
                     then pReadBuf^[czPix] := pReadBuf^[czPix] OR czmask;
                     czmask := czmask SHR 1;
                     if (p1^[cqPix] AND cqmask <> 0)
                     then pReadBuf^[czPix] := pReadBuf^[czPix] OR czmask;
                     czmask := czmask SHR 1;
                     { Zieloffset gegebenenfalls erhöhen}
                     if (czmask = 0)
                     then begin
                          czmask := qMaske;
                          inc(czPix);
                     end {Zieloffset gegebenenfalls erhöhen};
                   end {case 4};

           end {case BPP};
           {---- Quelloffset gegebenenfalls erhöhen}
           cqmask := cqmask SHR 1;
           if (cqmask = 0)
           then begin
                cqmask := qMaske;
                inc(cqPix);
           end {Quelloffset gegebenenfalls erhöhen};
        end {eine Bildzeile bearbeiten};
        {------- ganze Zeile aus Buffer in DIB kopieren}
        dec(DIBoff, cDIBline);
        pDIBv := pointer(pChar(pBMI) + DIBoff);
        Move(pReadBuf^, pDIBv^, cDIBline);
        {------- MultiTasking}
        if (MulTa <> nil)
        then begin
             Proz   := round(y * ProzFaktor);
             bAbort := TMultiTasking(MulTa)(DMG_Repack, Proz);
             if bAbort then exit;
        end {MultiTasking};
     end {alle Zeilen bearbeiten};
  end {with DMGS};
end {procedure Repack2or4};
{----------------------------------------------	Repack24}
procedure Repack24;
var
pR, pG, pB      : pChar;
pDIBv           : pointer;
pPCXv           : pointer;
DIBoff          : longint;
x, y            : word;
cHei, cWid      : word;
PCXZeile        : longint;
Proz            : longint;
begin
  with DMGS
  do begin
     {--------- Startinitialisierungen}
     wOffset  := 0;                             {Anfang expanded PCX}
     PCXZeile := wlineLength * 3;               {Länge PCXZeile}
     DIBoff   := cDIB + cBMI;                   {Ende des DIB}
     cHei     := pBMI^.bmiHeader.biHeight;
     cWid     := pBMI^.bmiHeader.biWidth - 1;
     ProzFaktor := 100 / cHei;
     {---------- Zeiger auf je eine Zeile R, G und B einstellen}
     pR := pChar(pWriteBuf);                 {rote  PCX-Zeile}
     pG := pR + wLineLength;                 {grüne PCX-Zeile}
     pB := pG + wLineLength;                 {blaue PCX-Zeile}
     {--------- alle Bildzeilen bearbeiten}
     for y := 1 to cHei
     do begin
        {------ eine ganze PCX-Zeile mit je R, G, B in Puffer kopieren}
        pPCXv := pWrite + wOffset;
        Move(pPCXv^, pWriteBuf^, PCXZeile);
        inc(wOffset, PCXZeile);
        {------ eine PCX-Zeile mit je einer Zeile R, G, B}
        {       umsetzen in byte(B, G, R)                }
        for x := 0 to cWid
        do begin
           pBGRZeile(pReadBuf)^[x, Blau]  := byte(pB[x]);
           pBGRZeile(pReadBuf)^[x, Gruen] := byte(pG[x]);
           pBGRZeile(pReadBuf)^[x, Rot]   := byte(pR[x]);
        end {eine PCX-Zeile umsetzen};
        {------- bearbeitete Zeile ins DIB kopieren}
        dec(DIBoff, cDIBline);
        pDIBv := pChar(pBMI) + DIBoff;
        Move(pReadBuf^, pDIBv^, cDIBline);
        {------ MultiTasking}
        if (MulTa <> nil)
        then begin
             Proz   := round(y * ProzFaktor);
             bAbort := TMultiTasking(MulTa)(DMG_Repack, Proz);
             if bAbort then exit;
        end {MultiTasking};
     end {alle Bildzeilen bearbeiten};
  end {with DMGS do with DMGS};
end {procedure Repack24};

{==============================================	Öffentliche PCX-Funktionen}

{----------------------------------------------	LoadThePCX}
{ Eingang:                                                }
{ in DMGS.Bildname        : DateiName und Pfad            }
{ Ausgang:                                                }
{ in DMGS.pBMI            : das Bild als DIB              }
{ in mg_LastError         : Fehler bei Return = false     }
function LoadThePCX: boolean;
var
cWid, cHei	: word;
PCXHeader	: tPCXHeader;
begin
  {------------	Start-Initialisierungen}
  Result := false;
  {------------	Stream erzeugen}
  if not(GetPictureStream)
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {Fehler beim Bild laden};
  {------------	PCX-Header einlesen}
  if not(GetHeader(@PCXHeader))
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {if LeseFehler beim PCX-Header};
  {------------ PCX-Werte ermitteln und DIB-Werte berechnen}
  with PCXHeader, DMGS
  do begin
     cWid     := longint(xMax - xMin + 1);
     cHei     := longint(yMax - yMin + 1);
     BPP      := BitsPixel * Planes;
     cDIB     := mg_GetDIBSize(cWid, cHei, BPP);
     cDIBLine := cDIB DIV cHei;
     cBMI     := sizeof(TBitmapInfoHeader);
     if (BPP < 9) then cBMI := cBMI + Farben * sizeof(TRGBQuad);
     wLineLength := longint(WidthBytes);
     wSize := wLineLength * longint(cHei) * longint(Planes);
  end {with PCXHeader do with DMGS do};
  {------------- IOBuffers besorgen}
  DMGS.rBufLen := DMGS.cDIBLine;
  DMGS.wBufLen := DMGS.wLineLength * 3;
  if not(GetBufferMem)
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {Fehler beim Puffer holen};
  {------------ Expanded-PCX-Speicher holen}
  if not(GetExpandedMem)
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {keinen Speicher gekriegt};
  {------------ ImageDaten dekomprimieren und Original-Bild-Speicher freigeben}
  if not(Expand(PCXHeader.Coding))
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
     {---------- PCXImage in DIBImage wandeln und ExpandedMem freigeben}
     case BPP of
          1, 8 : Repack1or8;
          2, 4 : Repack2or4;
          24   : Repack24;
     end {case BPP};
  end {with DMGS};
  if DMGS.bAbort
  then begin
       ExitConvProc(MGERR_CANCEL);
       exit;
  end {Nutzerabbruch};
  FreeExpandedMem;
  {------------- Speicher bis auf DIB freigeben}
  ExitConvProc(0);
  Result := mg_LastError = 0;
end {function LoadThePCX};

end.
