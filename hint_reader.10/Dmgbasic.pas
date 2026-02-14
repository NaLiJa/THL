
unit Dmgbasic;

{===============================================================}
{ Basistypen, -routinen und Variablen der DMGrafik.dll          }
{ Copyright (C) 1991 - 1996 Detlef Meister                      }
{								}
               Interface
{								}
{===============================================================}

uses Windows, SysUtils, Classes;
{$I dmgrafi.pas}

{============================================== öffentliche Typen}

{----------------------------------------------	Bitmap-Header}
const
Bitmap_Type	= $4d42;			{'BM' - lo/hi}
{----------------------------------------------	Longint-Rechenoperationen}
const
MP              = 7;
Multipli        = 1 SHL MP;
MaxSmallInt     = 32767;
{----------------------------------------------	IO-Puffer}
const
cIOBufLen       = 8192 * 2;
Flush_Buffer    = $1ff;
{----------------------------------------------	DIB-Zeile}
type
tBGRColVal      = (Blau, Gruen, Rot);
tBGRColor       = array[tBGRColVal] of byte;
tBGRZeile       = array[0..MaxSmallInt] of tBGRColor;
pBGRZeile       = ^tBGRZeile;
{----------------------------------------------	Struktur für Konverter}
type
pDMGS           = ^tDMGS;
tDMGS           = record
                  {---------------------------- Abbruch und Fehler}
                  bAbort        : bool;
                  rError        : bool;
                  wError        : bool;
                  {---------------------------- Stream}
                  Bildname      : string;
                  StreamOpen    : boolean;
                  Stream        : tStream;
                  rSize         : longint;
                  {---------------------------- LesePuffer}
                  pReadBuf      : pByteArray;
                  rBufLen       : word;
                  rBufOffs      : word;
                  rLaenge       : longint;
                  rOffset       : longint;
                  rGelesen      : longint;
                  {---------------------------- Entpacktes Bild}
                  pWrite        : pChar;
                  wOffset       : longint;
                  wSize         : longint;
                  wLineLength   : longint;
                  {---------------------------- SchreibPuffer}
                  pWriteBuf     : pByteArray;
                  wBufLen       : word;
                  wBufOffs      : word;
                  wLaenge       : longint;
                  {---------------------------- DIB}
                  pBMI          : pBitmapInfo;
                  cBMI          : longint;
                  cDIB          : longint;
                  cDIBLine      : longint;
                  Farben        : word;
                  BPP           : word;
                  Palette       : tRawPalette;
end {record tDMGS};
{----------------------------------------------	Typen für Resize}
type
tIntArray       = array[0..MaxSmallInt] of smallint;
pIntArray       = ^tIntArray;
{----------------------------------------------	Typen für Resample}
type
tGrenz          = (Erster, Letzter);
tPixel          = array[tGrenz] of smallint;
tPixelTab       = array[0..MaxSmallInt] of tPixel;
pPixelTab       = ^tPixelTab;
tRand           = array[tGrenz] of smallint;
tRandTab        = array[0..MaxSmallInt] of tRand;
pRandTab        = ^tRandTab;
{----------------------------------------------	Struktur für Color/Sizing}
type
pDMCoSi         = ^tDMCoSi;
tDMCoSi         = record
                  {---------------------------- QuellDIB}
                  pqBMI       : pBitmapInfo;
                  cqWid       : word;
                  cqHei       : word;
                  {---------------------------- ZielDIB}
                  pzBMI       : pBitmapInfo;
                  czWid       : word;
                  czHei       : word;
                  {---------------------------- Lesepuffer}
                  pqBuf       : pointer;
                  cqLen       : longint;
                  {---------------------------- Schreibpuffer}
                  pzBuf       : pointer;
                  czLen       : longint;
                  {---------------------------- Resizetabellen}
                  xIdx, yIdx  : pIntArray;
                  {---------------------------- Resampletabellen}
                  pyPix, pxPix: pPixelTab;
                  pyRnd, pxRnd: pRandTab;
