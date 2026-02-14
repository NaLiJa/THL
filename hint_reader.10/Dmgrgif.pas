
unit Dmgrgif;

{===============================================================}
{ GIF-Bilder-Konverter der DMGrafik.dll                         }
{ Copyright (C) 1991 - 1996 Detlef Meister                      }
{								}
               Interface
{								}
{===============================================================}

uses Windows;

{==============================================	öffentliche GIF-Funktionen}
function LoadTheGIF: Boolean;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses DMGBasic, SysUtils;

{==============================================	lokale Typen und Konstanten}

{----------------------------------------------	Decoder-Konstanten}
const
MaxLZWbits      = 12;
LZWTableSize    = 1 SHL MaxLZWbits;
Mask            : array[1..MaxLZWbits] of smallint
                = ($0001, $0003, $0007, $000F, $001F, $003F,
                   $007F, $00FF, $01FF, $03FF, $07FF, $0FFF);
YInc            : array[1..6] of byte = (8, 8, 4, 2, 1, 0);
Ylin            : array[1..6] of byte = (0, 4, 2, 1, 0, 0);
{----------------------------------------------	GIF Screen Deskriptor}
type
pGIFScrHeader   = ^tGIFScrHeader;
tGIFScrHeader   = packed record
                  ScreenWidth  : word;
                  ScreenHeight : word;
                  Flag         : byte;
                  BackColor    : byte;
                  Aspect       : byte;
end {record tGIFScrHeader};
{----------------------------------------------	GIF Image Deskriptor}
type
pGIFImgHeader   = ^tGIFImgHeader;
tGIFImgHeader   = packed record
                  ImageLeft     : word;
                  ImageTop      : word;
                  ImageWidth    : word;
                  ImageHeight   : word;
                  Flag          : byte;
end {record tGIFImgHeader};
{----------------------------------------------	Decoder-Tabellen}
type
pSymbolHead     = ^tSymbolHead;
tSymbolHead     = array[0..LZWTableSize] of smallint;
pSymbolTail     = ^tSymbolTail;
tSymbolTail     = array[0..LZWTableSize] of byte;
pSymbolStack    = ^tSymbolStack;
tSymbolStack    = array[0..LZWTableSize] of byte;
pCodeBuffer     = ^tCodeBuffer;
tCodeBuffer     = array[0..256 + 4] of byte;

{==============================================	lokale Hilfsfunktionen}

{----------------------------------------------	TestHeader}
function TestHeader: boolean;
var
Buf             : array[0..5] of char;
begin
  with DMGS
  do begin
     Result := false;
     rGelesen := Stream.Read(Buf, 6);
     if (rGelesen <> 6)
     then begin
          mg_LastError := MGERR_READERROR;
          exit;
     end;
     if (StrLComp(Buf, 'GIF', 3) = 0)
     then Result := true
     else mg_LastError := MGERR_WRONGFORM;
     inc(rOffset, 6);
  end {with DMGS};
end {procedure TestHeader};
{----------------------------------------------	GetScrHeader}
function GetScrHeader(GIFScrHeader: pGIFScrHeader): boolean;
var
i               : word;
ColorMap        : boolean;
begin
  with DMGS
  do begin
     Result := false;
     {--------- Screen Descriptor einlesen}
     rGelesen := Stream.Read(GIFScrHeader^, sizeof(tGIFScrHeader));
     if (rGelesen <> sizeof(tGIFScrHeader))
     then begin
          mg_LastError := MGERR_READERROR;
          exit;
     end;
     inc(rOffset, sizeof(tGIFScrHeader));
     with GIFScrHeader^
     do begin
        ColorMap  := (Flag and $80) <> 0;
        BPP       := (Flag AND $7) + 1;
        Farben    := (1 SHL BPP) AND $1ff;
     end {with GIFScrHeader^};
     {--------- globale Farbtabelle einlesen}
     if ColorMap
     then begin
          i := Farben * sizeof(tRGBColor);
          inc(rOffset, i);
          rGelesen := Stream.Read(Palette, i);
          if (rGelesen <> i)
          then begin
               mg_LastError := MGERR_READERROR;
               exit;
          end;
     end {globale Farbtabelle einlesen};
     Result := mg_LastError = 0;
  end {with DMGS};
