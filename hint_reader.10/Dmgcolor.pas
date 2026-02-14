
unit Dmgcolor;

{===============================================================}
{ Farbkonvertierungen der DMGrafik.dll                          }
{ Copyright (C) 1991 - 1996 Detlef Meister                      }
{								}
               Interface
{								}
{===============================================================}

uses Windows;

{==============================================	exportierte Color-Funktionen}
function mg_TrueColorToGrey(pBMI: pBitmapInfo): pBitmapInfo; stdcall;
function mg_TrueColorTo256(pBMI: pBitmapInfo): pBitmapInfo; stdcall;
function mg_ExpandToTrueColor(pBMI: pBitmapInfo): pBitmapInfo; stdcall;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses DMGBasic, SysUtils;

{==============================================	Private allgemeine Konstanten}

{----------------------------------------------	Zugriff auf die BMI-Palette}
type
pRGBQArray      = ^tRGBQArray;
tRGBQArray      = array[0..255] of tRGBQuad;

{==============================================	Konstanten TrueColorTo256}

{----------------------------------------------	Farbzuordnungen}
const
RedI            = 0;
GreenI          = 1;
BlueI           = 2;
{----------------------------------------------	feste Vorgabewerte}
const
Bits            = 5;
cBits           = 8 - Bits;
ColorMaxI       = 1 SHL Bits;
cHistogramm     = ColorMaxI * ColorMaxI * ColorMaxI;
{----------------------------------------------	Farbbox}
type
tMean           = array[RedI..BlueI] of single;
tFreqZeile      = array[0..ColorMaxI - 1] of longint;
tFreqArray      = array[RedI..BlueI] of tFreqZeile;
tLowHigh        = array[RedI..BlueI] of integer;
pBox            = ^tBox;
tBox            = record
                  WeiVar : single;
                  mean   : tMean;
                  weight : longint;
                  Freq   : tFreqArray;
                  low    : tLowHigh;
                  high   : tLowHigh;
end {record tBox};
{----------------------------------------------	Farbboxen, Histogramm, RGBMap}
type
pBoxes          = ^tBoxes;
tBoxes          = array[0..255] of tBox;
pHistogramm     = ^tHistogramm;
tHistogramm     = array[0..cHistogramm - 1] of longint;
type
pRGBmap         = ^tRGBmap;
tRGBmap         = array[0..cHistogramm - 1] of byte;

{==============================================	globale Variablen}
var
pHisto          : pHistogramm;
pBoxArr         : pBoxes;
pMap            : pRGBmap;
cHBRPix         : longint;                      {Anzahl aller Pixels}
cHBRCol         : longint;                      {gewünschte Zielfarben}
cHBRqBMI        : longint;
cHBRzBMI        : longint;
cHBROutCol      : longint;                      {tatsächliche Zielfarben}

{==============================================	Funktionen für TrueColorTo256}