end {record tDMCoSi};
{----------------------------------------------	Bildformate}
type
tBildFormat     = (tbf_Unknown, tbf_BMP, tbf_JPG, tbf_TGA, tbf_PCX, tbf_GIF);

{==============================================	globale Variablen}

{---------------------------------------------- FehlerHandling}
var
mg_LastError    : word;
{---------------------------------------------- Berechnungen}
rFWF            : word;
{---------------------------------------------- Strukturen}
InMemory        : boolean;
DMGS            : tDMGS;
DMCoSi          : tDMCoSi;
{---------------------------------------------- MultiTasking und Fortschritt}
MulTa           : TFarProc;
ProzFaktor      : single;
{---------------------------------------------- JPEG}
JPEG_Palette    : boolean;
JPEG_GrayScale  : boolean;
JPEG_DitherMode : integer;
JPEG_TwoPass    : boolean;
JPEG_Quality    : integer;


{==============================================	exportierte Basic-Funktionen}
function  mg_GetNumColors(BMI: pBitmapInfo): longint; stdcall;
function  mg_GetPaletteSize(BMI: pBitmapInfo): longint; stdcall;
function  mg_GetDIBSize(cWid, cHei: longint; BPP: word): longint; stdcall;
function  mg_SetupDIB(Palette: pRawPalette; cWid, cHei, cDIB, cBMI: longint;
          BPP: word): pBitmapInfo; stdcall;

{==============================================	öffentliche Hilfsunktionen}
function  GetStreamByte: byte;
procedure SetExpandByte(Pix: smallint);
function  GetPictureStream: boolean;
procedure FreePictureStream;
function  GetBufferMem: boolean;
function  GetExpandedMem: boolean;
procedure FreeExpandedMem;
function  GetResizeTabelle: boolean;
function  GetResampleTabelle: boolean;
function  GetCoSiBuf: boolean;
procedure ExitConvProc(Fehler: word);
procedure ExitCoSiProc(Fehler: word);

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

{==============================================	öffentliche Hilfsfunktionen}

{----------------------------------------------	GetStreamByte}
function GetStreamByte: byte;
var
Proz            : integer;
begin
  with DMGS
  do begin
     Result := 0;
     {---------- Puffer neu füllen}
     if (rBufOffs >= rLaenge)
     then begin
          rLaenge := rSize - rOffset;
          {----- Dateiende}
          if (rLaenge <= 0)
          then begin
               rError := true;
               exit;
          end {Dateiende};
          {----- Puffer neu füllen}
          if (rLaenge > rBufLen) then rLaenge := rBufLen;
          inc(rOffset, rLaenge);
          rGelesen := Stream.Read(pReadBuf^, rLaenge);
          Result := pReadBuf^[0];
          rBufOffs := 1;
          {----- MultiTasking}
          if (MulTa <> nil)
          then begin
               Proz   := Round(rOffset * ProzFaktor);
               bAbort := tMultiTasking(MulTa)(DMG_Expand, Proz);
          end {MultiTasking};
     end {Puffer neu füllen}
     else begin
          Result := pReadBuf^[rBufOffs];
          inc(rBufOffs);
     end {sind noch Daten im Puffer};
  end {with DMGS};
