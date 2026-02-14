
unit Dmgsize;

{===============================================================}
{ Größenkonvertierungen der DMGrafik.dll                        }
{ Copyright (C) 1991 - 1996 Detlef Meister                      }
{								}
               Interface
{								}
{===============================================================}

uses Windows;

{==============================================	exportierte Sizing-Funktionen}
function mg_TrueColorSizeDown(pBMI: pBitmapInfo; Wid, Hei: longint)
         : pBitmapInfo; stdcall;
function mg_TrueColorSizeUp(pBMI: pBitmapInfo; Wid, Hei: longint)
         : pBitmapInfo; stdcall;
function mg_ResizePicture(pBMI: pBitmapInfo; Wid, Hei: longint)
         : pBitmapInfo; stdcall;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses DMGBasic, SysUtils;

{==============================================	private Sizing-Funktionen}

{----------------------------------------------	ResamplePicture}
{ in DMCoSi.hqDIB  : die original Bitmap                       }
{ in DMCoSi.czWid und DMCoSi.czHei : Ziel-Breite und -Höhe     }
{ in DMCoSi.cqWid und DMCoSi.cqHei : Quell-Breite und -Höhe    }
{ SizeDown         : true, sonst SizeUp                        }
{ Ergebnis-DIB     : DMCoSi.pzBMI                              }
function ResamplePicture(SizeDown: bool): boolean;
var
{-------------- Quelle}
cqBMI           : longint;
cqOffs          : longint;                        {Offset Quellfeld}
{-------------- Ziel}
czBMI           : longint;
czDIB           : longint;
czOffs          : longint;			{Offset Zielfeld}
BPP             : longint;
{-------------- Hilfsvariablen}
qPtr, zPtr      : pByte;
pQ, pZ          : pBGRZeile;
y, x, yp, xp    : integer;
yStart, yEnde   : integer;
xStart, xEnde   : integer;
Proz            : longint;
SumB, SumG, SumR: longint;
rEHy, rLHy      : longint;
rEHx, rLHx      : longint;
begin
  {------------- StartInitialisierungen}
  Result := false;
  with DMCoSi
  do begin
     {---------- Quellbildwerte ermitteln}
     with pqBMI^.bmiHeader
     do begin
        {------- Quelle muß TrueColor sein}
        if (biBitCount <= 8)                    {kein TrueColor}
        then begin
             ExitCoSiProc(MGERR_NOTRUECOL);
             exit;
        end {kein TrueColor-Bild};
        {------- Daten Quelle ermitteln}
        cqBMI := sizeof(tBitmapInfoHeader);
        BPP   := biBitCount;
        cqLen := mg_GetDIBSize(biWidth, biHeight, biBitCount) DIV biHeight;
     end;
     {---------- weitere Zielbildwerte festlegen und Speicher holen}
     czDIB := mg_GetDIBSize(czWid, czHei, BPP);
     czLen := czDIB DIV czHei;
     czBMI := cqBMI;
     pzBMI := mg_SetupDIB(nil, czWid, czHei, czDIB, czBMI, BPP);
     if (pzBMI = nil)
     then begin
          ExitCoSiProc(MGERR_NOMEMORY);
          exit;
     end {kein ZielDIB gekriegt};
     {---------- Speicher für Umrechnungstabellen holen}
     if not(GetResampleTabelle)
     then begin
          ExitCoSiProc(mg_LastError);
          exit;
     end;
     {---------- Speicher für die Puffer holen}
     if not(GetCoSiBuf)
     then begin
          ExitCoSiProc(mg_LastError);
          exit;
     end {Speicher nicht fixiert};
     {---------- Startinitialisierungen}
     ProzFaktor := 100 / czHei;
     dec(czHei);
     czOffs := czBMI;
     pQ := pBGRZeile(pqBuf);
     pZ := pBGRZeile(pzBuf);
     SumB := 0;
     SumG := 0;
     SumR := 0;
     {---------- alle Zielzeilen bearbeiten}
     for y := 0 to czHei
     do begin
        {------- Startinitialisierungen für y-Schleife}
        yStart := pyPix^[y, Erster];
        yEnde  := pyPix^[y, Letzter];
        rEHy   := pyRnd^[y, Erster];
        rLHy   := pyRnd^[y, Letzter];
        cqOffs := cqBMI + yStart * cqLen;
        fillchar(pZ^, czLen, #0);
        {------- alle Quellzeilen für den Zielpixel abarbeiten}
        for yp := yStart to yEnde
        do begin
           {---- Quellzeile in Puffer kopieren}
           qPtr := pointer(pChar(pqBMI) + cqOffs);
           inc(cqOffs, cqLen);
           Move(qPtr^, pqBuf^, cqLen);
           {---- alle Zielspalten abarbeiten}
           for x := 0 to czWid - 1
           do begin
              {- Startinitialisierungen für x-Schleife}
              xStart := pxPix^[x, Erster];
              xEnde  := pxPix^[x, Letzter];
              rEHx   := pxRnd^[x, Erster];
              rLHx   := pxRnd^[x, Letzter];
              {- alle Quellspalten für den Zielpixel abarbeiten}
              for xp := xStart to xEnde
              do begin
                 case SizeDown of
                      { Bild verkleinern}
                      true:
                      begin
                        SumB := (pQ^[xp, Blau]  SHL MP) DIV rFWF;
                        SumG := (pQ^[xp, Gruen] SHL MP) DIV rFWF;
                        SumR := (pQ^[xp, Rot]   SHL MP) DIV rFWF;
                        { gegebenenfalls linken Rand wichten}
                        if (xp = xStart)
                        then begin
                             SumB := (rEHx * SumB) SHR MP;
                             SumG := (rEHx * SumG) SHR MP;
                             SumR := (rEHx * SumR) SHR MP;
                        end {gegebenenfalls linken Rand wichten}
                        { gegebenenfalls rechten Rand wichten}
                        else if (xp = xEnde)
                        then begin
                             SumB := (rLHx * SumB) SHR MP;
                             SumG := (rLHx * SumG) SHR MP;
                             SumR := (rLHx * SumR) SHR MP;
                        end {gegebenenfalls rechten Rand wichten};
                        { gegebenenfalls unteren Rand wichten}
                        if (yp = yStart)
                        then begin
                             SumB := (rEHy * SumB) SHR MP;
                             SumG := (rEHy * SumG) SHR MP;
                             SumR := (rEHy * SumR) SHR MP;
                        end {gegebenenfalls linken Rand wichten}
                        { gegebenenfalls oberen Rand wichten}
                        else if (yp = yEnde)
                        then begin
                             SumB := (rLHy * SumB) SHR MP;
                             SumG := (rLHy * SumG) SHR MP;
                             SumR := (rLHy * SumR) SHR MP;
                        end {gegebenenfalls oberen Rand wichten};
                      end {Bild verkleinern};
                      { Bild vergrößern}
                      false:
                      begin
                        SumB := pQ^[xp, Blau];
                        SumG := pQ^[xp, Gruen];
                        SumR := pQ^[xp, Rot];
                        { gibt es einen linken/rechten Randstreifen?}
                        if (xStart <> xEnde)
                        then begin
                             { gegebenenfalls linken Rand wichten}
                             if (xp = xStart)
                             then begin
                                  SumB := (SumB * rEHx) SHR MP;
                                  SumG := (SumG * rEHx) SHR MP;
                                  SumR := (SumR * rEHx) SHR MP;
                             end {gegebenenfalls linken Rand wichten}
                             { gegebenenfalls rechten Rand wichten}
                             else if (xp = xEnde)
                             then begin
                                  SumB := (SumB * rLHx) SHR MP;
                                  SumG := (SumG * rLHx) SHR MP;
                                  SumR := (SumR * rLHx) SHR MP;
                             end {gegebenenfalls rechten Rand wichten};
                        end {gibt es einen linken/rechten Randstreifen?};
                        { gibt es unteren/oberen Randstreifen?}
                        if (yStart <> yEnde)
                        then begin
                             { gegebenenfalls unteren Rand wichten}
                             if (yp = yStart)
                             then begin
                                  SumB := (SumB * rEHy) SHR MP;
                                  SumG := (SumG * rEHy) SHR MP;
                                  SumR := (SumR * rEHy) SHR MP;
                             end {gegebenenfalls linken Rand wichten}
                             { gegebenenfalls oberen Rand wichten}
                             else if (yp = yEnde)
                             then begin
                                  SumB := (SumB * rLHy) SHR MP;
                                  SumG := (SumG * rLHy) SHR MP;
                                  SumR := (SumR * rLHy) SHR MP;
                             end {gegebenenfalls oberen Rand wichten};
                        end {gibt es unteren/oberen Randstreifen?};
                      end {Bild vergrößern};
                 end {case SizeDown};
                 { Pixel aufsummieren}
                 pZ^[x, Blau]  := pZ^[x, Blau]  + SumB;
                 pZ^[x, Gruen] := pZ^[x, Gruen] + SumG;
                 pZ^[x, Rot]   := pZ^[x, Rot]   + SumR;
              end {alle Quellspalten für den Zielpixel abarbeiten};
           end {alle Zielspalten abarbeiten};
        end {alle Quellzeilen für den Zielpixel abarbeiten};
        {------- bearbeitete Zeile ins DIB kopieren}
        zPtr := pointer(pChar(pzBMI) + czOffs);
        inc(czOffs, czLen);
        Move(pzBuf^, zPtr^, czLen);
        {------- MultiTasking}
        if (MulTa <> nil)
        then begin
             Proz := round(y * ProzFaktor);
             if TMultiTasking(MulTa)(DMG_Resize, Proz)
             then begin
                  ExitCoSiProc(MGERR_CANCEL);
                  exit;
             end {Nutzerabbruch};
        end {MultiTasking};
     end {alle Zielzeilen bearbeiten};
  end {with DMCoSi};
  {------------- Werte übergeben}
  ExitCoSiProc(0);
  Result := mg_LastError = 0;
end {function ResamplePicture};

{==============================================	Exportierte Sizing-Funktionen}

{----------------------------------------------	mg_TrueColorSizeDown}
{ in pBMI        : die original Bitmap                              }
{ in Hei, Wid    : die Ziel-Höhe und -Breite                        }
{ Ergebnis-DIB   : Result                                           }
function mg_TrueColorSizeDown(pBMI: pBitmapInfo; Wid, Hei: longint): pBitmapInfo;
begin
  {------------- Startinitialisierungen}
  Result := nil;
  mg_LastError := 0;
  if (pBMI = nil) then exit;                    {kein Bild da ???}
  fillchar(DMCoSi, sizeof(tDMCoSi), #0);
  with DMCoSi
  do begin
     pqBMI := pBMI;
     czWid := Wid;
     czHei := Hei;
     {------------- Plausibilitätscheck}
     cqWid := pBMI^.bmiHeader.biWidth;
     cqHei := pBMI^.bmiHeader.biHeight;
     if (cqWid <= czWid) OR (cqHei <= czWid)
     then mg_LastError := MGERR_NOTLOWER
     else if ResamplePicture(true) then Result := pzBMI;
  end {with DMCoSi};
end {function mg_TrueColorSizeDown};
{----------------------------------------------	mg_TrueColorSizeUp}
{ in pBMI        : die original Bitmap                            }
{ in Hei, Wid    : die Ziel-Höhe und -Breite                      }
{ Ergebnis-DIB   : Result                                         }
function mg_TrueColorSizeUp(pBMI: pBitmapInfo; Wid, Hei: longint): pBitmapInfo;
begin
  {------------- Startinitialisierungen}
  Result := nil;
  mg_LastError := 0;
  if (pBMI = nil) then exit;                    {kein Bild da ???}
  fillchar(DMCoSi, sizeof(tDMCoSi), #0);
  with DMCoSi
  do begin
     pqBMI := pBMI;
     czWid := Wid;
     czHei := Hei;
     {------------- Plausibilitätscheck}
     cqWid := pBMI^.bmiHeader.biWidth;
     cqHei := pBMI^.bmiHeader.biHeight;
     if (cqWid >= czWid) OR (cqHei >= czHei)
     then mg_LastError := MGERR_NOTHIGHER
     else if ResamplePicture(false) then Result := pzBMI;
  end {with DMCoSi};
end {function mg_TrueColorSizeUp};
{----------------------------------------------	mg_ResizePicture}
{ in pBMI        : die original Bitmap                          }
{ in Hei, Wid    : die Ziel-Höhe und -Breite                    }
{ Ergebnis-DIB   : Result                                       }
function mg_ResizePicture(pBMI: pBitmapInfo; Wid, Hei: longint): pBitmapInfo;
var
{---------------- Quell-DIB}
cqBMI           : longint;
cqOffs          : longint;
{---------------- Ziel-DIB}
czBMI           : longint;
czDIB           : longint;
czOffs          : longint;
BPP             : longint;
{---------------- Hilfsvariablen}
qPtr, zPtr      : pByte;
y, ySrc         : integer;
x, xSrc         : integer;
yp, cQ, cZ      : integer;
PixWid          : word;
Proz            : longint;
cqmask, czmask  : byte;                         {Pixelmasken}
Pixel           : byte;                         {Ergebnis-Pixelmaske}
Maske           : byte;                         {Pixelmasken-Default}
maskq           : byte;                         {Vergleichs-Pixelmaske}
begin
  {------------- StartInitialisierungen}
  Result := nil;
  mg_LastError := 0;
  if (pBMI = nil) then exit;                    {kein Bild da ???}
  fillchar(DMCoSi, sizeof(tDMCoSi), #0);
  with DMCoSi
  do begin
     pqBMI := pBMI;
     czWid := Wid;
     czHei := Hei;
     {---------- Quellbildwerte ermitteln}
     with pqBMI^.bmiHeader
     do begin
        BPP   := biBitCount;
        cqLen := mg_GetDIBSize(biWidth, biHeight, biBitCount) DIV biHeight;
        cqWid := biWidth;
        cqHei := biHeight;
     end;
     if (BPP > 8) AND (BPP < 24) then BPP := 24;
     Maske  := 0;
     PixWid := 0;
     case BPP of
          1  : Maske  := $80;
          2  : Maske  := $c0;
          4  : Maske  := $f0;
          8  : PixWid := 1;
          24 : PixWid := 3;
     end;
     {---------- Speicher für Umrechnungstabellen holen}
     if not(GetResizeTabelle)
     then begin
          ExitCoSiProc(mg_LastError);
          exit;
     end;
     y := mg_GetPaletteSize(pqBMI);
     cqBMI := sizeof(TBitmapInfoHeader) + y;
     {---------- Zielbildwerte festlegen und Speicher holen}
     czDIB := mg_GetDIBSize(czWid, czHei, BPP);
     czLen := czDIB DIV czHei;
     czBMI := cqBMI;
     pzBMI := mg_SetupDIB(nil, czWid, czHei, czDIB, czBMI, BPP);
     if (pzBMI = nil)
     then begin
          ExitCoSiProc(MGERR_NOMEMORY);
          exit;
     end {kein ZielDIB gekriegt};
     {------------- gegebenenfalls Farbtabelle kopieren}
     if (BPP <= 8)
     then begin
          qPtr := pointer(pChar(pqBMI) + sizeof(TBitmapInfoHeader));
          zPtr := pointer(pChar(pzBMI) + sizeof(TBitmapInfoHeader));
          Move(qPtr^, zPtr^, y);
     end;
     {---------- Speicher für die Puffer holen}
     if not(GetCoSiBuf)
     then begin
          ExitCoSiProc(mg_LastError);
          exit;
     end {Speicher nicht fixiert};
     {---------- Startinitialisierungen}
     ProzFaktor := 100 / czHei;
     dec(czWid);
     dec(czHei);
     cqOffs := cqBMI;
     czOffs := czBMI;
     ySrc := yIdx^[0];                          {Start y-Umrechnungstabelle}
     {---------- Bildgröße ändern}
     case BPP of
     
       {-------- 256 und Echtfarben}
       8, 24:
       {-------- alle Zielzeilen bearbeiten}
       for y := 0 to czHei
       do begin
          {----- bei Verkleinern Quellzeilen übergehen}
          while (ySrc <> yIdx^[y])
          do begin
             inc(ySrc);
             inc(cqOffs, cqLen);
          end {bei Verkleinern Quellzeilen übergehen};
          {----- Quellzeile in Puffer kopieren}
          qPtr := pointer(pChar(pqBMI) + cqOffs);
          Move(qPtr^, pqBuf^, cqLen);
          {----- Startinitialisierungen}
          xSrc  := xIdx^[0];                    {Start x-Umrechnungstabelle}
          {--- alle Zielspalten bearbeiten}
          for x := 0 to czWid
          do begin
             {-- bei Verkleinern Quellspalten übergehen}
             while (xSrc <> xIdx^[x]) do inc(xSrc);
             cQ := xSrc * PixWid;
             cZ := x * PixWid;
             for yp := 0 to PixWid - 1
             do begin
                {-- QuellPixel holen und schreiben}
                Pixel := pByteArray(pqBuf)^[cQ + yp];
                pByteArray(pzBuf)^[cZ + yp] := Pixel;
             end;
          end {alle Zielspalten bearbeiten};
          {----- bearbeitete Zeile ins DIB kopieren}
          zPtr := pointer(pChar(pzBMI) + czOffs);
          inc(czOffs, czLen);
          Move(pzBuf^, zPtr^, czLen);
          {----- MultiTasking}
          if (MulTa <> nil)
          then begin
               Proz := round(y * ProzFaktor);
               if TMultiTasking(MulTa)(DMG_Resize, Proz)
               then begin
                    ExitCoSiProc(MGERR_CANCEL);
                    exit;
               end {Nutzerabbruch};
          end {MultiTasking};
       end {256 und Echtfarben};

       {-------- 2, 4 und 16 Farben}
       1, 2, 4:
       {-------- alle Zielzeilen bearbeiten}
       for y := 0 to czHei
       do begin
          {----- bei Verkleinern Quellzeilen übergehen}
          while (ySrc <> yIdx^[y])
          do begin
             inc(ySrc);
             inc(cqOffs, cqLen);
          end {bei Verkleinern Quellzeilen übergehen};
          {----- Quellzeile in Puffer kopieren}
          qPtr := pointer(pChar(pqBMI) + cqOffs);
          Move(qPtr^, pqBuf^, cqLen);
          {----- Startinitialisierungen}
          fillchar(pzBuf^, czLen, #0);          {Zielpuffer erst löschen}
          xSrc   := xIdx^[0];                   {Start x-Umrechnungstabelle}
          cqmask := Maske;                      {Bitmasken initialisieren}
          czmask := Maske;
          cQ     := 0;
          cZ     := 0;
          {----- alle Zielspalten bearbeiten}
          for x := 0 to czWid
          do begin
             {-- bei Verkleinern Quellspalten übergehen}
             while (xSrc <> xIdx^[x])
             do begin
                inc(xSrc);
                cqmask := cqmask SHR BPP;
                if (cqmask = 0)
                then begin
                     cqmask := Maske;
                     inc(cQ);
                end;
             end {bei Verkleinern Quellspalten übergehen};
             {-- QuellPixel holen}
             Pixel := pByteArray(pqBuf)^[cQ] AND cqmask;
             {-- nur gesetzten QuellPixel in Zielpixel schreiben}
             if (Pixel <> 0)
             then begin
                  { Quellpixel in Zielposition schieben}
                  if (cqmask <> czmask)
                  then begin
                       maskq := cqmask;
                       while (maskq <> czmask)
                       do if (maskq <  czmask)
                       then begin
                            Pixel := Pixel SHL BPP;
                            maskq := maskq SHL BPP;
                       end
                       else begin
                            Pixel := Pixel SHR BPP;
                            maskq := maskq SHR BPP;
                       end;
                  end {Quellpixel in Zielposition schieben};
                  Pixel := Pixel OR pByteArray(pzBuf)^[cZ];
                  pByteArray(pzBuf)^[cZ] := Pixel;
             end;
             czmask := czmask SHR BPP;
             if (czmask = 0)
             then begin
                  czmask := Maske;
                  inc(cZ);
             end;
          end {alle Zielspalten bearbeiten};
          {----- bearbeitete Zeile ins DIB kopieren}
          zPtr := pointer(pChar(pzBMI) + czOffs);
          inc(czOffs, czLen);
          Move(pzBuf^, zPtr^, czLen);
          {----- MultiTasking}
          if (MulTa <> nil)
          then begin
               Proz := round(y * ProzFaktor);
               if TMultiTasking(MulTa)(DMG_Resize, Proz)
               then begin
                    ExitCoSiProc(MGERR_CANCEL);
                    exit;
               end {Nutzerabbruch};
          end {MultiTasking};
       end {2, 4 und 16 Farben};
     end {Bildgröße ändern};
  end {with DMCoSi};
  {------------- Werte übergeben}
  ExitCoSiProc(0);
  Result := DMCoSi.pzBMI;
end {function mg_ResizePicture};

end.