end {function GetScrHeader};
{----------------------------------------------	GetImgHeader}
function GetImgHeader(GIFImgHeader: pGIFImgHeader): boolean;
var
i               : word;
Col             : smallint;
ColorMap        : boolean;
{---------------------------------------------- SubFunction GetWord}
function GetWord: word;
var
a, b            : byte;
begin
  a := GetStreamByte;
  b := GetStreamByte;
  Result := (b SHL 8) OR a;
end;
{----------------------------------------------	MainFunction GetImgHeader}
begin
  with DMGS
  do begin
     {--------- Image Descriptor einlesen}
     with GIFImgHeader^
     do begin
        ImageLeft   := GetWord;
        ImageTop    := GetWord;
        ImageWidth  := GetWord;
        ImageHeight := GetWord;
        Flag        := GetStreamByte;
        ColorMap    := (Flag and $80) <> 0;
        Col         := 1 SHL BPP;
     end {with GIFImgHeader^};
     {--------- lokale Farbtabelle über die globale einlesen}
     if ColorMap
     then begin
          for i := 0 to Col - 1
          do begin
             Palette[i, Red]   := GetStreamByte;
             Palette[i, Green] := GetStreamByte;
             Palette[i, Blue]  := GetStreamByte;
          end {alle Farben einlesen};
     end {lokale Farbtabelle einlesen};
     if rError
     then begin
          Result := false;
          mg_LastError :=MGERR_READERROR
     end
     else Result := true;
  end {with DMGS};
end {function GetImgHeader};
{----------------------------------------------	SkipBlock}
function SkipBlock: boolean;
var
i               : integer;
Block           : array[0..256] of byte;
begin
  {------------ Länge des ExtendedBlocks einlesen}
  Block[0] := GetStreamByte;
  {------------ ExtendedBlock einlesen}
  with DMGS
  do begin
     if not(rError)
     then if (Block[0] <> 0)
     then for i:= 1 to Block[0] do Block[i] := GetStreamByte;
     if rError
     then Result := false
     else Result := (Block[0] <> 0);
  end {with DMGS};
end {function SkipBlock};
{----------------------------------------------	SkipExtension}
function SkipExtension: boolean;
begin
  {------------ Funktionscode einlesen}
  GetStreamByte;
  {------------ ExtendedBlocks überspringen}
  while SkipBlock do;
  if DMGS.rError
  then begin
       Result := false;
       mg_LastError := MGERR_READERROR;
  end
  else Result := true;
end {function SkipExtension};
{----------------------------------------------	Expand}
function Expand: boolean;
var
CodeBuffer      : pCodeBuffer;
SymbolHead      : pSymbolHead;
SymbolTail      : pSymbolTail;
SymbolStack     : pSymbolStack;
c               : smallint;
LastByte        : smallint;                     {Anzahl Bytes im CodeBuffer}
LastBit         : smallint;                     {Anzahl Bits  im CodeBuffer}
CurrentBit      : smallint;                     {nächstes zu lesendes Bit}
InputCodeSize   : smallint;                     {vorgegebene Code-Bitgröße}
ClearCode       : smallint;
EndCode         : smallint;
CodeSize        : smallint;                     {aktuelle Code-Bitgröße}
LimitCode       : smallint;
MaxCode         : smallint;                     {erster unbenutzter Codewert}
SP              : smallint;                     {SymbolStack Pointer}
OldCode         : smallint;
FirstCode       : smallint;
Code            : smallint;
InCode          : smallint;
FirstTime       : boolean;
OutOfBlocks     : boolean;
{----------------------------------------------	SubProcedures ReInitDecoder}
procedure ReInitDecoder;
begin
  CodeSize  := InputCodeSize + 1;               
  LimitCode := ClearCode SHL 1;
  MaxCode   := ClearCode + 2;
  SP        := 0;
