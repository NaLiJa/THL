
Unit DMGrJPEG;

{===============================================================}
{ JPEG-Bilder-Konverter der DMGrafik.dll                        }
{ Copyright (C) 1996 Detlef Meister                             }
{								}
               Interface
{								}
{===============================================================}

uses Windows;


{==============================================	exportierte Funktionen}
procedure mg_JPGIn_Options(Palette, Gray, TwoPass: bool; Dither: integer); stdcall;
procedure mg_JPGOut_SetQuality(Quality: integer); stdcall;
function  mg_SaveTheJPG(DIB: pBitmapInfo; Name: pChar): boolean; stdcall;

{==============================================	öffentliche Funktionen}
function LoadTheJPG: bool;


{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses jMoreCfg, jerror, jDefErr, jpeglib, jdapimin, jdatasrc, jdapistd,
     jcapimin, jdatadst, jcapistd, jcparam,
     DMGBasic, SysUtils, Classes;


{==============================================	lokale Typen}

{---------------------------------------------- extended error handler}
type
jmp_buf         = pointer;
type
my_error_ptr    = ^my_error_mgr;
my_error_mgr    = record
                  pub           : jpeg_error_mgr;
                  setjmp_buffer : jmp_buf;
end {record my_error_mgr};


{==============================================	lokale Funktionen}

{---------------------------------------------- GetThe_mg_Error}
{ Setzt die JPEG-Fehler-Codes in die der DMGrafik.dll um   }
function GetThe_mg_Error(cinfo: j_common_ptr): word;
var
Fehler          : J_MESSAGE_CODE;
begin
  Fehler := J_MESSAGE_CODE(cinfo^.err^.msg_code);
  case Fehler of

       {-------- diese dürften nie auftreten!!!}
       (*JERR_BAD_ALIGN_TYPE,
       JERR_QUANT_FEW_COLORS,
       JERR_QUANT_MANY_COLORS,
       JERR_BUFFER_SIZE,
       JERR_CANT_SUSPEND,
       JERR_BAD_POOL_ID,
       JERR_BAD_BUFFER_MODE,
       JERR_BAD_DCTSIZE,
       JERR_BAD_IN_COLORSPACE,
       JERR_BAD_J_COLORSPACE,
       JERR_BAD_ALLOC_CHUNK,*)

       {-------- Format nicht unterstützt}
       JERR_WIDTH_OVERFLOW,
       JERR_NO_HUFF_TABLE,
       JERR_NO_IMAGE,
       JERR_NO_QUANT_TABLE,
       JERR_NO_SOI,
       JERR_NO_BACKING_STORE,
       JERR_NOTIMPL,
       JERR_NOT_COMPILED,
       JERR_IMAGE_TOO_BIG,
       JERR_FRACT_SAMPLE_NOTIMPL,
       JERR_CCIR601_NOTIMPL,
       JERR_ARITH_NOTIMPL             : Result := MGERR_NOTSUPPORT;

       {-------- Falsches Format}
       JERR_MISMATCHED_QUANT_TABLE    : Result := MGERR_WRONGFORM;

       {-------- Datei-Lesefehler}
       JERR_TOO_LITTLE_DATA,
       JERR_UNKNOWN_MARKER,
       JERR_SOF_DUPLICATE,
       JERR_SOF_NO_SOS,
       JERR_SOF_UNSUPPORTED,
       JERR_SOI_DUPLICATE,
       JERR_SOS_NO_SOF,
       JERR_QUANT_COMPONENTS,
       JERR_MISSING_DATA,
       JERR_MODE_CHANGE,
       JERR_INPUT_EMPTY,
       JERR_HUFF_CLEN_OVERFLOW,
       JERR_HUFF_MISSING_CODE,
       JERR_EOI_EXPECTED,
       JERR_FILE_READ,
       JERR_COMPONENT_COUNT,
       JERR_CONVERSION_NOTIMPL,
       JERR_DAC_INDEX,
       JERR_DAC_VALUE,
       JERR_DHT_COUNTS,
       JERR_DHT_INDEX,
       JERR_DQT_INDEX,
       JERR_EMPTY_IMAGE,
       JERR_BAD_PRECISION,
       JERR_BAD_PROGRESSION,
       JERR_BAD_PROG_SCRIPT,
       JERR_BAD_SAMPLING,
       JERR_BAD_SCAN_SCRIPT,
       JERR_BAD_STATE,
       JERR_BAD_MCU_SIZE,
       JERR_BAD_LENGTH,
       JERR_BAD_COMPONENT_ID          : Result := MGERR_READERROR;

       {-------- Speicherfehler}
       JERR_VIRTUAL_BUG,
       JERR_BAD_VIRTUAL_ACCESS,
       JERR_OUT_OF_MEMORY             : Result := MGERR_NOMEMORY;

       {-------- Datei-Schreibfehler}
       JERR_FILE_WRITE                : Result := MGERR_WRITEERROR;

       {-------- selbst implementierte JPEG-Fehler}
       JERR_INPUT_EOF                 : Result := MGERR_ENDOFIMG;

       {-------- Warnungen und Traces sind, wenn sie hier ankommen, }
       {         vom Nutzer abgebrochen worden!                     }
       JTRC_16BIT_TABLES,
       JTRC_ADOBE,
       JTRC_APP0,
       JTRC_APP14,
       JTRC_DAC,
       JTRC_DHT,
       JTRC_DQT,
       JTRC_DRI,
       JTRC_EMS_CLOSE,
       JTRC_EMS_OPEN,
       JTRC_EOI,
       JTRC_HUFFBITS,
       JTRC_JFIF,
       JTRC_JFIF_BADTHUMBNAILSIZE,
       JTRC_JFIF_MINOR,
       JTRC_JFIF_THUMBNAIL,
       JTRC_MISC_MARKER,
       JTRC_PARMLESS_MARKER,
       JTRC_QUANTVALS,
       JTRC_QUANT_3_NCOLORS,
       JTRC_QUANT_NCOLORS,
       JTRC_QUANT_SELECTED,
       JTRC_RECOVERY_ACTION,
       JTRC_RST,
       JTRC_SMOOTH_NOTIMPL,
       JTRC_SOF,
       JTRC_SOF_COMPONENT,
       JTRC_SOI,
       JTRC_SOS,
       JTRC_SOS_COMPONENT,
       JTRC_SOS_PARAMS,
       JTRC_TFILE_CLOSE,
       JTRC_TFILE_OPEN,
       JTRC_UNKNOWN_IDS,
       JTRC_XMS_CLOSE,
       JTRC_XMS_OPEN,
       JWRN_ADOBE_XFORM,
       JWRN_BOGUS_PROGRESSION,
       JWRN_EXTRANEOUS_DATA,
       JWRN_HIT_MARKER,
       JWRN_HUFF_BAD_CODE,
       JWRN_JFIF_MAJOR,
       JWRN_JPEG_EOF,
       JWRN_MUST_RESYNC,
       JWRN_NOT_SEQUENTIAL,
       JWRN_TOO_MUCH_DATA             : Result := MGERR_CANCEL;

       {-------- alle anderen erzeugen unbekannten Fehler}
       else                             Result := $ff;
  end;
end {function GetThe_mg_Error};
{----------------------------------------------- überschriebene format_message}
procedure MyFormatMessage(cinfo: j_common_ptr; var buffer: string); far;
var
err             : jpeg_error_mgr_ptr;
msg_code        : J_MESSAGE_CODE;
msgtext         : string;
isstring        : boolean;
begin
  err := cinfo^.err;
  msg_code := J_MESSAGE_CODE(err^.msg_code);
  msgtext := '';
  {------------- Look up message string in proper table }
  if (msg_code > JMSG_NOMESSAGE)
  and (msg_code <= J_MESSAGE_CODE(err^.last_jpeg_message))
  then msgtext := err^.jpeg_message_table^[msg_code]
  else if (err^.addon_message_table <> NIL)
  and (msg_code >= err^.first_addon_message)
  and (msg_code <= err^.last_addon_message)
  then msgtext := err^.addon_message_table^[J_MESSAGE_CODE(ord(msg_code)
                  - ord(err^.first_addon_message))];
  {------------- Defend against bogus message number }
  if (msgtext = '')
  then begin
       err^.msg_parm.i[0] := int(msg_code);
       msgtext := err^.jpeg_message_table^[JMSG_NOMESSAGE];
  end;
  {------------- Check for string parameter as indicated by %s in the message text}
  isstring := Pos('%s', msgtext) > 0;
  {------------- Format the message into the passed buffer }
  if (isstring)
  then buffer := Concat(msgtext, err^.msg_parm.s)
  else buffer := Format(msgtext, [err^.msg_parm.i[0], err^.msg_parm.i[1],
                                  err^.msg_parm.i[2], err^.msg_parm.i[3],
                                  err^.msg_parm.i[4], err^.msg_parm.i[5],
                                  err^.msg_parm.i[6], err^.msg_parm.i[7]]);
end;
{----------------------------------------------- überschriebene output_message}
procedure MyOutputMessage(cinfo: j_common_ptr); far;
const
MsgTyp          = MB_APPLMODAL OR MB_ICONERROR OR MB_OKCANCEL;
var
buffer          : string;
Erg             : word;
begin
  {------------- Create the message}
  cinfo^.err^.format_message(cinfo, buffer);
  {------------- Send it to stderr, adding a newline}
  Erg := MessageBox(0, pChar(buffer), pChar(LoadStr(MGERR_JPGWARNUNG)), MsgTyp);
  if (Erg = IDCANCEL)
  then begin
       mg_LastError := GetThe_mg_Error(cinfo);
       cinfo^.err^.error_exit(cinfo);
  end;
end;
{----------------------------------------------- define error recovery point}
{                                                Return 0 when OK           }
function setjmp(setjmp_buffer: jmp_buf): int;
begin
  setjmp := 0;
end;
{----------------------------------------------- Return control to setjmp point}
procedure longjmp(setjmp_buffer : jmp_buf; flag : int);
begin
  {------------- stille Exception auslösen - das ganze Ding funktioniert nur, }
  {              weil im IJG code kein Exception-Handling eingebaut ist. Eine }
  {              durch die überschrieben error_exit Methode ausgelöste Excep- }
  {              tion hangelt sich durch die NICHT-Behandlung bis zum try-    }
  {              except-Block der Hauptroutine LoadTheJPG und wird erst dort  }
  {              behandelt!                                                   }
  Abort;
end;
{---------------------------------------------- überschriebene error_exit}
{ The routine that will replace the standard error_exit method}
procedure MyErrorExit(cinfo: j_common_ptr); far;
var
myerr           : my_error_ptr;
begin
  {------------- cinfo^.err points to a my_error_mgr struct}
  myerr := my_error_ptr(cinfo^.err);
  {------------- Return control to the setjmp point}
  longjmp(myerr^.setjmp_buffer, 1);
end;
{----------------------------------------------	GetJPEGOutStream}
function GetJPEGOutStream: boolean;
const
fmFileOpen      = fmCreate OR fmShareExclusive;
begin
  try
    with DMGS
    do begin
       StreamOpen := false;
       Stream     := tFileStream.Create(Bildname, fmFileOpen);
       StreamOpen := true;
       Result     := true;
    end {DMGS};
  except
    On EFCreateError
    do begin
       Result := false;
       mg_LastError := MGERR_READOPEN;
    end;
  end;
end {function GetJPEGOutStream};


{==============================================	globale öffentliche Funktionen}

{----------------------------------------------	LoadTheJPG}
{ Eingang:                                                }
{ in DMGS.Bildname        : DateiName und Pfad            }
{ Ausgang:                                                }
{ in DMGS.pBMI            : das Bild als DIB              }
{ in mg_LastError         : Fehler bei Return = false     }
function LoadTheJPG: bool;
var
pDIBdata        : pointer;
Proz            : longint;
cWid, cHei	: longint;
cinfo           : jpeg_decompress_struct;
jerr            : my_error_mgr;
buffer          : JSAMPARRAY;		        {Ausgabe-Zeilenpuffer}
i               : integer;
JPEG_BPP        : word;
JPEG_Colors     : word;
begin
  Result := false;
  try
    {----------- JPEG Eingabe-Stream erzeugen}
    if not (GetPictureStream)
    then begin
         ExitConvProc(mg_LastError);
         exit;
    end;
    {----------- JPEG Error Manager object erzeugen}
    cinfo.err := jpeg_std_error(jerr.pub);
    {----------- überschriebene Methoden in JPEG Error Manager einhängen}
    jerr.pub.error_exit := MyErrorExit;
    jerr.pub.format_message := MyFormatMessage;
    jerr.pub.output_message := MyOutputMessage;
    jerr.pub.trace_level := 0;
    {------------- Establish setjmp return context for MyErrorExit to use}
    if (setjmp(jerr.setjmp_buffer)<>0)
    then begin
         jpeg_destroy_decompress(@cinfo);
         ExitConvProc(GetThe_mg_Error(@cinfo));
         exit;
    end;
    {----------- JPEG Decompressor erzeugen}
    jpeg_create_decompress(@cinfo);
    {----------- Eingabe-Stream einhängen}
    jpeg_stdio_src(@cinfo, DMGS.Stream);
    {----------- JPEG-Header einlesen, auswerten und Defaults setzen}
    jpeg_read_header(@cinfo, TRUE);
    {----------- Defaults für Decompression überschreiben}
    cinfo.scale_num := 1;
    cinfo.scale_denom := 1; 
    cinfo.dct_method := JDCT_DEFAULT;  {JDCT_ISLOW}
    cinfo.dither_mode := J_DITHER_MODE(JPEG_DitherMode);
    cinfo.two_pass_quantize := JPEG_TwoPass;
    {----------- übergebene Parameter für Grayscale setzen }
    if JPEG_GrayScale then cinfo.out_color_space := JCS_GRAYSCALE;
    if (cinfo.out_color_space = JCS_GRAYSCALE) then JPEG_Palette := true;
    {----------- Wenn Palette gefordert, 256 Farben einstellen}
    if JPEG_Palette
    then begin
         JPEG_BPP := 8;
         JPEG_Colors := (1 SHL JPEG_BPP) AND $1ff;
         cinfo.quantize_colors := true;
         cinfo.desired_number_of_colors := JPEG_Colors;
    end
    else begin
         JPEG_BPP := 24;
         JPEG_Colors := (1 SHL JPEG_BPP) AND $1ff;
         cinfo.quantize_colors := false;
    end;
    {----------- Start decompressor}
    jpeg_start_decompress(@cinfo);
    {----------- DIB-Bildwerte berechnen. Nach jpeg_start_decompress  }
    {            sind die Ausgabe-Bildmaße da, die Palette, falls wir }
    {            eine wollen...                                       }
    with DMGS
    do begin
       {-------- Palette kopieren}
       if JPEG_Palette
       then for i := 0 to cinfo.actual_number_of_colors - 1
       do if (cinfo.out_color_space = JCS_GRAYSCALE)
       then begin
            Palette[i, Blue]  := i;
            Palette[i, Green] := i;
            Palette[i, Red]   := i;
       end
       else begin
            Palette[i, Blue]  := cinfo.colormap[RGB_BLUE]^[i];
            Palette[i, Green] := cinfo.colormap[RGB_GREEN]^[i];
            Palette[i, Red]   := cinfo.colormap[RGB_RED]^[i];
       end {Farbtabelle initialisieren};
       cWid       := cinfo.output_width;
       cHei       := cinfo.output_height;
       BPP        := JPEG_BPP;
       cBMI       := sizeof(TBitmapInfoHeader) + JPEG_Colors * sizeof(tRGBQuad);
       cDIB       := mg_GetDIBSize(cWid, cHei, BPP);
       cDIBLine   := cDIB DIV cHei;
       ProzFaktor := 100 / cHei;
       {-------- DIB-Speicher holen und initialisieren}
       pBMI := mg_SetupDIB(@Palette, cWid, cHei, cDIB, cBMI, BPP);
       if (pBMI = nil)
       then begin
            jpeg_destroy_decompress(@cinfo);
            ExitConvProc(MGERR_NOMEMORY);
            Result := FALSE;
            exit;
       end {keinen Speicher gekriegt};
       {-------- DIB-Data-Zeiger auf DIB-Ende einstellen}
       pDIBdata := pointer(longint(pBMI) + cBMI + cDIB);
    end {with DMGS};
    {----------- Puffer in DIB-Zeilenlänge holen, der automatisch   }
    {            bei jpeg_destroy_decompress freigegeben wird.      }
    buffer := cinfo.mem^.alloc_sarray(j_common_ptr(@cinfo), JPOOL_IMAGE,
              DMGS.cDIBLine, 1);
    {---------- ImageDaten zeilenweise dekomprimieren. Wir benutzen }
    {           die statische Library-Variable cinfo.output_scanline}
    {           als Schleifenzähler                                 }
    while (cinfo.output_scanline < cinfo.output_height)
    do begin
       {-------- jpeg_read_scanlines expects an array of pointers to }
       {         scanlines. Here the array is only one element long, }
       {         but you could ask for more than one scanline at a   }
       {         time if that's more convenient.                     }
       jpeg_read_scanlines(@cinfo, buffer, 1);
       {-------- DIB-Zeile in DIB kopieren}
       pDIBdata := pointer(longint(pDIBdata) - DMGS.cDIBLine);
       Move(buffer[0]^, pDIBdata^, DMGS.cDIBLine);
       {-------- MultiTasking}
       with DMGS
       do if (MulTa <> nil)
       then begin
            Proz   := round(cinfo.output_scanline * ProzFaktor);
            bAbort := TMultiTasking(MulTa)(DMG_Repack, Proz);
            if bAbort
            then begin
                 jpeg_destroy_decompress(@cinfo);
                 ExitConvProc(MGERR_CANCEL);
                 Result := FALSE;
                 exit;
            end {Abbruch durch Benutzer};
       end {MultiTasking};
    end {ImageDaten zeilenweise dekomprimieren};
    {----------- Finish decompression und freigeben JPEG decompression object}
    jpeg_finish_decompress(@cinfo);
    jpeg_destroy_decompress(@cinfo);
    {----------- DMGrafik-typische Sachen freigeben, u.a. Stream}
    ExitConvProc(0);
    Result := TRUE;
  except
    On EInOutError
    do begin
       ExitConvProc(MGERR_READOPEN);
       Result := FALSE;
    end {EInOutError};
    On EAbort
    do begin
       {-------- hier die JPEG-Fehler auf meine aufteilen}
       jpeg_destroy_decompress(@cinfo);
       ExitConvProc(GetThe_mg_Error(@cinfo));
       Result := FALSE;
    end {EAbort};
  end {except};
end {function LoadTheJPG};


{==============================================	exportierte Funktionen}

{----------------------------------------------	mg_JPGIn_SetPalette}
procedure mg_JPGIn_Options(Palette, Gray, TwoPass: bool; Dither: integer);
begin
  JPEG_Palette    := Palette;
  JPEG_GrayScale  := Gray;
  JPEG_TwoPass    := TwoPass;
  JPEG_DitherMode := Dither;
end {procedure mg_JPGIn_SetPalette};

{----------------------------------------------	mg_JPGOut_SetQuality}
{ Eingang:                                                          }
{ Quality: Wert von 0 (schrecklich) bis 100 (sehr gut)              }
procedure mg_JPGOut_SetQuality(Quality: integer);
begin
  JPEG_Quality := Quality;
end {procedure mg_JPGOut_SetQuality};
{----------------------------------------------	mg_SaveTheJPG}
{ Eingang :                                                  }
{ DIB     : Zeiger auf DIB (pBitmapInfo)                     }
{ Name    : Name unter dem das JPEG-Bild gespeichert wird    }
{ Ausgang : true/false                                       }
{           bei false Fehlernummer in mg_LastError           }                                      
function mg_SaveTheJPG(DIB: pBitmapInfo; Name: pChar): boolean;
var
cinfo           : jpeg_compress_struct;
jerr            : my_error_mgr;
buffer          : JSAMPARRAY;		        {Ausgabe-Zeilenpuffer}
cWid, cHei      : integer;
pDIBdata        : pointer;
Proz            : longint;
begin
  Result := false;
  {------------	DMGS initialisieren}
  FillChar(DMGS, sizeof(tDMGS), #0);
  mg_LastError  := 0;
  DMGS.Bildname := Name;
  {------------- QuellDIB-Werte besorgen}
  with DMGS
  do begin
     with DIB^.bmiHeader
     do begin
        BPP := biBitCount;
        {------- DIB muß 24 bpp haben}
        if (BPP <= 8) AND (BPP <> 0)
        then begin
             ExitConvProc(MGERR_TOFEWCOLORS);
             exit;
        end {kein TrueColor-Bild};
        cWid     := biWidth;
        cHei     := biHeight;
     end {with DIB^.bmiHeader};
     cDIB     := mg_GetDIBSize(cWid, cHei, BPP);
     cDIBLine := cDIB DIV cHei;
     cBMI     := sizeof(TBitmapInfoHeader);
     Farben   := (1 SHL BPP) AND $1ff;
     if (BPP < 9) then cBMI := cBMI + Farben * sizeof(TRGBQuad);
     {---------- DIB-Data-Zeiger auf DIB-Ende einstellen}
     pDIBdata := pointer(longint(DIB) + cBMI + cDIB);
  end {QuellDIB-Werte besorgen};
  {------------- weitere Vorgaben ermitteln}
  ProzFaktor := 100 / cHei;
  try
    {----------- JPEG Error Manager object erzeugen}
    cinfo.err := jpeg_std_error(jerr.pub);
    {----------- überschriebene Methoden in JPEG Error Manager einhängen}
    jerr.pub.error_exit := MyErrorExit;
    jerr.pub.format_message := MyFormatMessage;
    jerr.pub.output_message := MyOutputMessage;
    jerr.pub.trace_level := 0;
    {----------- JPEG Compressor erzeugen}
    jpeg_create_compress(@cinfo);
    {----------- JPEG Ausgabe-Stream erzeugen}
    if not(GetJPEGOutStream)
    then begin
         jpeg_destroy_compress(@cinfo);
         ExitConvProc(mg_LastError);
         exit;
    end;
    {----------- JPEG Ausgabe-Stream einhängen}
    jpeg_stdio_dest(@cinfo, DMGS.Stream);
    {----------- JPEG Ausgabe-Werte setzen}
    cinfo.image_width := cWid;
    cinfo.image_height := cHei;
    if (DMGS.BPP = 8)
    then cinfo.input_components := 1
    else cinfo.input_components := 3;
    cinfo.in_color_space := JCS_RGB;
    jpeg_set_defaults(@cinfo);
    {----------- Now you can set any non-default parameters you wish to. Here }
    {            we just illustrate the use of quality (quantization table)   }
    {            scaling:                                                     }
    jpeg_set_quality(@cinfo, JPEG_Quality, TRUE);
    {----------- TRUE ensures that we will write a complete interchange-JPEG  }
    {            file. Pass TRUE unless you are very sure of what you're doing}
    jpeg_start_compress(@cinfo, TRUE);
    {----------- Puffer in DIB-Zeilenlänge holen, der automatisch   }
    {            bei jpeg_destroy_compress freigegeben wird.      }
    {---------- ImageDaten zeilenweise dekomprimieren. Wir benutzen }
    {           die statische Library-Variable cinfo.output_scanline}
    {           als Schleifenzähler                                 }
    {----------- Puffer in DIB-Zeilenlänge holen, der automatisch   }
    {            bei jpeg_destroy_decompress freigegeben wird.      }
    buffer := cinfo.mem^.alloc_sarray(j_common_ptr(@cinfo), JPOOL_IMAGE,
              DMGS.cDIBLine, 1);
    while (cinfo.next_scanline < cinfo.image_height)
    do begin
       {-------- jpeg_write_scanlines expects an array of pointers to scanlines}
       {         Here the array is only one element long, but you could pass   }
       {         more than one scanline at a time if that's more convenient.   }
       {-------- DIB-Zeile in DIB kopieren}
       pDIBdata := pointer(longint(pDIBdata) - DMGS.cDIBLine);
       Move(pDIBdata^, buffer[0]^, DMGS.cDIBLine);
       jpeg_write_scanlines(@cinfo, buffer, 1);
       {-------- MultiTasking}
       with DMGS
       do if (MulTa <> nil)
       then begin
            Proz   := round(cinfo.next_scanline * ProzFaktor);
            bAbort := TMultiTasking(MulTa)(DMG_Repack, Proz);
            if bAbort
            then begin
                 jpeg_destroy_compress(@cinfo);
                 ExitConvProc(MGERR_CANCEL);
                 Result := FALSE;
                 exit;
            end {Abbruch durch Benutzer};
       end {MultiTasking};
    end;
    jpeg_finish_compress(@cinfo);
    jpeg_destroy_compress(@cinfo);
    ExitConvProc(0);
    Result := true;
  except
    On EInOutError
    do begin
       ExitConvProc(MGERR_READOPEN);
       Result := FALSE;
    end {EInOutError};
    On EAbort
    do begin
       {-------- hier die JPEG-Fehler auf meine aufteilen}
       jpeg_destroy_compress(@cinfo);
       ExitConvProc(GetThe_mg_Error(@cinfo));
       Result := FALSE;
    end {EAbort};
  end {except};
end {function mg_SaveTheJPG};


end.

