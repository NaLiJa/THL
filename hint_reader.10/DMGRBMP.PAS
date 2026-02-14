
unit DMGrBMP;

{===============================================================}
{ Bitmap-Funktionen DMGrafik.dll                                }
{ Copyright (C) 1991 - 1996 Detlef Meister                      }
{								}
               Interface
{								}
{===============================================================}

{==============================================	Units, Resources, Includes}
uses Windows;

{==============================================	exportierte Bitmap-Funktionen}
function  mg_GetDIBMeasure(pBMI: pBitmapInfo): longint; stdcall;
function  mg_MakeBMPfromDIB(pBMI: pBitmapInfo): hBitmap; stdcall;
function  mg_SaveTheDIB(pBMI: pBitmapInfo; Name: pChar): boolean; stdcall;

{==============================================	öffentliche Hilfsfunktionen}
function LoadTheDIB: boolean;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses DMGBasic, Classes, SysUtils;

{============================================== private Bitmap-Funktionen}

{----------------------------------------------	TestWinDIB}
function TestWinDIB(pBMF: pBitmapFileHeader; pBMI: pBitmapInfo): boolean;
begin
  TestWinDIB := false;
  {------------- erste Zeichen müssen 'BM' sein}
  if (pBMF^.bfType <> Bitmap_Type) then exit;
  if (pBMI^.bmiHeader.biSize <> sizeof(tBitmapInfoHeader))
  then exit
  else TestWinDIB := true;
end {function TestWinDIB};

{============================================== exportierte Bitmap-Funktionen}

{----------------------------------------------	mg_GetDIBMeasure}
function mg_GetDIBMeasure(pBMI: pBitmapInfo): longint;
var
Wert            : LongRec;
begin
  {------------ Werte übergeben}
  if (pBMI <> nil)
  then with pBMI^.bmiHeader
  do begin
     Wert.Lo := biWidth;
     Wert.Hi := biHeight;
     Result := longint(Wert);
  end {with pBMI^.bmiHeader}
  else Result := 0;
end {function mg_GetDIBMeasure};
{----------------------------------------------	mg_MakeBMPfromDIB}
function mg_MakeBMPfromDIB(pBMI: pBitmapInfo): hBitmap;
var
DC              : hDC;
pHilf           : pointer;
Offset          : longint;
begin
  Result := 0;
  {------------	DIB-Speicher verriegeln}
  if (pBMI = nil) then exit;
  {------------- DisplayContext besorgen}
  DC := GetDC(0);
  if (DC <> 0)
  then begin
       {-------- Zeiger auf das BitArray besorgen}
       Offset := sizeof(tBitmapInfoHeader) + mg_GetPaletteSize(pBMI);
       pHilf  := pChar(pBMI) + Offset;
       {-------- Bitmap erzeugen}
       Result := CreateDIBitmap(DC, pBMI^.bmiHeader, cbm_Init,
                 pHilf, pBMI^, dib_RGB_Colors);
       {-------- DisplayContext freigeben}
       ReleaseDC(0, DC);
  end {DisplayContext nicht gekriegt};
end {function mg_MakeBMPfromDIB};
{----------------------------------------------	mg_SaveTheDIB}
function mg_SaveTheDIB(pBMI: pBitmapInfo; Name: pChar): boolean;
const
dmWriteOpen     = fmCreate OR fmShareExclusive;
var
pHilf           : pointer;
Erg, cBMI	: longint;
Laenge          : longint;
Stream		: tFileStream;
BMF		: tBitmapFileHeader;
Buf             : string;
begin
  Result := false;
  if (pBMI = nil) then exit;
  {------------	BitmapFileHeader füllen}
  cBMI :=  sizeof(tBitmapInfoHeader) + mg_GetPaletteSize(pBMI);
  BMF.bfType := Bitmap_Type;
  BMF.bfSize := sizeof(tBitmapFileHeader) + cBMI + pBMI^.bmiHeader.biSizeImage;
  BMF.bfReserved1 := 0;
  BMF.bfReserved2 := 0;
  BMF.bfOffBits := sizeof(tBitmapFileHeader) + cBMI;
  try
    {----------- Bild-Stream erzeugen}
    Buf    := StrPas(Name);
    Stream := tFileStream.Create(Buf, dmWriteOpen);
    {----------- BitmapFileHeader speichern}
    Laenge := sizeof(BMF);
    Erg    := Stream.Write(BMF, Laenge);
    if (Erg <> Laenge)
    then begin
         Stream.Free;
         mg_LastError := MGERR_WRITEERROR;
         exit;
    end {if Stream-Fehler};
    {----------- DIB speichern}
    pHilf  := pBMI;				{Pointer auf DIB-Daten}
    Laenge := cBMI + pBMI^.bmiHeader.biSizeImage;
    Erg    := Stream.Write(pHilf^, Laenge);
    Stream.Free;
    if (Erg <> Laenge)
    then mg_LastError := MGERR_WRITEERROR
    else Result := mg_LastError = 0;
  except
    On EFCreateError do mg_LastError := MGERR_WRITEOPEN;
  end {except};