end {function GetStreamByte};
{----------------------------------------------	SetExpandByte}
procedure SetExpandByte(Pix: smallint);
var
Zeiger          : pointer;
begin
  with DMGS
  do begin
     {--------- Puffer muß am Ende geleert werden}
     if (Pix = Flush_Buffer)
     then if (wBufOffs > 0)
     then begin
          if (wOffset + wBufOffs >= wSize) then wBufOffs := wSize - wOffset - 1;
          Zeiger := pWrite + wOffset;
          Move(pWriteBuf^, Zeiger^, wBufOffs);
          exit;
     end {Puffer muß am Ende geleert werden};
     {--------- Puffer voll}
     if (wBufOffs >= wLaenge)
     then begin
          {---- Puffer leeren}
          Zeiger := pWrite + wOffset;
          inc(wOffset, wLaenge);
          Move(pWriteBuf^, Zeiger^, wLaenge);
          {---- neue Länge berechnen}
          wLaenge := wSize - wOffset;
          {---- Expanded-Bild-Ende}
          if (wLaenge <= 0)
          then begin
               wError := true;
               wBufOffs := 0;
               exit;
          end {Expanded-Bild-Ende};
          if (wLaenge > wBufLen) then wLaenge := wBufLen;
          pWriteBuf^[0] := byte(Pix);
          wBufOffs := 1;
     end {Puffer voll}
     {--------- Byte in Puffer schreiben}
     else begin
          pWriteBuf^[wBufOffs] := byte(Pix);
          inc(wBufOffs);
     end {Byte in Puffer schreiben};
  end {with DMGS};
end {procedure SetExpandByte};
{----------------------------------------------	GetPictureStream}
function GetPictureStream: boolean;
const
fmFileOpen      = fmOpenRead OR fmShareDenyWrite;
var
FileStream      : tFileStream;
MemStream       : tMemoryStream;
begin
  try
    with DMGS
    do begin
       StreamOpen := false;
       {-------- MemoryStream}
       if InMemory
       then begin
            MemStream := tMemoryStream.Create;
            MemStream.LoadFromFile(Bildname);
            Stream := MemStream;
       end {MemoryStream}
       {-------- FileStream}
       else begin
            FileStream := tFileStream.Create(Bildname, fmFileOpen);
            Stream := FileStream;
       end;
       rSize := Stream.Size;
       ProzFaktor := 100 / rSize;
       StreamOpen := true;
       Result := true;
    end {DMGS};
  except
    On EFOpenError
    do begin
       Result := false;
       mg_LastError := MGERR_READOPEN;
    end;
  end;
end {function GetPictureStream};
{----------------------------------------------	FreePictureStream}
procedure FreePictureStream;
begin
  with DMGS
  do if StreamOpen
  then begin
       Stream.Free;
       StreamOpen := false;
  end;
end {procedure FreePictureStream};
{----------------------------------------------	GetBufferMem}
function GetBufferMem: boolean;
begin
  with DMGS
  do begin
     {--------- beim ersten Zugriff Pufferlesen erzwingen}
     if (rBufLen < cIOBufLen) then rBufLen := cIOBufLen;
     rBufOffs := rBufLen;
     if (wBufLen < cIOBufLen) then wBufLen := cIOBufLen;
     wLaenge  := wBufLen;
     {--------- Lese- und Schreib-Puffer besorgen}
     try
       GetMem(pReadBuf, rBufLen);
       GetMem(pWriteBuf, wBufLen);
     except
       On EOutOfMemory do mg_LastError := MGERR_NOMEMORY;
     end {keinen Speicher gekriegt}
  end {with DMGS do};
  Result := mg_LastError = 0;
end {function GetBufferMem};
{----------------------------------------------	FreeBufferMem}
procedure FreeBufferMem;
begin
  with DMGS
  do begin
     {--------- Lese-Puffer löschen}
     if (pReadBuf <> nil)
     then begin
          FreeMem(pReadBuf);
          pReadBuf := nil;
     end {Lese-Puffer löschen};
     {--------- Schreib-Puffer löschen}
     if (pWriteBuf <> nil)
     then begin
          FreeMem(pWriteBuf);
          pWriteBuf := nil;
     end {Schreib-Puffer löschen};
  end {with DMGS};
end {procedure FreeBufferMem};
{----------------------------------------------	GetExpandedMem}
function GetExpandedMem: boolean;
begin
  with DMGS
  {------------- Speicher besorgen}
  do try
     GetMem(pWrite, wSize);
  except
    On EOutOfMemory do mg_LastError := MGERR_NOMEMORY;
  end {keinen Speicher gekriegt};
  Result := mg_LastError = 0;