end {procedure ReInitDecoder};
{----------------------------------------------	SubProcedure ReadCode}
function ReadCode: smallint;
var
Accum           : longint;
Offs, i, Count  : smallint;
begin
  {------------ gegebenenfalls Puffer neu laden}
  if ((CurrentBit + CodeSize) > LastBit)
  then begin
       if OutOfBlocks
       then begin
            ReadCode := EndCode;
            exit;
       end {Out of blocks};
       {------- die letzten 2 Bytes nach vorne kopieren...}
       CodeBuffer^[0] := CodeBuffer^[LastByte - 2];
       CodeBuffer^[1] := CodeBuffer^[LastByte - 1];
       {------- ...und den Puffer neu füllen}
       Count := smallint(GetStreamByte);  {Blocklänge holen}
       if DMGS.rError OR (Count = 0)
       then begin
            OutOfBlocks := true;
            ReadCode    := EndCode;
            exit;
       end {Lesefehler};
       for i := 1 to Count do CodeBuffer^[i + 1] := GetStreamByte;
       if DMGS.rError
       then begin
            OutOfBlocks := true;
            ReadCode    := EndCode;
            exit;
       end {Lesefehler};
       {------- Zähler neu setzen}
       CurrentBit := CurrentBit - LastBit + 16;
       LastByte   := 2 + Count;
       LastBit    := LastByte * 8;
  end {Puffer neu laden};
  {------------ die nächsten 24 Bits in Accum bilden}
  Offs       := CurrentBit SHR 3;
  Accum      := CodeBuffer^[Offs + 2];
  Accum      := Accum SHL 8;
  Accum      := Accum OR CodeBuffer^[Offs + 1];
  Accum      := Accum SHL 8;
  Accum      := Accum OR CodeBuffer^[Offs];
  {------------ Aktuelle Bits in Accumnach rechts bringen }
  {             dann ausmaskieren erforderliche Zahl der Bits}
  Accum      := Accum SHR (CurrentBit AND 7);
  ReadCode   := smallint(Accum) AND Mask[CodeSize];
  CurrentBit := CurrentBit + CodeSize;