end {function mg_SaveTheDIB};

{============================================== öffentliche Bitmap-Funktionen}

{----------------------------------------------	LoadTheDIB}
{ Eingang:                                                }
{ in DMGS.Bildname        : DateiName und Pfad            }
{ Ausgang:                                                }
{ in DMGS.pBMI            : das Bild als DIB              }
{ in mg_LastError         : Fehler bei Return = false     }
function LoadTheDIB: boolean;
const
dmReadOpen      = fmOpenRead OR fmShareDenyWrite;
var
pHilf           : pointer;
Laenge          : longint;
Err             : longint;
BMF		: tBitmapFileHeader;
begin
  Result := false;
  with DMGS
  do try
     {----------- BildDatei öffnen}
     Stream := tFileStream.Create(Bildname, dmReadOpen);
     {----------- FileHeader einlesen}
     Laenge := sizeof(tBitmapFileHeader);
     Err    := Stream.Read(BMF, Laenge);
     if (Err <> Laenge)
     then begin
          Stream.Free;
          mg_LastError := MGERR_READERROR;
          exit;
     end {LeseFehler};
     {---------- Speicher für BitmapInfoHeader besorgen}
     Laenge := sizeof(tBitmapInfoHeader);
     GetMem(pBMI, Laenge);
     {---------- BitmapInfoHeader einlesen}
     Laenge := sizeof(tBitmapInfoHeader);
     Err    := Stream.Read(pBMI^, Laenge);
     if (Err <> Laenge)
     then begin
          Stream.Free;
          FreeMem(pBMI);
          mg_LastError := MGERR_READERROR;
          exit;
     end {LeseFehler};
     {---------- Testen, ob Windows3.0-Bitmap}
     if not(TestWinDIB(Addr(BMF), pBMI))
     then begin
          Stream.Free;
          FreeMem(pBMI);
          mg_LastError := MGERR_NOWINBMP;
          exit;
     end {if not(TestWinDIB)};
     {---------- Länge Palette ermitteln - nur den Normalfall!!!}
     Farben := mg_GetPaletteSize(pBMI);
     {---------- Länge DIB ermitteln}
     cDIB := pBMI^.bmiHeader.biSizeImage;
     if (cDIB = 0) then cDIB := BMF.bfSize - BMF.bfOffBits;
     {---------- Gesamtlänge DIB-Speicher ermitteln}
     inc(Laenge, Farben);
     inc(Laenge, cDIB);
     {---------- DIB-Speicher erweitern}
     ReAllocMem(pBMI, Laenge);
     {---------- Zeiger auf Palette einstellen und Palette einlesen}
     {           Dateizeiger steht noch richtig!                   }
     if (Farben > 0)
     then begin
          Laenge := sizeof(tBitmapInfoHeader);
          pHilf  := pChar(pBMI) + Laenge;
          Laenge := Farben;
          Err    := Stream.Read(pHilf^, Laenge);
          if (Err <> Laenge)
          then begin
               Stream.Free;
               FreeMem(pBMI);
               mg_LastError := MGERR_READERROR;
               exit;
          end {Palette nicht geladen};
     end {Palette einlesen};
     {---------- Stream auf Anfang der Pixeldaten stellen}
     Stream.Seek(BMF.bfOffBits, 0);
     {---------- Zeiger auf Pixeldaten einstellen und diese einlesen}
     Laenge := sizeof(tBitmapInfoHeader) + Farben;
     pHilf  := pChar(pBMI) + Laenge;
     Laenge := cDIB;
     Err    := Stream.Read(pHilf^, Laenge);
     Stream.Free;
     if (Err <> Laenge)
     then begin
          FreeMem(pBMI);
          mg_LastError := MGERR_READERROR;
          exit;
     end {Fehler beim Einlesen};
  except
    On EFOpenError do mg_LastError := MGERR_READOPEN;
    On EOutOfMemory
    do begin
       Stream.Free;
       mg_LastError := MGERR_NOMEMORY;
    end;
  end {with DMGS};
  Result := mg_LastError = 0;
end {function LoadTheDIB};

end.