end {function GetExpandedMem};
{----------------------------------------------	FreeExpandedMem}
procedure FreeExpandedMem;
begin
  with DMGS
  do if (pWrite <> nil)
  then begin
       FreeMem(pWrite);
       pWrite := nil;
  end;
end {procedure FreeExpandedMem};
{----------------------------------------------	GetResizeTabelle}
function  GetResizeTabelle: boolean;
var
Faktor          : single;
Index           : smallint;
begin
  with DMCoSi
  do try
     {---------- Breiten- und HöhenSpeicher holen}
     GetMem(xIdx, sizeof(smallint) * czWid);
     GetMem(yIdx, sizeof(smallint) * czHei);
     {---------- Faktor Breite berechnen und BreitenSpeicher füllen}
     Faktor := czWid / cqWid;
     for Index := 0 to czWid - 1 do xIdx^[Index] := round(Index / Faktor);
     {---------- Faktor Höhe berechnen und HöhenSpeicher füllen}
     Faktor := czHei / cqHei;
     for Index := 0 to czHei - 1 do yIdx^[Index] := round(Index / Faktor);
  except
    On EOutOfMemory do mg_LastError := MGERR_NOMEMORY;
  end {keinen Speicher gekriegt};
  Result := mg_LastError = 0;
end {function GetResizeTabelle};
{----------------------------------------------	FreeResizeTabelle}
procedure FreeResizeTabelle;
begin
  with DMCoSi
  do begin
     {---------- BreitenSpeicher freigeben}
     if (xIdx <> nil)
     then begin
          FreeMem(xIdx);
          xIdx := nil;
     end;
     {---------- HöhenSpeicher freigeben}
     if (yIdx <> nil)
     then begin
          Freemem(yIdx);
          yIdx := nil;
     end;
  end {with DMCoSi};
end {procedure FreeResizeTabelle};
{----------------------------------------------	GetResampleTabelle}
function  GetResampleTabelle: boolean;
var
rSFy, rSFx      : single;
rEQP, rLQP      : single;
Fak1, Fak2      : single;
Hilfe           : single;
iEQP, iLQP      : smallint;
Index           : smallint;
begin
  with DMCoSi
  do try
     {---------- Höhen- und BreitenSpeicher holen}
     GetMem(pyPix, sizeof(tPixel) * czHei);
     GetMem(pxPix, sizeof(tPixel) * czWid);
     {---------- vertikalen und horizontalen RandSpeicher holen}
     GetMem(pyRnd, sizeof(tRand) * czHei);
     GetMem(pxRnd, sizeof(tRand) * czWid);
     {---------- Faktoren berechnen}
     rSFy := cqHei / czHei;
     rSFx := cqWid / czWid;
     rFWF := round(rSFY * rSFx * Multipli);
     {---------- y-Tabellen füllen}
     for index := 0 to czHei - 1
     do begin
        {------- Erster und letzter Quellpixel real}
        rEQP := rSFy * index;
        rLQP := rSFy * (index + 1);
        {------- Erster und letzter Quellpixel smallint}
        iEQP := trunc(rEQP);
        iLQP := trunc(rLQP);
        if (iLQP >= rLQP) then dec(iLQP);
        {------- unterer und oberer Rand}
        if (cqHei > czHei)
        then begin
             {-- SampleDown}
             Fak1 := 1 + iEQP - rEQP;
             Fak2 := rLQP - iLQP;
        end
        else begin
             {-- SampleUp}
             Hilfe := iLQP / rSFy;
             Fak1  := Hilfe - index;
             Fak2  := index + 1 - Hilfe;
        end;
        {------- Tabellen füllen}
        pyPix^[index, Erster]  := iEQP;
        pyPix^[index, Letzter] := iLQP;
        pyRnd^[index, Erster]  := round(Fak1 * Multipli);
        pyRnd^[index, Letzter] := round(Fak2 * Multipli);
     end {y-Tabellen füllen};
     {---------- x-Tabellen füllen}
     for index := 0 to czWid - 1
     do begin
        {------- Erster und letzter Quellpixel real}
        rEQP := rSFx * index;
        rLQP := rSFx * (index + 1);
        {------- Erster und letzter Quellpixel smallint}
        iEQP := trunc(rEQP);
        iLQP := trunc(rLQP);
        if (iLQP >= rLQP) then dec(iLQP);
        {------- linker und rechter Rand}
        if (cqWid > czWid)
        then begin
             {-- SampleDown}
             Fak1 := 1 + iEQP - rEQP;
             Fak2 := rLQP - iLQP;
        end
        else begin
             {-- SampleUp}
             Hilfe := iLQP / rSFx;
             Fak1  := Hilfe - index;
             Fak2  := index + 1 - Hilfe;
        end;
        {------- Tabellen füllen}
        pxPix^[index, Erster]  := iEQP;
        pxPix^[index, Letzter] := iLQP;
        pxRnd^[index, Erster]  := round(Fak1 * Multipli);
        pxRnd^[index, Letzter] := round(Fak2 * Multipli);
     end {x-Tabellen füllen};
  except
    On EOutOfMemory do mg_LastError := MGERR_NOMEMORY;
  end {keinen Speicher gekriegt};
  Result := mg_LastError = 0;
