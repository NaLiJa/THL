
unit Mpvdaten;

{===============================================================}
{ Globals für das Testprojekt MPicView für die DMGrafik.dll     }
{ Copyright (C) 1996 Detlef Meister                             }
{								}
               Interface
{								}
{===============================================================}

uses
  WinTypes;

{==============================================	Globale Konstanten}

{----------------------------------------------	Fehler-Resourcen}
const
app_FirstError   = 304;
app_OnlyOne      = app_FirstError;
app_ConvertToBMP = app_FirstError + 1;
app_WrongDLL     = app_FirstError + 2;
app_LastError    = app_FirstError + 2;
{----------------------------------------------	String Resourcen}
const
rs_PicOpen       = 368;
rs_PicSave       = 369;
rs_DirOpen       = 370;
rsPicShowEnding  = 371;
{----------------------------------------------	sonstige Konstanten}
const
MinWidth         = 345;
MinHeight        = 302;

{==============================================	Globale Typen}

{----------------------------------------------	JPEG-Dither}
type
tJPG_In_Dither  = (tDit_No, tDit_Ord, tDit_FS);
tJPG_OutColors  = (tCol_No, tCol_256, tCol_Gray);


{==============================================	Globale Variablen}

{----------------------------------------------	MultiTasking}
var
UserAbort                         : boolean;
var
{----------------------------------------------	DIB-Bilder}
MemDIB                            : pBitmapInfo;
MemWid                            : integer;
MemHei                            : integer;
{----------------------------------------------	Slideshow}
AnzBilder                         : integer;
AktBild                           : integer;
BilderShow                        : boolean;
{----------------------------------------------	Dateien}
PicOpenDatPfad                    : string;
PicOpenPfdName                    : string;
PicOpenDatName                    : string;
VerzeichnisPfad                   : string;
{----------------------------------------------	Größenänderungen}
SizeVerzerr                       : boolean;
SizeBreite                        : word;
SizeHoehe                         : word;
{----------------------------------------------	JPEG-Optionen}
JPEG_In_Dither                    : tJPG_In_Dither;
JPEG_In_2Pass                     : boolean;
JPEG_In_OutColors                 : tJPG_OutColors;
JPEG_Out_Quality                  : integer;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

end.