end {function ReadCode};
{----------------------------------------------	SubProcedure LZWReadByte}
function LZWReadByte: smallint;
begin
  {------------ beim ersten Mal ClearCode zurückliefern}
  if FirstTime
  then begin
       FirstTime := false;
       Code      := ClearCode;
  end {FirstTime}
  {------------ Wenn noch Codes im Stack, diese zurückliefern}
  else begin
       if (SP > 0)
       then begin
            dec(SP);
            LZWReadByte := smallint(SymbolStack^[SP]);
            exit;
       end {noch Codes im Stack};
       {------- neue Codes einlesen}
       Code := ReadCode;
  end {sind noch Codes im Stack};  
  {------------ Decoder muß neu initialisiert werden}
  if (Code = ClearCode)
  then begin
       ReInitDecoder;
       {------- es können mehrere ClearCodes aufeinander folgen} 
       repeat
         Code := ReadCode;
       until (Code <> ClearCode) OR DMGS.rError;
       {------- Lesefehler durch 0 ersetzen}
       if (Code > ClearCode) OR DMGS.rError then Code := 0;
       FirstCode   := Code;
       OldCode     := Code;
       LZWReadByte := Code;
       exit;
  end {Decoder neu initialisieren};
  {------------ Vorzeitiges BlockEnde - bis zum nächsten Terminator überlesen}
  if (Code = EndCode)
  then begin
       if not(OutOfBlocks) then SkipBlock;
       OutOfBlocks := true;
       LZWReadByte := 0;
       exit;
  end {vorzeitiges Block-Ende};
  {------------ RawByte oder Symbol übernehmen}
  InCode := Code;
  {------------ noch nicht definiertes Symbol}
  if (Code >= MaxCode)
  {------------- Fehler! Schleifenbildung verhindern}
  then begin
       if (Code > MaxCode) then InCode := 0;
       SymbolStack^[SP] := byte(FirstCode);
       inc(SP);
       Code := OldCode;
  end {noch nicht definiertes Symbol};
  {------------ wenn es ein Symbol ist, in den Stack packen}
  while (Code >= ClearCode)
  do begin
     SymbolStack^[SP] := SymbolTail^[Code];
     inc(SP);
     Code := SymbolHead^[Code];
  end {Symbol in den Stack packen};
  {------------ jetzt repräsentiert Code endlich ein RawByte}
  FirstCode := Code;
  {------------ noch Platz in der Code-Tabelle?}
  Code := MaxCode;
  if (Code < LZWTableSize)
  then begin
       {------- neues Symbol definieren: prev sym+head of this sym's expansion}
       SymbolHead^[Code] := OldCode;
       SymbolTail^[Code] := byte(FirstCode);
       inc(MaxCode);
       {------- muß CodeSize erhöht werden?}
       if (MaxCode >= LimitCode) AND (CodeSize < MaxLZWbits)
       then begin
            inc(CodeSize);
            LimitCode := LimitCode SHL 1;
       end {CodeSize erhöhen};
  end {noch Platz in Tabelle};
  OldCode := InCode;
  LZWReadByte := FirstCode;
end {function LZWReadByte};
{----------------------------------------------	MainProcedure Expand}
begin
  {------------ Speicher besorgen}
  with DMGS
  do try
     SymbolHead  := New(pSymbolHead);
     SymbolTail  := New(pSymbolTail);
     SymbolStack := New(pSymbolStack);
     CodeBuffer  := New(pCodeBuffer);
     {--------- Start-Initialisierungen}
     FillChar(SymbolHead^,  SizeOf(tSymbolHead),  0);
     FillChar(SymbolTail^,  SizeOf(tSymbolTail),  0);
     FillChar(SymbolStack^, SizeOf(tSymbolStack), 0);
     FillChar(CodeBuffer^,  SizeOf(tCodeBuffer),  0);
     InputCodeSize := word(GetStreamByte);
     if (InputCodeSize  < 2) OR (InputCodeSize >= MaxLZWBits)
     then mg_LastError := MGERR_READERROR
     else begin
          {---- InitDecoder}
          LastByte    := 2;                   {Recopy der letzten 2 Bytes sichern}
          LastBit     := 0;                   {Puffer ist leer}
          CurrentBit  := 0;                   {beim 1.Mal Pufferlesen erzwingen}
          OutOfBlocks := false;
          ClearCode   := 1 SHL InputCodeSize;
          EndCode     := ClearCode + 1;
          FirstTime   := true;
          ReInitDecoder;
          {---- ganzes Image entpacken}
          repeat
            c := LZWReadByte;
            SetExpandByte(c);
          until wError OR rError OR bAbort;
     end {kein Lesefehler bei InputCodeSize};
     {--------- Puffer leeren}
     SetExpandByte(Flush_Buffer);
     if bAbort then mg_LastError := MGERR_CANCEL;
  except
    On EOutOfMemory do mg_LastError := MGERR_NOMEMORY;
  end {keinen Speicher gekriegt};
  if (SymbolHead <> nil)  then Dispose(SymbolHead);
  if (SymbolTail <> nil)  then Dispose(SymbolTail);
  if (SymbolStack <> nil) then Dispose(SymbolStack);
  if (CodeBuffer <> nil)  then Dispose(CodeBuffer);
  Result := mg_LastError = 0;
end {function Expand};
{----------------------------------------------	Repack1}
procedure Repack1(InterLaced: Bool);
var
pGIFv, pDIBv	: pointer;
DIBoffs, DIBend : longint;
Proz            : longint;
Pass, Row       : integer;
i, i2, Cnt      : word;
y, cHei         : word;
b               : byte;
begin
  with DMGS
  do begin
     {--------- Startinitialisierungen}
     wOffset := 0;                              {Anfang entpacktes GIF-Image}
     with pBMI^.bmiHeader
     do begin
        cHei := biHeight - 1;
        DIBend := biSizeImage + cBMI - cDIBline; {Letzte Bildzeile im DIB}
        DIBoffs := DIBend;
     end {with pBMI^.bmiHeader};
     Cnt := (wLineLength - 1) div 8;
     ProzFaktor := 100 / cHei;
     {--------- NonInterlaced}
     if not(InterLaced)
     then for y := 0 to cHei
     do begin
        {------ ganze Quell-Zeile in Puffer kopieren}
        pGIFv := pWrite + wOffset;
        Move(pGIFv^, pWriteBuf^, wLineLength);
        inc(wOffset, wLineLength);
        for i := 0 to Cnt
        do begin
           i2 := i SHL 3;
           b := (pWriteBuf^[i2] AND $01) SHL 7;
           inc(i2);
           b := b OR (pWriteBuf^[i2] AND $01) SHL 6;
           inc(i2);
           b := b OR (pWriteBuf^[i2] AND $01) SHL 5;
           inc(i2);
           b := b OR (pWriteBuf^[i2] AND $01) SHL 4;
           inc(i2);
           b := b OR (pWriteBuf^[i2] AND $01) SHL 3;
           inc(i2);
           b := b OR (pWriteBuf^[i2] AND $01) SHL 2;
           inc(i2);
           b := b OR (pWriteBuf^[i2] AND $01) SHL 1;
           inc(i2);
           b := b OR (pWriteBuf^[i2] AND $01);
           pReadBuf^[i] := b;
        end {eine Zeile konvertieren};
        {------- bearbeitete Quellzeile ins DIB kopieren}
        pDIBv := pChar(pBMI) + DIBoffs;
        Move(pReadBuf^, pDIBv^, cDIBline);
        dec(DIBoffs, cDIBline);
        {------ MultiTasking}
        if (MulTa <> nil)
        then begin
             Proz   := round(y * ProzFaktor);
             bAbort := TMultiTasking(MulTa)(DMG_Repack, Proz);
             if bAbort then exit;
        end {MultiTasking};
     end {kein Interlace}
     {--------- InterLaced}
     else begin
          Pass := 1;
          Row  := 0;
          for y := 0 to cHei
          do begin
             {-- ganze Quell-Zeile in Puffer kopieren}
             pGIFv := pWrite + wOffset;
             Move(pGIFv^, pWriteBuf^, wLineLength);
             inc(wOffset, wLineLength);
             for i := 0 to Cnt
             do begin
                i2 := i SHL 3;
                b  := (pWriteBuf^[i2] AND $01) SHL 7;
                inc(i2);
                b  := b OR (pWriteBuf^[i2] AND $01) SHL 6;
                inc(i2);
                b  := b OR (pWriteBuf^[i2] AND $01) SHL 5;
                inc(i2);
                b  := b OR (pWriteBuf^[i2] AND $01) SHL 4;
                inc(i2);
                b  := b OR (pWriteBuf^[i2] AND $01) SHL 3;
                inc(i2);
                b  := b OR (pWriteBuf^[i2] AND $01) SHL 2;
                inc(i2);
                b  := b OR (pWriteBuf^[i2] AND $01) SHL 1;
                inc(i2);
                b  := b OR (pWriteBuf^[i2] AND $01);
                pReadBuf^[i] := b;
             end {eine Zeile konvertieren};
             {-- bearbeitete Quellzeile interlaced ins DIB kopieren}
             pDIBv := pChar(pBMI) + DIBoffs;
             Move(pReadBuf^, pDIBv^, cDIBline);
             Row := Row + YInc[Pass];
             if (Row > cHei)
             then begin
                  Inc(Pass);
                  Row := YLin[Pass];
                  DIBoffs := DIBend;
                  dec(DIBoffs, cDIBline * longint(Row));
             end {if (Row > cHei)}
             else dec(DIBoffs, cDIBline * longint(YInc[Pass]));
             {-- MultiTasking}
             if (MulTa <> nil)
             then begin
                  Proz   := round(y * ProzFaktor);
                  bAbort := TMultiTasking(MulTa)(DMG_Repack, Proz);
                  if bAbort then exit;
             end {MultiTasking};
          end {alle Zeilen konvertieren};
     end {Interlace}
  end {with DMGS do};
end {procedure Repack1};
{----------------------------------------------	Repack4}
procedure Repack4(InterLaced: Bool);
var
pGIFv, pDIBv	: pointer;
DIBoffs, DIBend : longint;
Proz            : longint;
Pass, Row       : integer;
i, i2, Cnt      : word;
y, cHei         : word;
b               : byte;
begin
  with DMGS
  do begin
     {--------- Startinitialisierungen}
     wOffset := 0;                              {Anfang entpacktes GIF-Image}
     with pBMI^.bmiHeader
     do begin
        cHei := biHeight - 1;
        DIBend := biSizeImage + cBMI - cDIBline; {Letzte Bildzeile im DIB}
        DIBoffs := DIBend;
     end {with pBMI^.bmiHeader};
     Cnt := (wLineLength - 1) div 2;
     ProzFaktor := 100 / cHei;
     {--------- NonInterlaced}
     if not(InterLaced)
     then for y := 0 to cHei
     do begin
        {------ ganze Quell-Zeile in Puffer kopieren}
        pGIFv := pWrite + wOffset;
        Move(pGIFv^, pWriteBuf^, wLineLength);
        inc(wOffset, wLineLength);
        for i := 0 to Cnt
        do begin
           i2 := i SHL 1;
           b  := (pWriteBuf^[i2] AND $0f) SHL 4;
           inc(i2);
           b  := b OR (pWriteBuf^[i2] AND $0f);
           pReadBuf^[i] := b;
        end {eine Zeile konvertieren};
        {------- bearbeitete Quellzeile ins DIB kopieren}
        pDIBv := pChar(pBMI) + DIBoffs;
        Move(pReadBuf^, pDIBv^, cDIBline);
        dec(DIBoffs, cDIBline);
        {------ MultiTasking}
        if (MulTa <> nil)
        then begin
             Proz   := round(y * ProzFaktor);
             bAbort := TMultiTasking(MulTa)(DMG_Repack, Proz);
             if bAbort then exit;
        end {MultiTasking};
     end {kein Interlace}
     {--------- InterLaced}
     else begin
          Pass := 1;
          Row  := 0;
          for y := 0 to cHei
          do begin
             {-- ganze Quell-Zeile in Puffer kopieren}
             pGIFv := pWrite + wOffset;
             Move(pGIFv^, pWriteBuf^, wLineLength);
             inc(wOffset, wLineLength);
             for i := 0 to Cnt
             do begin
                i2 := i SHL 1;
                b  := (pWriteBuf^[i2] AND $0f) SHL 4;
                inc(i2);
                b  := b OR (pWriteBuf^[i2] AND $0f);
                pReadBuf^[i] := b;
             end {eine Zeile konvertieren};
             {-- bearbeitete Quellzeile interlaced ins DIB kopieren}
             pDIBv := pChar(pBMI) + DIBoffs;
             Move(pReadBuf^, pDIBv^, cDIBline);
             Row:= Row + YInc[Pass];
             if (Row > cHei)
             then begin
                  Inc(Pass);
                  Row := YLin[Pass];
                  DIBoffs := DIBend;
                  dec(DIBoffs, cDIBline * longint(Row));
             end {if (Row > cHei)}
             else dec(DIBoffs, cDIBline * longint(YInc[Pass]));
             {-- MultiTasking}
             if (MulTa <> nil)
             then begin
                  Proz   := round(y * ProzFaktor);
                  bAbort := TMultiTasking(MulTa)(DMG_Repack, Proz);
                  if bAbort then exit;
             end {MultiTasking};
          end {alle Zeilen konvertieren};
     end {Interlace}
  end {with DMGS};
end {procedure Repack4};
{----------------------------------------------	Repack8}
procedure Repack8(InterLaced: Bool);
var
pGIFv, pDIBv	: pointer;
DIBoffs, DIBend : longint;
y, cHei         : integer;
Pass, Row       : integer;
Proz            : longint;
begin
  with DMGS
  do begin
     {--------- Startinitialisierungen}
     wOffset := 0;                              {Anfang entpacktes GIF-Image}
     with pBMI^.bmiHeader
     do begin
        cHei := biHeight - 1;
        DIBend := biSizeImage + cBMI - cDIBline; {Letzte Bildzeile im DIB}
        DIBoffs := DIBend;
     end {with pBMI^.bmiHeader};
     ProzFaktor := 100 / cHei;
     {--------- NonInterlaced}
     if not(InterLaced)
     then for y := 0 to cHei
     do begin
        {------ ganze Quell-Zeile ins DIB kopieren}
        pGIFv := pWrite + wOffset;
        inc(wOffset, wLineLength);
        pDIBv := pChar(pBMI) + DIBoffs;
        dec(DIBoffs, cDIBline);
        Move(pGIFv^, pDIBv^, wLineLength);
        {------ MultiTasking}
        if (MulTa <> nil)
        then begin
             Proz   := round(y * ProzFaktor);
             bAbort := TMultiTasking(MulTa)(DMG_Repack, Proz);
             if bAbort then exit;
        end {MultiTasking};
     end {kein Interlace}
     {--------- InterLaced}
     else begin
          Pass := 1;
          Row  := 0;
          for y := 0 to cHei
          do begin
             {-- ganze Quell-Zeile interlaced ins DIB kopieren}
             pGIFv := pWrite + wOffset;
             inc(wOffset, wLineLength);
             pDIBv := pChar(pBMI) + DIBoffs;
             Move(pGIFv^, pDIBv^, wLineLength);
             Row:= Row + YInc[Pass];
             if (Row > cHei)
             then begin
                  inc(Pass);
                  Row := YLin[Pass];
                  DIBoffs := DIBend;
                  dec(DIBoffs, cDIBline * longint(Row));
             end {if (Row > cHei)}
             else dec(DIBoffs, cDIBline * longint(YInc[Pass]));
             {-- MultiTasking}
             if (MulTa <> nil)
             then begin
                  Proz   := round(y * ProzFaktor);
                  bAbort := TMultiTasking(MulTa)(DMG_Repack, Proz);
                  if bAbort then exit;
             end {MultiTasking};
          end {alle Zeilen konvertieren};
     end {InterLaced};
  end {with DMGS};
end {procedure Repack8};

{==============================================	Öffentliche GIF-Funktionen}

{----------------------------------------------	LoadTheGIF}
{ Eingang:                                                }
{ in DMGS.Bildname        : DateiName und Pfad            }
{ Ausgang:                                                }
{ in DMGS.pBMI            : das Bild als DIB              }
{ in mg_LastError         : Fehler bei Return = false     }
function LoadTheGIF: Boolean;
var
cWid, cHei      : integer;
InterLaced      : bool;
GIFScrHeader    : tGIFScrHeader;
GIFImgHeader    : tGIFImgHeader;
BlockType       : char;
Done            : boolean;
begin
  {------------- Start-Initialisierungen}
  Result     := false;
  Done       := false;
  {------------- Stream erzeugen}
  if not(GetPictureStream)
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {Fehler beim Bild laden};
  {------------- IOBuffers besorgen}
  DMGS.rBufLen := cIOBufLen;                   {das muß hier reichen}
  DMGS.wBufLen := cIOBufLen;                   {das muß hier reichen}
  if not(GetBufferMem)
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {Fehler beim Puffer holen};
  {------------- Bild auf GIF-Signum testen}
  if not(TestHeader)
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {Bild auf GIF-Signum testen};
  {------------- Screen Descriptor holen}
  if not(GetScrHeader(@GIFScrHeader))
  then begin
       ExitConvProc(mg_LastError);
       exit;
  end {Screen Descriptor holen};
  {------------- GIF-Blöcke bearbeiten}
  while not(Done)
  do begin
     BlockType := Chr(GetStreamByte);
     with DMGS do if rError OR bAbort
     then begin
          if rError
          then ExitConvProc(MGERR_READERROR)
          else ExitConvProc(MGERR_CANCEL);
          exit;
     end {with DMGS do};
     case BlockType of

       {-------- Image Descriptor Block}
       ',':
       begin
         {------ Image Descriptor holen}
         if not(GetImgHeader(@GIFImgHeader))
         then begin
              ExitConvProc(mg_LastError);
              exit;
         end {Image Descriptor holen};
         {------ Globale Initialisierungen}
         Interlaced  := (GIFImgHeader.Flag and $40) <> 0;
         cWid        := GIFImgHeader.ImageWidth;
         cHei        := GIFImgHeader.ImageHeight;
         {------ GIF-Größe und GIF-Zeilengröße berechnen und Speicher besorgen}
         DMGS.wSize := longint(cWid) * longint(cHei);
         DMGS.wLineLength := cWid;
         if not(GetExpandedMem)
         then begin
              ExitConvProc(mg_LastError);
              exit;
         end {keinen Expanded Speicher gekriegt};
         {------ GIF-Image entpacken und Original-Bild-Speicher freigeben}
         if not(Expand)
         then begin
              ExitConvProc(mg_LastError);
              exit;
         end {Fehler beim Entpacken};
         FreePictureStream;
         with DMGS
         do begin
            {--- Achtung: 5-7-BPP GIF's müssen auf 8-BPP umgesetzt werden}
            if (BPP < 8) AND (BPP > 4)
            then begin
                 BPP := 8;
                 Farben := 256;
            end {5-7-BPP GIF's umsetzen};
            {--- DIB-Größe berechnen}
            cBMI  := sizeof(TBitmapInfoHeader) + Farben * sizeof(TRGBQuad);
            cDIB  := mg_GetDIBSize(cWid, cHei, BPP);
            cDIBLine := cDIB div (cHei);
            {--- Speicher holen, verriegeln und pBMI-Header füllen}
            pBMI := mg_SetupDIB(@Palette, cWid, cHei, cDIB, cBMI, BPP);
            if (pBMI = nil)
            then begin
                 ExitConvProc(MGERR_NOMEMORY);
                 exit;
            end {keinen DIB-Speicher gekriegt};
         end {with DMGS do};
         {----- GIF in DIB wandeln und Expanded-Bild-Speicher freigeben}
         case DMGS.BPP of
              8 : Repack8(InterLaced);
              4 : Repack4(InterLaced);
              1 : Repack1(InterLaced);
         end {case BPP};
         if DMGS.bAbort
         then begin
              ExitConvProc(MGERR_CANCEL);
              exit;
         end {Nutzerabbruch};
         FreeExpandedMem;
         Done := true;
       end {Image Descriptor Block};

       {------- Extended Function Block}
       '!': begin
            if not(SkipExtension)
            then begin
                 ExitConvProc(mg_LastError);
                 exit;
            end {Skip Extended Function Block};
       end {Extended Function Block};

       {------- File Ende}
       ';': Done := true;
     end {case BlockType of};
  end;
  {------------- Speicher bis auf DIB freigeben}
  ExitConvProc(0);
  Result := mg_LastError = 0;
end {function LoadTheGIF};

end.