end {function GetResampleTabelle};
{----------------------------------------------	FreeResampleTabelle}
procedure FreeResampleTabelle;
begin
  with DMCoSi
  do begin
     {---------- HöhenSpeicher freigeben}
     if (pyPix <> nil)
     then begin
          FreeMem(pyPix);
          pyPix := nil;
     end;
     {---------- BreitenSpeicher freigeben}
     if (pxPix <> nil)
     then begin
          FreeMem(pxPix);
          pxPix := nil;
     end;
     {---------- vertikalen RandSpeicher freigeben}
     if (pyRnd <> nil)
     then begin
          FreeMem(pyRnd);
          pyRnd := nil;
     end;
     {---------- horizontalen RandSpeicher freigeben}
     if (pxRnd <> nil)
     then begin
          FreeMem(pxRnd);
          pxRnd := nil;
     end;
  end {with DMCoSi};
end {procedure FreeResampleTabelle};
{----------------------------------------------	GetCoSiBuf}
function GetCoSiBuf: boolean;
begin
  with DMCoSi
  do try
     {--------- Lese- und Schreib-Puffer besorgen}
     Getmem(pqBuf, cqLen + 1);
     GetMem(pzBuf, czLen + 1);
  except
    On EOutOfMemory do mg_LastError := MGERR_NOMEMORY;
  end {keinen Speicher gekriegt};
  Result := mg_LastError = 0;
end {function GetCoSiBuf};
{----------------------------------------------	FreeCoSiBuf}
procedure FreeCoSiBuf;
begin
  with DMCoSi
  do begin
     {--------- Lese-Puffer löschen}
     if (pqBuf <> nil)
     then begin
          FreeMem(pqBuf);
          pqBuf := nil;
     end {Lese-Puffer löschen};
     {--------- Schreib-Puffer löschen}
     if (pzBuf <> nil)
     then begin
          Freemem(pzBuf);
          pzBuf := nil;
     end {Schreib-Puffer löschen};
  end {with DMGS};
end {procedure FreeCoSiBuf};
{----------------------------------------------	ExitConvProc}
procedure ExitConvProc(Fehler: word);
begin
  {------------	gegebenenfalls Original-Bild-Speicher freigeben}
  FreePictureStream;
  {------------	gegebenenfalls Expanded-Bild-Speicher freigeben}
  FreeExpandedMem;
  {------------	gegebenenfalls Lese-Schreib-Puffer freigeben}
  FreeBufferMem;
  {------------	gegebenenfalls DIB-Speicher freigeben}
  with DMGS
  do if (pBMI <> nil) AND (Fehler <> 0)
  then begin
       FreeMem(pBMI);
       pBMI := nil;
  end {DIB-Speicher bei Fehler freigeben};
  mg_LastError := Fehler;
