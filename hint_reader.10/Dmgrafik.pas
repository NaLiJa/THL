
unit DMgrafik;

{===============================================================}
{ Verbindungsunit von den Programmen zur DMGrafik.dll           }
{ Copyright (C) 1991 - 1996 Detlef Meister                      }
{                                                               }
{								}
               Interface
{								}
{===============================================================}

{----------------------------------------------	Units/Resources/Includes}
uses Windows, Forms;
{$I DMGrafi.pas}

{==============================================	DLL-Funktionen}

{---------------------------------------------- Basic-Funktionen}
function  mg_GrafikVersion: word; stdcall;
procedure mg_GrafikFehler(Win: tHandle; Tit, Zus: pChar; Err: word); stdcall;
function  mg_GetLastError: word; stdcall;
function  mg_CheckFormat(Extension: pChar): Bool; stdcall;
procedure mg_SetTheCallBack(CallBack: tFarProc); stdcall;
{---------------------------------------------- Bitmap-Basic-Funktionen}
function  mg_GetNumColors(BMI: pBitmapInfo): longint; stdcall;
function  mg_GetPaletteSize(BMI: pBitmapInfo): longint; stdcall;
function  mg_GetDIBSize(cWid, cHei: longint; BPP: word): longint; stdcall;
function  mg_SetupDIB(Palette: pRawPalette; cWid, cHei, cDIB, cBMI: longint;
          BPP: word): pBitmapInfo; stdcall;
function  mg_GetDIBMeasure(pBMI: pBitmapInfo): longint; stdcall;
function  mg_MakeBMPfromDIB(pBMI: pBitmapInfo): hBitmap; stdcall;
{---------------------------------------------- Konverter-Funktionen}
function  mg_LoadThePicture(Name: pChar; InMem: bool): pBitmapInfo; stdcall;
function  mg_SaveTheDIB(pBMI: pBitmapInfo; Name: pChar): boolean; stdcall;
function  mg_SaveTheJPG(DIB: pBitmapInfo; Name: pChar): boolean; stdcall;
procedure mg_FreeTheDIB(pBMI: pBitmapInfo); stdcall;
{---------------------------------------------- Bearbeitungs-Funktionen}
function  mg_TrueColorToGrey(pBMI: pBitmapInfo): pBitmapInfo; stdcall;
function  mg_TrueColorTo256(pBMI: pBitmapInfo): pBitmapInfo; stdcall;
function  mg_ExpandToTrueColor(pBMI: pBitmapInfo): pBitmapInfo; stdcall;
function  mg_TrueColorSizeDown(pBMI: pBitmapInfo; Wid, Hei: longint)
          : pBitmapInfo; stdcall;
function  mg_TrueColorSizeUp(pBMI: pBitmapInfo; Wid, Hei: longint)
          : pBitmapInfo; stdcall;
function  mg_ResizePicture(pBMI: pBitmapInfo; Wid, Hei: longint)
          : pBitmapInfo; stdcall;
{---------------------------------------------- JPEG-Funktionen}
procedure mg_JPGIn_Options(Palette, Gray, TwoPass: bool; Dither: integer);
          stdcall;
procedure mg_JPGOut_SetQuality(Quality: integer); stdcall;


{==============================================	Unit-Funktionen}

{---------------------------------------------- Basic-Funktionen}
function  DMGCheckVersion(Appl: tApplication): boolean;
procedure GrafikFehler(Appl: tApplication; Fehl: word; ExText: string);
function  CheckBildFormat(Extension: string): boolean;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses SysUtils;

{==============================================	DLL-Funktionen}

{---------------------------------------------- Basic-Funktionen}
function  mg_GrafikVersion;                     external 'DMGrafik' index  1;
procedure mg_GrafikFehler;                      external 'DMGrafik' index  2;
function  mg_GetLastError;                      external 'DMGrafik' index  3;
function  mg_CheckFormat;                       external 'DMGrafik' index  4;
procedure mg_SetTheCallBack;                    external 'DMGrafik' index  5;
{---------------------------------------------- Bitmap-Basic-Funktionen}
function  mg_GetNumColors;                      external 'DMGrafik' index  6;
function  mg_GetPaletteSize;                    external 'DMGrafik' index  7;
function  mg_GetDIBSize;                        external 'DMGrafik' index  8;
function  mg_SetupDIB;                          external 'DMGrafik' index  9;
function  mg_GetDIBMeasure;                     external 'DMGrafik' index 10;
function  mg_MakeBMPfromDIB;                    external 'DMGrafik' index 11;
function  mg_SaveTheDIB;                        external 'DMGrafik' index 12;
procedure mg_FreeTheDIB;                        external 'DMGrafik' index 13;
{---------------------------------------------- Konverter-Funktionen}
function  mg_LoadThePicture;                    external 'DMGrafik' index 14;
{---------------------------------------------- Bearbeitungs-Funktionen}
function  mg_TrueColorToGrey;                   external 'DMGrafik' index 15;
function  mg_TrueColorTo256;                    external 'DMGrafik' index 16;
function  mg_ExpandToTrueColor;                 external 'DMGrafik' index 17;
function  mg_TrueColorSizeDown;                 external 'DMGrafik' index 18;
function  mg_TrueColorSizeUp;                   external 'DMGrafik' index 19;
function  mg_ResizePicture;                     external 'DMGrafik' index 20;
{---------------------------------------------- JPEG-Funktionen}
procedure mg_JPGIn_Options;                     external 'DMGrafik' index 21;
procedure mg_JPGOut_SetQuality;                 external 'DMGrafik' index 22;
function  mg_SaveTheJPG;                        external 'DMGrafik' index 23;


{==============================================	Unit-Funktionen}

{----------------------------------------------	DMGCheckVersion}
function DMGCheckVersion(Appl: tApplication): boolean;
begin
  {------------- Test auf richtige 'DMGrafik.dll'}
  if (mg_GrafikVersion < DMG_Version)
  then begin
       GrafikFehler(Appl, MGErr_WrongDLL, DMG_V_String);
       Result := false;
  end {falsche GrafikVersion}
  else Result := true;
end {function DMGCheckVersion};
{----------------------------------------------	GrafikFehler}
procedure GrafikFehler(Appl: tApplication; Fehl: word; ExText: string);
begin
  mg_GrafikFehler(Appl.Handle, pChar(Appl.Title), pChar(ExText), Fehl)
end {procedure GrafikFehler};
{----------------------------------------------	CheckBildFormat}
function CheckBildFormat(Extension: string): boolean;
begin
  Result := mg_CheckFormat(pChar(Extension));
end {function CheckBildFormat};

end {unit DMgrafik}.