{----------------------------------------------	Histogramm}
{ Berechnen des Histogrammes und der projektierten        }
{ Frequenzen im Array der ersten Box                      }
function Histogramm: boolean;
var
qPtr            : pointer;                      {Zeiger ins DIB}
cqOffs          : longint;                      {Offset ins DIB}
pQ              : pBGRZeile;                    {Zeiger Quellzeile Puffer}
h               : integer;                      {Offset ins Histogramm}
Proz            : integer;                      {Fortschritt}
r, g, b         : byte;                         {RGB-Farbanteile}
y, x            : integer;
begin
  {------------- Frequenz-Arrays der ersten Box löschen}
  with pBoxArr^[0]
  do begin
     fillchar(Freq[RedI],   sizeof(tFreqZeile), #0);
     fillchar(Freq[GreenI], sizeof(tFreqZeile), #0);
     fillchar(Freq[BlueI],  sizeof(tFreqZeile), #0);
     {---------- Startinitialisierungen}
     ProzFaktor := 100 / DMCoSi.czHei;
     cqOffs     := cHBRqBMI;
     pQ         := pBGRZeile(DMCoSi.pqBuf);
     {---------- Alle Zeilen der Quelle bearbeiten}
     for y := 0 to DMCoSi.czHei - 1
     do begin
        {------- Quellzeile komplett in Puffer holen}
        qPtr := pChar(DMCoSi.pqBMI) + cqOffs;
        inc(cqOffs, DMCoSi.cqLen);
        Move(qPtr^, DMCoSi.pqBuf^, DMCoSi.cqLen);
        {------- Alle Spalten der Quelle bearbeiten}
        for x := 0 to DMCoSi.czWid - 1
        do begin
           {---- Zähler Rotanteil erhöhen:  Farbanteil auf 5 Bit reduzieren}
           r := pQ^[x, Rot] SHR cBits;
           inc(Freq[RedI, r]);
           {---- Zähler Grünanteil erhöhen: Farbanteil auf 5 Bit reduzieren}
           g := pQ^[x, Gruen] SHR cBits;
           inc(Freq[GreenI, g]);
           {---- Zähler Blauanteil erhöhen: Farbanteil auf 5 Bit reduzieren}
           b := pQ^[x, Blau] SHR cBits;
           inc(Freq[BlueI, b]);
           {---- Offset ins 32768-Farben-Histogramm berechnen}
           h := r SHL Bits;
           h := (h OR g) SHL Bits;
           h := h OR b;
           {---- Farb-Zähler im Histogramm erhöhen}
           inc(pHisto^[h]);
        end {Alle Spalten der Quelle bearbeiten};
        {------- MultiTasking}
        if (MulTa <> nil)
        then begin
             Proz := round(y * ProzFaktor);
             if TMultiTasking(MulTa)(DMG_Histogramm, Proz)
             then begin
                  mg_LastError := MGERR_CANCEL;
                  Result := false;
                  exit;
             end {Nutzerabbruch};
        end {MultiTasking};
     end {Alle Zeilen der Quelle bearbeiten};
  end {with pBoxArr^[0]};
  Result := true;
end {function Histogramm};
{----------------------------------------------	BoxStats}
{ Berechnen der Mean und Weighted Varianz der Box       }
procedure BoxStats(var pn: tBox);
var
mean1, vari1    : single;
hw              : single;                       {Hilfe für Berechnungen}
i, col          : integer;
begin
  {------------- Startinitialisierungen}
  pn.WeiVar := 0.0;
  if (pn.Weight = 0) then exit;
  {------------- alle Farbanteile bearbeiten}
  for col := RedI to BlueI
  do begin
     vari1 := 0.0;
     mean1 := 0.0;
     for i := pn.Low[col] to pn.High[col] - 1
     do begin
        {------- mean1 := mean1 + i * Freq[col, i]}
        hw    := pn.Freq[col, i];
        hw    := hw * i;
        mean1 := mean1 + hw;
        {------- vari1 := vari1 + i * i * Freq[col, i]}
        hw    := hw * i;
        vari1 := vari1 + hw;
     end {for i := pn.Low[col] to pn.High[col] - 1};
     pn.Mean[col] := mean1 / pn.Weight;
     {---------- WeiVar := WeiVar + vari1 - mean[col] * mean[col] * Weight}
     hw := pn.mean[col];
     hw := hw * hw * pn.Weight;
     hw := vari1 - hw;
     pn.WeiVar := pn.WeiVar + hw;
  end {alle Farbanteile bearbeiten};
  {------------- neue Weighted Varianz der Box ermitteln}
  pn.WeiVar := pn.WeiVar / cHBRPix;
end {procedure BoxStats};
{----------------------------------------------	FindCutPoint}
{ Berechnen des optimalen CutPoint der Box pn entlang der   }
{ durch RGB gegebenen Achse. Speichert das Ergebnis des     }
{ Cut in nBox1 und nBox2.                                   }
function FindCutPoint(var pn, nBox1, nBox2: tBox; RGB: byte): boolean;
var
u, v, max       : single;                       {Hilfsfelder}
hw              : single;
OptWei          : longint;                      {neue Weights}
CurWei          : longint;
myfreq          : longint;                      {Farbzähler}
h               : integer;                      {Offset ins Histogramm}
rOff, gOff      : integer;
i, CutPt        : integer;
maxIdx, minIdx  : integer;
l1, l2, h1, h2  : integer;
b, g, r         : byte;
begin
  Result := false;
  {------------- abweisen Differenz von 1}
  if (pn.Low[RGB] + 1 = pn.High[RGB]) then exit;
  {------------- Startinitialisierungen}
  MinIdx := round((pn.Mean[RGB] + pn.Low[RGB]) * 0.5);
  MaxIdx := round((pn.Mean[RGB] + pn.High[RGB]) * 0.5);
  CutPt  := MinIdx;
  OptWei := pn.Weight;
  CurWei := 0;
  {------------- Current Weight ermitteln}
  for i := pn.Low[RGB] to MinIdx - 1 do CurWei := CurWei + longint(pn.Freq[RGB, i]);
  {------------- Startinitialisierungen}
  u := 0.0;
  Max := -1.0;
  for i := MinIdx to MaxIdx
  do begin
     inc(CurWei, pn.Freq[RGB, i]);
     if (CurWei = pn.Weight) then break;       {For-Schleife verlassen}
     {---------- u := u + (i * Freq[RGB, i]) / Weight}
     hw := i;
     hw := (hw * pn.Freq[RGB, i]) / pn.Weight;
     u  := u + hw;
     {---------- v := (CurWei / (Weight - CurWei)) * (mean[RGB] - u)^2}
     hw := pn.Mean[RGB];
     hw := hw - u;
     hw := hw * hw;
     v  := CurWei;
     v  := (v / (pn.Weight - CurWei)) * hw;
     {---------- CutPoint und Optimal Weight suchen}
     if (v > max)
     then begin
          max    := v;
          CutPt  := i;
          OptWei := CurWei;
     end {if (v > max)};
  end {for i := MinIdx to MaxIdx};
  inc(CutPt);
  {------------- die alte Box in zwei neue kopieren}
  Move(pn, nBox1, sizeof(tBox));
  Move(pn, nBox2, sizeof(tBox));
  {------------- Weights für die neuen Boxen ermitteln}
  nBox1.Weight := OptWei;
  nBox2.Weight := nBox2.Weight - OptWei;
  if (nBox1.Weight = 0) OR (nBox2.Weight = 0)
  then begin
       exit;
  end;
  nBox1.High[RGB] := CutPt;
  nBox2.Low[RGB]  := CutPt;
  {------------- Frequenz-Arrays der ersten neuen Box löschen           }
  {              die der zweiten bleiben erhalten und werden subtrahiert}
  fillchar(nBox1.Freq[RedI],   sizeof(tFreqZeile), #0);
  fillchar(nBox1.Freq[GreenI], sizeof(tFreqZeile), #0);
  fillchar(nBox1.Freq[BlueI],  sizeof(tFreqZeile), #0);
  {------------- Rotanteile der Frequenz-Arrays aktualisieren}
  for r := nBox1.Low[RedI] to nBox1.High[RedI] - 1
  do begin
     rOff := r SHL Bits;
     {---------- Grünanteile der Frequenz-Arrays aktualisieren}
     for g := nBox1.Low[GreenI] to nBox1.High[GreenI] - 1
     do begin
        gOff := (rOff OR g) SHL Bits;
        {------- Blauanteile der Frequenz-Arrays aktualisieren}
        for b := nBox1.Low[BlueI] to nBox1.High[BlueI] - 1
        do begin
           {---- Offset ins Histogramm berechnen}
           h := gOff OR b;
           {---- Farbzähler aus dem Histogramm holen}
           myfreq := pHisto^[h];
           if (myfreq <> 0)
           then begin
                { ermitteln der neuen Frequenzen der ersten Box}
                inc(nBox1.Freq[RedI,   r], myfreq);
                inc(nBox1.Freq[GreenI, g], myfreq);
                inc(nBox1.Freq[BlueI,  b], myfreq);
                { ermitteln der neuen Frequenzen der zweiten Box}
                { durch Abziehen von den alten Werten           }
                dec(nBox2.Freq[RedI,   r], myfreq);
                dec(nBox2.Freq[GreenI, g], myfreq);
                dec(nBox2.Freq[BlueI,  b], myfreq);
           end;
        end {Blauanteile der Frequenz-Arrays aktualisieren};
     end {Grünanteile der Frequenz-Arrays aktualisieren};
  end {Rotanteile der Frequenz-Arrays aktualisieren};
  {------------- Boxgröße an die Punktanzahl anpassen - Low und High}
  for r := RedI to BlueI
  do begin
     l1 := ColorMaxI;
     l2 := ColorMaxI;
     h1 := 0;
     h2 := 0;
     for g := 0 to ColorMaxI - 1
     do begin
        if (nBox1.Freq[r, g] <> 0)
        then begin
             if (g < l1) then l1 := g;
             if (g > h1) then h1 := g;
        end {if (nBox1.Freq[r, g] <> 0)};
        if (nBox2.Freq[r, g] <> 0)
        then begin
             if (g < l2) then l2 := g;
             if (g > h2) then h2 := g;
        end {if (nBox1.Freq[r, g] <> 0)};
     end {for g := 0 to ColorMaxI};
     nBox1.Low[r]  := l1;
     nBox2.Low[r]  := l2;
     nBox1.High[r] := h1 + 1;
     nBox2.High[r] := h2 + 1;
  end {Boxgröße an die Punktanzahl anpassen};
  {------------- Neuberechnen der Mean und Weighted Variance der neuen Boxen}
  BoxStats(nBox1);
  BoxStats(nBox2);
  Result := true;
end {function FindCutPoint};
{----------------------------------------------	CutBox}
{ Schneiden der Box, daß zwei daraus entstehen        }
function CutBox(var pn, nBox1: tBox): boolean;
const
Hugo            = 1.7 * 10308;                  {MaxDouble}
var
i               : integer;
TotVar          : array[RedI..BlueI] of double;
nBoxes          : array[RedI..BlueI, 0..1] of tBox;
begin
  {------------- Abweisen bei Null-Werten}
  if (pn.WeiVar = 0.0) OR (pn.Weight = 0)
  then begin
       pn.WeiVar := 0.0;
       Result := false;
       exit;
  end else Result := true;
  {------------- Suchen des optimalen CutPoint entlang der}
  {              roten, grünen und blauen Achse.          }
  for i := RedI to BlueI
  do begin
     if (FindCutPoint(pn, nBoxes[i, 0], nBoxes[i, 1], i))
     then TotVar[i] := nBoxes[i, 0].WeiVar + nBoxes[i, 1].WeiVar
     else TotVar[i] := Hugo;
  end {Suchen des optimalen CutPoint};
  {------------- Finden, welcher der drei CutPoints die totale}
  {              Varianz minimiert: dieser ist der richtige   }
  if  (TotVar[RedI] < Hugo)
  AND (TotVar[RedI] <= TotVar[GreenI])
  AND (TotVar[RedI] <= TotVar[BlueI])
  then begin
       Move((nBoxes[RedI, 0]), pn,    sizeof(tBox));
       Move((nBoxes[RedI, 1]), nBox1, sizeof(tBox));
       exit;
  end
  else if  (TotVar[GreenI] < Hugo)
  AND (TotVar[GreenI] <= TotVar[RedI])
  AND (TotVar[GreenI] <= TotVar[BlueI])
  then begin
       Move((nBoxes[GreenI, 0]), pn,    sizeof(tBox));
       Move((nBoxes[GreenI, 1]), nBox1, sizeof(tBox));
       exit;
  end
  else if  (TotVar[BlueI] < Hugo)
  then begin
       Move((nBoxes[BlueI, 0]), pn,    sizeof(tBox));
       Move((nBoxes[BlueI, 1]), nBox1, sizeof(tBox));
       exit;
  end {Finden des richtigen CutPoint};
  {------------- Keine Box kann an irgendeiner Achse geschnitten werden}
  pn.WeiVar := 0.0;
  Result := false;
end {function CutBox};
{----------------------------------------------	CutBoxes}
{ Alle notwendigen Farb-Boxen erzeugen                  }
function CutBoxes: integer;
var
CurBox, n, i    : integer;
Max             : single;
begin
  {------------- Startinitialisierungen in Box 0}
  with pBoxArr^[0]
  do begin
     Low[RedI]    := 0;
     Low[GreenI]  := 0;
     Low[BlueI]   := 0;
     High[RedI]   := ColorMaxI;
     High[GreenI] := ColorMaxI;
     High[BlueI]  := ColorMaxI;
     Weight       := cHBRPix;
  end;
  {------------- Mean und Weighted Varianz der Box 0 berechnen}
  BoxStats(pBoxArr^[0]);
  {------------- alle Farb-Boxen berechnen}
  CurBox := 1;
  while (CurBox < cHBRCol)
  do begin
     {------------- Suchen der Box mit der größten Varianz - in 'n'}
     n   := CurBox;
     max := 0.0;
     for i := 0 to CurBox - 1
     do with pBoxArr^[i]
     do begin
        if (WeiVar > Max)
        then begin
             Max := WeiVar;
             n   := i;
        end;
     end {Suchen der Box mit der größten Varianz};
     {---------- keine Box geht mehr zu schneiden - while-Schleife verlassen}
     if (n = CurBox) then break;
     {---------- neue Box aus der alten schneiden}
     if (CutBox(pBoxArr^[n], pBoxArr^[CurBox])) then inc(CurBox);
  end {alle Boxen berechnen};
  Result := CurBox;
end {function CutBoxes};
{----------------------------------------------	MakeRGBmap}
function MakeRGBmap: boolean;
var
ProzFaktor      : single;
Proz            : integer;
i, p            : integer;
r, g, b         : integer;
rOff, gOff      : integer;
begin
  ProzFaktor := 100 / cHBROutCol;
  {------------- Remap-Tabelle erstellen}
  for i := 0 to cHBROutCol - 1
  do with pBoxArr^[i]
  do begin
     for r := Low[RedI] to High[RedI] - 1
     do begin
        rOff := r SHL Bits;
        for g := Low[GreenI] to High[GreenI] - 1
        do begin
           gOff := (rOff OR g) SHL Bits;
           for b := Low[BlueI] to High[BlueI] - 1
           do begin
              {- Mapping: 32768 Farben auf 256 abbilden}
              p := gOff OR b;
              pMap^[p] := i;
           end;
        end;
     end;
     {---------- MultiTasking}
     if (MulTa <> nil)
     then begin
          Proz := round(i * ProzFaktor);
          if TMultiTasking(MulTa)(DMG_Remap, Proz)
          then begin
               Result := false;
               exit;
          end {Nutzerabbruch};
     end {MultiTasking};
  end {Remap-Tabelle erstellen};
  Result := true;
end {function MakeRGBmap};
{----------------------------------------------	ChangeTheColors}
function ChangeTheColors: boolean;
var
{-------------- Quell-DIB}
qPtr            : pByte;                        {Zeiger auf 1 Quellpixel}
cqOffs          : longint;
{-------------- Ziel-DIB}
zPtr            : pByte;                        {Zeiger auf 1 Zielpixel}
czOffs          : longint;
{-------------- Hilfsvariablen}
pQ              : pBGRZeile;
Proz            : longint;
b, g, r         : integer;
y, x            : integer;
p               : integer;
begin
  {------------- Startinitialisierungen}
  ProzFaktor := 100 / DMCoSi.czHei;
  cqOffs := cHBRqBMI;
  czOffs := cHBRzBMI;
  pQ := pBGRZeile(DMCoSi.pqBuf);
  {------------- Alle Zeilen des Ziels bearbeiten}
  for y := 0 to DMCoSi.czHei - 1
  do begin
     {---------- Quellzeile in Puffer kopieren}
     qPtr := pointer(pChar(DMCoSi.pqBMI) + cqOffs);
     inc(cqOffs, DMCoSi.cqLen);
     Move(qPtr^, DMCoSi.pqBuf^, DMCoSi.cqLen);
     {---------- Alle Spalten des Ziel bearbeiten}
     for x := 0 to DMCoSi.czWid - 1
     do begin
        {------- Farbanteile auf 5 Bit reduzieren: 32768 Farben}
        r := (pQ^[x, Rot]   AND $f8) SHL (Bits + Bits - cBits);
        g := (pQ^[x, Gruen] AND $f8) SHL (Bits        - cBits);
        b := (pQ^[x, Blau]  AND $f8) SHR                cBits;
        {------- 1 von 256 Farben aus Mapping-Tabelle holen}
        p := r OR g OR b;
        pByteArray(DMCoSi.pzBuf)^[x] := pMap^[p];
     end {Alle Spalten des Ziels bearbeiten};
     {---------- bearbeitete Zeile ins DIB kopieren}
     zPtr := pointer(pChar(DMCoSi.pzBMI) + czOffs);
     inc(czOffs, DMCoSi.czLen);
     Move(DMCoSi.pzBuf^, zPtr^, DMCoSi.czLen);
     {---------- MultiTasking}
     if (MulTa <> nil)
     then begin
          Proz := round(y * ProzFaktor);
          if TMultiTasking(MulTa)(DMG_ChgTo256, Proz)
          then begin
               Result := false;
               exit;
          end {Nutzerabbruch};
     end {MultiTasking};
  end {Alle Zeilen des Ziel bearbeiten};
  Result := true;
end {function ChangeTheColors};
{----------------------------------------------	GetHBRmem}
function GetHBRmem: boolean;
begin
  {------------- Speicher für Histogramm, Farbboxen und pMap holen}
  try
    GetMem(pHisto, sizeof(tHistogramm));
    GetMem(pBoxArr, sizeof(tBoxes));
    GetMem(pMap, sizeof(tRGBmap));
    fillchar(pHisto^, sizeof(tHistogramm), #0);
    fillchar(pBoxArr^, sizeof(tBoxes), #0);
    fillchar(pMap^, sizeof(tRGBmap), #0);
  except
    On EOutOfMemory do mg_LastError := MGERR_NOMEMORY;
  end;
  Result := mg_LastError = 0;
end {function GetHBRmem};
{----------------------------------------------	FreeHBRmem}
procedure FreeHBRmem;
begin
  {------------- Speicher für Histogramm freigeben}
  if (pHisto <> nil)
  then begin
       FreeMem(pHisto);
       pHisto := nil;
  end;
  {------------- Speicher für Farbboxen freigeben}
  if (pBoxArr <> nil)
  then begin
       FreeMem(pBoxArr);
       pBoxArr := nil;
  end;
  {------------- Speicher für pMap freigeben}
  if (pMap <> nil)
  then begin
       FreeMem(pMap);
       pMap := nil;
  end;
end {procedure FreeHBRmem};

{==============================================	Exportierte Color-Funktionen}

{----------------------------------------------	mg_TrueColorTo256}
{ in pBMI        : die original Bitmap                           }
{ Ergebnis-DIB   : Return                                        }
function mg_TrueColorTo256(pBMI: pBitmapInfo): pBitmapInfo;
const
zBPP            = 8;
zFarben         = 1 SHL zBPP;
var
Palette         : pRGBQArray;
czDIB           : longint;
i               : integer;
bErg            : boolean;
begin
  {------------- StartInitialisierungen}
  Result := nil;
  mg_LastError := 0;
  if (pBMI = nil) then exit;                    {kein Bild da ???}
  fillchar(DMCoSi, sizeof(tDMCoSi), #0);
  pHisto  := nil;
  pBoxArr := nil;
  pMap    := nil;
  with DMCoSi
  do begin
     pqBMI := pBMI;
     with pqBMI^.bmiHeader
     do begin
        {------- Quelle muß TrueColor sein}
        if (biBitCount <= 8)                    {kein TrueColor}
        then begin
             ExitCoSiProc(MGERR_NOTRUECOL);
             exit;
        end {kein TrueColor-Bild};
        {------- Daten Quelle ermitteln}
        czWid := biWidth;
        czHei := biHeight;
        cHBRqBMI := sizeof(tBitmapInfoHeader);
        cqLen := mg_GetDIBSize(czWid, czHei, biBitCount) DIV czHei;
     end {with pqBMI^.bmiHeader};
     {---------- Daten Zielbild ermitteln}
     czDIB := mg_GetDIBSize(czWid, czHei, zBPP);
     cHBRzBMI := sizeof(tBitmapInfoHeader) + zFarben * sizeof(TRGBQuad);;
     czLen := czDIB DIV czHei;
     {---------- Speicher Zielbild holen}
     pzBMI := mg_SetupDIB(nil, czWid, czHei, czDIB, cHBRzBMI, zBPP);
     if (pzBMI = nil)
     then begin
          ExitCoSiProc(MGERR_NOMEMORY);
          exit;
     end {keinen Speicher gekriegt};
     {---------- Speicher für die Puffer holen}
     if not(GetCoSiBuf)
     then begin
          ExitCoSiProc(mg_LastError);
          exit;
     end {Speicher nicht fixiert};
     {---------- Speicher für FarbBoxen, Histogramm und pMap holen}
     cHBRPix := czWid;
     cHBRPix := cHBRPix * czHei;
     cHBRCol := zFarben;
     if not(GetHBRmem)
     then begin
          FreeHBRmem;
          ExitCoSiProc(mg_LastError);
          exit;
     end {Abbruch};
     {---------- Histogramm berechnen und erste Box füllen}
     if not(Histogramm)
     then begin
          FreeHBRmem;
          ExitCoSiProc(MGERR_CANCEL);
          exit;
     end {Abbruch};
     {---------- Farbboxen bearbeiten}
     cHBROutCol := CutBoxes;
     {---------- Palette füllen}
     Palette := pRGBQArray(pChar(pzBMI) + sizeof(TBitmapInfoHeader));
     for i := 0 to cHBROutCol - 1
     do with pBoxArr^[i]
     do begin
        Palette^[i].rgbRed   := round(Mean[RedI])   SHL cBits;
        Palette^[i].rgbGreen := round(Mean[GreenI]) SHL cBits;
        Palette^[i].rgbBlue  := round(Mean[BlueI])  SHL cBits;
        Palette^[i].rgbReserved := 0;
     end {Palette füllen};
     {---------- pMap füllen}
     if not(MakeRGBmap)
     then begin
          FreeHBRmem;
          ExitCoSiProc(MGERR_CANCEL);
          exit;
     end {Abbruch};
     {---------- RGB-Image füllen}
     bErg := ChangeTheColors;
     FreeHBRmem;
     if not(bErg)
     then begin
          ExitCoSiProc(MGERR_CANCEL);
          exit;
     end {Abbruch};
  end {with DMCoSi};
  {------------- Werte übergeben}
  ExitCoSiProc(0);
  Result := DMCoSi.pzBMI;
end {function mg_TrueColorTo256};
{----------------------------------------------	mg_TrueColorToGrey}
{ in pBMI        : die original Bitmap                            }
{ Ergebnis-DIB   : Return                                         }
function mg_TrueColorToGrey(pBMI: pBitmapInfo): pBitmapInfo;
var
{-------------- Quelle}
cqBMI           : longint;
cqOffs          : longint;
{-------------- Ziel}
czBMI           : longint;
czDIB           : longint;
czOffs          : longint;
BPP             : longint;
{-------------- Hilfsvariablen}
qPtr            : pByte;                        {Zeiger auf 1 Quellpixel}
zPtr            : pByte;                        {Zeiger auf 1 Zielpixel}
pQ              : pBGRZeile;
y, x            : integer;
Proz            : longint;
Farbe           : byte;
b, g, r         : longint;
begin
  {------------- StartInitialisierungen}
  Result := nil;
  mg_LastError := 0;
  if (pBMI = nil) then exit;                    {kein Bild da ???}
  fillchar(DMCoSi, sizeof(tDMCoSi), #0);
  with DMCoSi
  do begin
     pqBMI := pBMI;
     with pqBMI^.bmiHeader
     do begin
        {------- Quelle muß TrueColor sein}
        if (biBitCount <= 8)                    {kein TrueColor}
        then begin
             ExitCoSiProc(MGERR_NOTRUECOL);
             exit;
        end {kein TrueColor-Bild};
        {------- Daten Quelle ermitteln}
        czWid := biWidth;
        czHei := biHeight;
        BPP   := biBitCount;
        cqBMI := sizeof(tBitmapInfoHeader);
        cqLen := mg_GetDIBSize(czWid, czHei, BPP) DIV czHei;
     end {with pqBMI^.bmiHeader};
     {---------- Daten Zielbild ermitteln}
     BPP   := 8;
     czDIB := mg_GetDIBSize(czWid, czHei, BPP);
     czBMI := sizeof(tBitmapInfoHeader) + 256 * sizeof(TRGBQuad);;
     czLen := czDIB DIV czHei;
     {---------- Speicher Zielbild holen}
     pzBMI := mg_SetupDIB(nil, czWid, czHei, czDIB, czBMI, BPP);
     if (pzBMI = nil)
     then begin
          ExitCoSiProc(MGERR_NOMEMORY);
          exit;
     end {keinen Speicher gekriegt};
     {---------- Speicher für die Puffer holen}
     if not(GetCoSiBuf)
     then begin
          ExitCoSiProc(mg_LastError);
          exit;
     end {Speicher nicht fixiert};
     {---------- Graustufenpalette erzeugen}
     for y := 0 to 255
     do with pzBMI^.bmiColors[y]
     do begin
        rgbRed   := y;
        rgbGreen := y;
        rgbBlue  := y;
        rgbReserved := 0;
     end {Graustufenpalette erzeugen};
     {---------- Alle Zeilen des Ziels bearbeiten}
     ProzFaktor := 100 / czHei;
     dec(czHei);
     dec(czWid);
     cqOffs := cqBMI;
     czOffs := czBMI;
     pQ := pBGRZeile(pqBuf);
     for y := 0 to czHei
     do begin
        {------- Quellzeile in Puffer kopieren}
        qPtr := pointer(pChar(pqBMI) + cqOffs);
        inc(cqOffs, cqLen);
        Move(qPtr^, pqBuf^, cqLen);
        {------- Alle Spalten des Ziel bearbeiten}
        for x := 0 to czWid
        do begin
           b := pQ^[x, Blau];
           g := pQ^[x, Gruen];
           r := pQ^[x, Rot];
           Farbe := byte((r * 77 + g * 151 + b * 28) SHR 8);
           pByteArray(pzBuf)^[x] := Farbe;
        end {Alle Spalten des Ziels bearbeiten};
        {------- bearbeitete Zeile ins DIB kopieren}
        zPtr := pointer(pChar(pzBMI) + czOffs);
        inc(czOffs, czLen);
        Move(pzBuf^, zPtr^, czLen);
        {------- MultiTasking}
        if (MulTa <> nil)
        then begin
             Proz := round(y * ProzFaktor);
             if TMultiTasking(MulTa)(DMG_ChgToGray, Proz)
             then begin
                  ExitCoSiProc(MGERR_CANCEL);
                  exit;
             end {Nutzerabbruch};
        end {MultiTasking};
     end {Alle Zeilen des Ziel bearbeiten};
  end {with DMCoSi};
  {------------- Werte übergeben}
  ExitCoSiProc(0);
  Result := DMCoSi.pzBMI;
end {function mg_TrueColorToGrey};
{----------------------------------------------	mg_ExpandToTrueColor}
{ in pBMI        : die original Bitmap                              }
{ Ergebnis-DIB   : Return                                           }
function mg_ExpandToTrueColor(pBMI: pBitmapInfo): pBitmapInfo;
var
{---------------- Quell-DIB}
cqBMI           : longint;
cqOffs          : longint;
{---------------- Ziel-DIB}
czBMI           : longint;
czDIB           : longint;
czOffs          : longint;
BPP             : word;
{---------------- Hilfsvariablen}
qPtr            : pByte;                        {Zeiger auf 1 Quellpixel}
zPtr            : pByte;                        {Zeiger auf 1 Zielpixel}
pZ              : pBGRZeile;
Palette         : pRGBQArray;
Proz            : longint;
x, y            : integer;
cqPix           : integer;
Pixel           : byte;                         {Index in Farbtabelle}
Maske           : byte;                         {Default-Pixelmaske}
cqmask, czmask  : byte;                         {Quell- und Zielmaske}
maskq           : byte;                         {Hilfsmaske}
begin
  {------------- StartInitialisierungen}
  Result := nil;
  fillchar(DMCoSi, sizeof(tDMCoSi), #0);
  mg_LastError := 0;
  if (pBMI = nil) then exit;                    {kein Bild da ???}
  with DMCoSi
  do begin
     DMCoSi.pqBMI := pBMI;
     {------------- QuellDIB-Werte besorgen}
     with pqBMI^.bmiHeader
     do begin
        BPP := biBitCount;
        {------- TrueColor abweisen}
        if (BPP > 8)
        then begin
             ExitCoSiProc(MGERR_ISTRUECOL);
             exit;
        end;
        {------- für den Rest Masken setzen}
        Maske  := 0;
        czmask := 0;
        case BPP of
          1 : begin
                Maske  := $80;
                czmask := $01;
              end;
          2 : begin
                Maske  := $c0;
                czmask := $03;
              end;
          4 : begin
                Maske  := $f0;
                czmask := $0f;
              end;
        end {case BPP of};
        czWid   := biWidth;
        czHei   := biHeight;
        cqLen   := mg_GetDIBSize(czWid, czHei, BPP) DIV biHeight;
        cqBMI   := sizeof(TBitmapInfoHeader) + mg_GetPaletteSize(pqBMI);
        Palette := pointer(pChar(pqBMI) + sizeof(TBitmapInfoHeader));
     end {with pqBMI^.bmiHeader};
     {---------- Zielbilddaten festlegen und Speicher holen}
     czBMI := sizeof(TBitmapInfoHeader);
     czDIB := mg_GetDIBSize(czWid, czHei, 24);
     czLen := czDIB DIV czHei;
     pzBMI := mg_SetupDIB(nil, czWid, czHei, czDIB, czBMI, 24);
     if (pzBMI = nil)
     then begin
          ExitCoSiProc(MGERR_NOMEMORY);
          exit;
     end {kein ZielDIB gekriegt};
     {---------- Speicher für die Puffer holen}
     if not(GetCoSiBuf)
     then begin
          ExitCoSiProc(mg_LastError);
          exit;
     end {Speicher nicht fixiert};
     {---------- StartInitialisierungen}
     ProzFaktor := 100 / czHei;
     dec(czWid);
     dec(czHei);
     cqOffs := cqBMI;
     czOffs := czBMI;
     pZ := pBGRZeile(pzBuf);
     {---------- alle Zielzeilen bearbeiten}
     case BPP of

       {-------- 256 Farben}
       8:
       for y := 0 to czHei
       do begin
          {----- Quellzeile in Puffer kopieren}
          qPtr := pointer(pChar(pqBMI) + cqOffs);
          inc(cqOffs, cqLen);
          Move(qPtr^, pqBuf^, cqLen);
          {----- alle Zielspalten bearbeiten}
          for x := 0 to czWid
          do begin
             {-- QuellPixel holen}
             Pixel := pByteArray(pqBuf)^[x];
             {-- mit Farbindex Farbwerte aus Palette holen und in ZielDIB}
             {   Achtung, im DIB folgende Reihenfolge: Blue, Green, Red  }
             pZ^[x, Blau]  := Palette^[Pixel].rgbBlue;
             pZ^[x, Gruen] := Palette^[Pixel].rgbGreen;
             pZ^[x, Rot]   := Palette^[Pixel].rgbRed;
          end {alle Zielspalten bearbeiten};
          {----- bearbeitete Zeile ins DIB kopieren}
          zPtr := pointer(pChar(pzBMI) + czOffs);
          inc(czOffs, czLen);
          Move(pzBuf^, zPtr^, czLen);
          {----- MultiTasking}
          if (MulTa <> nil)
          then begin
               Proz := round(y * ProzFaktor);
               if TMultiTasking(MulTa)(DMG_ExpToTrue, Proz)
               then begin
                    ExitCoSiProc(MGERR_CANCEL);
                    exit;
               end {Nutzerabbruch};
          end {MultiTasking};
       end {256 Farben};

       {-------- 2, 4 und 16 Farben}
       1, 2, 4:
       for y := 0 to czHei
       do begin
          {----- Quellzeile in Puffer kopieren}
          qPtr := pointer(pChar(pqBMI) + cqOffs);
          inc(cqOffs, cqLen);
          Move(qPtr^, pqBuf^, cqLen);
          cqPix  := 0;
          cqmask := Maske;
          {----- alle Zielspalten bearbeiten}
          for x := 0 to czWid
          do begin
             {-- QuellPixel holen}
             Pixel := pByteArray(pqBuf)^[cqPix] AND cqmask;
             {-- QuellPixel in ZielPosition schieben}
             if (Pixel <> 0)
             then if (cqmask <> czmask)
             then begin
                  maskq := cqmask;
                  while (maskq <> czmask)
                  do begin
                     Pixel := Pixel SHR BPP;
                     maskq := maskq SHR BPP;
                  end;
             end {QuellPixel in ZielPosition schieben};
             {-- QuellPixelOffset erhöhen}
             cqmask := cqmask SHR BPP;
             if (cqmask = 0)
             then begin
                  cqmask := Maske;
                  inc(cqPix);
             end {QuellPixelOffset erhöhen};
             {-- mit Farbindex Farbwerte aus Palette holen und in ZielDIB}
             {   Achtung, im DIB folgende Reihenfolge: Blue, Green, Red  }
             pZ^[x, Blau]  := Palette^[Pixel].rgbBlue;
             pZ^[x, Gruen] := Palette^[Pixel].rgbGreen;
             pZ^[x, Rot]   := Palette^[Pixel].rgbRed;
          end {alle Zielspalten bearbeiten};
          {----- bearbeitete Zeile ins DIB kopieren}
          zPtr := pointer(pChar(pzBMI) + czOffs);
          inc(czOffs, czLen);
          Move(pzBuf^, zPtr^, czLen);
          {----- MultiTasking}
          if (MulTa <> nil)
          then begin
               Proz := round(y * ProzFaktor);
               if TMultiTasking(MulTa)(DMG_ExpToTrue, Proz)
               then begin
                    ExitCoSiProc(MGERR_CANCEL);
                    exit;
               end {Nutzerabbruch};
          end {MultiTasking};
       end {2, 4 und 16 Farben};
     end {case BPP of};
  end {with DMCoSi};
  {------------- Werte übergeben}
  ExitCoSiProc(0);
  Result := DMCoSi.pzBMI;
end {function mg_ExpandToTrueColor};

end.