end {procedure ExitConvProc};
{----------------------------------------------	ExitCoSiProc}
procedure ExitCoSiProc(Fehler: word);
begin
  {------------	gegebenenfalls ZwischenSpeicher freigeben}
  FreeCoSiBuf;
  {------------	gegebenenfalls TabellenSpeicher freigeben}
  FreeResizeTabelle;
  FreeResampleTabelle;
  {------------- bei Fehler Ziel-DIB-Speicher freigeben}
  with DMCoSi
  do if (pzBMI <> nil) AND (Fehler <> 0)
  then begin
       FreeMem(pzBMI);
       pzBMI := nil;
  end {gegebenenfalls Ziel-DIB-Speicher freigeben};
  mg_LastError := Fehler;
end {procedure ExitCoSiProc};

{==============================================	exportierte Basic-Funktionen}

{----------------------------------------------	mg_GetNumColors}
function mg_GetNumColors(BMI: pBitmapInfo): longint;
var
Farben		: longint;
begin
  with BMI^.bmiHeader do Farben := 1 SHL (biBitCount * biPlanes);
  Result := Farben AND $1ff;
end {function mg_GetNumColors};
{----------------------------------------------	mg_GetPaletteSize}
function mg_GetPaletteSize(BMI: pBitmapInfo): longint;
begin
  Result := mg_GetNumColors(BMI) * sizeof(TRGBQuad);
end {function mg_GetPaletteSize};
{----------------------------------------------	mg_GetDIBSize}
function mg_GetDIBSize(cWid, cHei: longint; BPP: word): longint;
var
Breite          : longint;
begin
  case BPP of
       1            : Breite := 4 * ((cWid + 31) DIV 32);
       2, 4         : Breite := 4 * ((cWid + 7)  DIV 8);
       8            : Breite := 4 * ((cWid + 3)  DIV 4);
       15, 16, 24   : Breite := 4 * ((3 * cWid + 3) DIV 4);
       else           Breite := 0;
  end {case BPP};
  Result := Breite * cHei;
end {function mg_GetDIBSize};
{----------------------------------------------	mg_SetupDIB}
function mg_SetupDIB(Palette: pRawPalette; cWid, cHei, cDIB, cBMI: longint;
         BPP: word): pBitmapInfo;
var
i, Farben       : longint;
pBMI            : pBitmapInfo;
begin
  {------------ DIB-Speicher besorgen}
  try
    GetMem(pBMI, cBMI + cDIB);
    fillchar(pBMI^, cBMI + cDIB, #0);
    Result := pBMI;
    {----------- BitmapInfoHeader initialisieren}
    with pBMI^.bmiHeader
    do begin
       biSize        := sizeof(tBitmapInfoHeader);
       biWidth       := cWid;
       biHeight      := cHei;
       biPlanes      := 1;
       biBitCount    := BPP;
       biCompression := BI_RGB;
       biSizeImage   := cDIB;
       Farben        := (1 SHL BPP) AND $1ff;
       biClrUsed     := Farben;
    end;
    {----------- Farbtabelle initialisieren}
    {$R-}
    if (BPP <= 8) AND (Palette <> nil)
    then for i := 0 to Farben - 1
    do with pBMI^.bmiColors[i]
    do begin
       rgbRed      := Palette^[i, Red];
       rgbGreen    := Palette^[i, Green];
       rgbBlue     := Palette^[i, Blue];
       rgbReserved := 0;
    end {Farbtabelle initialisieren};
    {$R+}
  except
    On EOutOfMemory
    do begin
       mg_LastError := MGERR_NOMEMORY;
       Result := nil;
    end;
  end {keinen Speicher gekriegt};
end {function mg_SetupDIB};

end.
