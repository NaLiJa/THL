
unit MPVmain;

{$ifdef TestGrafikDLL}
  {$D+}
  {$L+}
{$else}
  {$D-}
  {$L-}
{$endif}

{===============================================================}
{ Hauptformular des Testprojektes MPicView für die DMGrafik.dll }
{ Copyright (C) 1996 Detlef Meister                             }
{								}
               Interface
{								}
{===============================================================}

uses Windows, SysUtils, Messages, Classes, Graphics, Controls, Forms, Dialogs,
     Menus, ExtCtrls, Buttons, StdCtrls, Gauges, DMTools;

type
  TMPicViewMainForm = class(TForm)
    MPVMainMenu                   : TMainMenu;
    DateiMenu                     : TMenuItem;
    DatOpenMenuItem               : TMenuItem;
    DatSavemenuItem               : TMenuItem;
    N1                            : TMenuItem;
    ExitMenuItem                  : TMenuItem;
    ShowDirMenuItem               : TMenuItem;
    HilfeMenu                     : TMenuItem;
    HelpIndexMenuItem             : TMenuItem;
    HelpAboutMenuItem             : TMenuItem;
    ButtonPanel                   : TPanel;
    ExitSpeedButton               : TSpeedButton;
    PicLoadSpeedButton            : TSpeedButton;
    ShowDirSpeedButton            : TSpeedButton;
    AboutSpeedButton              : TSpeedButton;
    HilfeSpeedButton              : TSpeedButton;
    PicOpenDialog                 : TOpenDialog;
    DirShowDialog                 : TOpenDialog;
    ImageScrollBox                : TScrollBox;
    OptsMenu                      : TMenuItem;
    ButtonleisteMenuItem          : TMenuItem;
    StatusleisteMenuItem          : TMenuItem;
    N2                            : TMenuItem;
    N4                            : TMenuItem;
    BildImage                     : TImage;
    BitmapSaveDialog              : TSaveDialog;
    ExpandToTrueSpeedbutton       : TSpeedButton;
    BildSaveSpeedButton           : TSpeedButton;
    Bild1                         : TMenuItem;
    TCDownMenuItem                : TMenuItem;
    TCUpMenuItem                  : TMenuItem;
    N3                            : TMenuItem;
    TCto256MenuItem               : TMenuItem;
    TCtoGreyMenuItem              : TMenuItem;
    ExpandToTrueMenuItem          : TMenuItem;
    ResampleMenuItem              : TMenuItem;
    TCDownSpeedButton             : TSpeedButton;
    TCUpSpeedButton               : TSpeedButton;
    ResizeSpeedButton             : TSpeedButton;
    TCto256SpeedButton            : TSpeedButton;
    TCtoGreySpeedButton           : TSpeedButton;
    GroundPanel                   : TPanel;
    StatusPanel                   : TPanel;
    ActionPanel                   : TPanel;
    ActionGauge                   : TGauge;
    N5                            : TMenuItem;
    JPEGOptsMenuItem              : TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ExitSpeedButtonClick(Sender: TObject);
    procedure HilfeSpeedButtonClick(Sender: TObject);
    procedure PicLoadSpeedButtonClick(Sender: TObject);
    procedure ButtonleisteMenuItemClick(Sender: TObject);
    procedure StatusleisteMenuItemClick(Sender: TObject);
    procedure ShowDirSpeedButtonClick(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure ExpandToTrueSpeedbuttonClick(Sender: TObject);
    procedure BildSaveSpeedButtonClick(Sender: TObject);
    procedure TCDownSpeedButtonClick(Sender: TObject);
    procedure TCUpSpeedButtonClick(Sender: TObject);
    procedure TCtoGreySpeedButtonClick(Sender: TObject);
    procedure ResizeSpeedButtonClick(Sender: TObject);
    procedure TCto256SpeedButtonClick(Sender: TObject);
    procedure JPEGOptsMenuItemClick(Sender: TObject);
  private
    { Private-Deklarationen }
    VerzeichnisListe        : tStringList;
    ShowButtonLeiste        : boolean;
    ShowStatusLeiste        : boolean;
    function  InitDefaults: boolean;
    procedure FehlerBehandeln(Fehler: word; Name: string);
    procedure EnableButtons;
    procedure wmDropFiles(var Msg : twmDropFiles); message wm_DropFiles;
    function  BildLaden(BildName: string): bool;
    procedure SetWindowSize(BildName: string);
    procedure ShowNextPicture;
  public
    { Public-Deklarationen }
  end;

var MPicViewMainForm: TMPicViewMainForm;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses MPVdaten, MPVsize, ShellAPI,
     {$ifdef TestGrafikDLL}
       DMGMain, DMGBasic, DMGColor, DMGSize, DMGrBMP, DMGrJPEG,
     {$else}
       DMGrafik,
     {$endif}
     MPVOpts;

{$R *.DFM}
{$R MPVmain.res}

{==============================================	DMGrafik_CallBack}
function DMGrafik_CallBack(wMsg: word; cProgress: longint): bool; stdcall;
var
Wert		: longint;
begin
  DMGrafik_CallBack := UserAbort;
  if UserAbort then exit;
  {------------ Aus der Botschaft Message zusammenstellen}
  case wMsg of
       DMG_Expand,
       DMG_Repack,
       DMG_Resize,
       DMG_ChgToGray,
       DMG_ExpToTrue,
       DMG_Histogramm,
       DMG_Remap,
       DMG_ChgTo256  : Wert := cProgress;
       {------- alle anderen Meldungen ignorieren}
       else Wert := 0;
  end {case mMsg of};
  MPicViewMainForm.ActionGauge.Progress := Wert;
  {------------ MultiTasking ausführen}
  Application.ProcessMessages;
  DMGrafik_CallBack := UserAbort;
end {function DMGrafik_CallBack}; 

{==============================================	Hilfskonstruktion TestGrafikDLL}
{$ifdef TestGrafikDLL}
  {-------------------------------------------- GrafikFehler}
  procedure GrafikFehler(Appl: tApplication; Fehl: word; ExText: string);
  begin
    mg_GrafikFehler(Appl.Handle, pChar(Appl.Title), pChar(ExText), Fehl)
  end {procedure GrafikFehler};
  {-------------------------------------------- CheckBildFormat}
  function CheckBildFormat(Extension: string): boolean;
  begin
    Result := mg_CheckFormat(pChar(Extension));
  end {function CheckBildFormat};
{$endif}

{==============================================	eigene Methoden}

{----------------------------------------------	InitDefaults}
function TMPicViewMainForm.InitDefaults: boolean;
begin
  Result := false;
  {$ifndef TestGrafikDLL}
    {---------- Versionstest DMGrafik.dll}
    if not(DMGCheckVersion(Application)) then exit;
  {$endif}
  {------------ Defaults setzen}
  PicOpenDatPfad := '';
  PicOpenPfdName := '';
  PicOpenDatName := '';
  VerzeichnisPfad := '';
  BilderShow     := false;
  UserAbort      := false;
  ShowButtonLeiste := true;
  ShowStatusLeiste := true;
  AnzBilder := 0;
  AktBild   := 0;
  SizeVerzerr := false;
  {------------ Stringliste für Verzeichnis-Show erstellen}
  VerzeichnisListe := TStringList.Create;
  if (VerzeichnisListe = nil) then exit;
  VerzeichnisListe.Sorted := true;
  VerzeichnisListe.Duplicates := dupIgnore;
  {------------ JPEG-Defaults setzen}
  JPEG_In_OutColors := tCol_No;                 {keine Quantisierung}
  JPEG_In_Dither    := tDit_FS;                 {Floyd-Steinberg-Dither}
  JPEG_In_2Pass     := true;                    {2-Pass-Quantisierung}
  JPEG_Out_Quality  := 80;
  {------------- und JPEG-Optionen gleich setzen}
  mg_JPGIn_Options((JPEG_In_OutColors = tCol_256),
                   (JPEG_In_OutColors = tCol_Gray),
                   JPEG_In_2Pass, integer(JPEG_In_Dither));
  mg_JPGOut_SetQuality(JPEG_Out_Quality);
  {------------ Defaults erfolgreich gesetzt}
  Result := true;
end {function TMPicViewMainForm.InitDefaults};
{----------------------------------------------	FehlerBehandeln}
procedure TMPicViewMainForm.FehlerBehandeln(Fehler: word; Name: string);
begin
  case Fehler of
       {-------- StandardErrors}
       MTERR_STDFIRST..MTERR_STDLAST:
          mt_StandardError(Fehler);
       {-------- ExtendedErrors}
       MTERR_EXTFIRST..MTERR_EXTLAST:
          mt_ExtendedError(Fehler, #13#10 + Name);
       {-------- GrafikErrors}
       MGERR_First..MGERR_Last :
          GrafikFehler(Application, Fehler, #13#10 + Name);
       {-------- ApplicationErrors}
       app_FirstError..app_LastError:
          mt_ApplicationError(Fehler, #13#10 + Name);
       {-------- Unbekannter Fehler}
       else mt_StandardError(MTERR_UNKNOWN);
  end {case Fehler};
end {procedure TMPicViewMainForm.FehlerBehandeln};
{----------------------------------------------	EnableButtons}
procedure TMPicViewMainForm.EnableButtons;
var
PicLoaded       : boolean;
begin
  {------------- Arbeitserleichterung}
  PicLoaded := (length(PicOpenDatName) > 0);
  {------------- Speedbuttons}
  BildSaveSpeedButton.Enabled := PicLoaded;
  TCDownSpeedButton.Enabled := PicLoaded;
  TCUpSpeedButton.Enabled := PicLoaded;
  ResizeSpeedButton.Enabled := PicLoaded;
  TCto256SpeedButton.Enabled := PicLoaded;
  TCtoGreySpeedButton.Enabled := PicLoaded;
  ExpandToTrueSpeedbutton.Enabled := PicLoaded;
  {------------- Menüs}
  DatSavemenuItem.Enabled := PicLoaded;
  TCDownMenuItem.Enabled := PicLoaded;
  TCUpMenuItem.Enabled := PicLoaded;
  ResampleMenuItem.Enabled := PicLoaded;
  TCto256MenuItem.Enabled := PicLoaded;
  TCtoGreyMenuItem.Enabled := PicLoaded;
  ExpandToTrueMenuItem.Enabled := PicLoaded;
end {procedure TMPicViewMainForm.EnableButtons};
{----------------------------------------------	wmDropFiles}
procedure TMPicViewMainForm.wmDropFiles(var Msg : tWMDropFiles);
var
Buf             : array[0..255] of char;
ExtBuf          : string[4];
DateiAnzahl     : integer;
begin
  {------------- Anzahl gedroppter Dateien holen}
  DateiAnzahl := DragQueryFile(Msg.Drop, -1, nil, 0);
  {------------- nur eine Datei aktzeptieren}
  if (DateiAnzahl = 1)
  then begin
       {-------- gedroppten Dateinamen holen}
       DragQueryFile(Msg.Drop, 0, Buf, sizeof(Buf));
       PicOpenDatPfad := Buf;
       PicOpenPfdName := ExtractFilePath(PicOpenDatPfad);
       PicOpenDatName := ExtractFileName(PicOpenDatPfad);
       ExtBuf         := ExtractFileExt(PicOpenDatPfad);
       {-------- Extension prüfen}
       if CheckBildFormat(ExtBuf)
       {-------- Bild laden}
       then begin
            BildLaden(PicOpenDatPfad);
            SetWindowSize(PicOpenDatPfad);
            EnableButtons;
       end
       {-------- falsche Extension}
       else FehlerBehandeln(MGERR_NotSupport, PicOpenDatPfad);
  end
  else FehlerBehandeln(app_OnlyOne, '');
  DragFinish(Msg.Drop);
end {procedure TMPicViewMainForm.wmDropFiles};
{----------------------------------------------	BildLaden}
function TMPicViewMainForm.BildLaden(BildName: string): bool;
var
Bitmap          : hBitmap;
NewDIB          : pBitmapInfo;
Measure         : LongRec;
begin
  Result := false;
  NewDIB := mg_LoadThePicture(pChar(Bildname), true);
  if (NewDIB = nil)
  then begin
       FehlerBehandeln(mg_GetLastError, BildName);
       MPicViewMainForm.ActionGauge.Progress := 0;
       exit;
  end;
  {------------- voriges DIB löschen}
  mg_FreeTheDIB(MemDIB);
  {------------- für Bildbearbeitungsfunktionen DIB aufheben}
  MemDIB := NewDIB;
  Measure := LongRec(mg_GetDIBMeasure(NewDIB));
  MemWid := Measure.Lo;
  MemHei := Measure.Hi;
  {------------- DIB in BMP konvertieren}
  Bitmap := mg_MakeBMPfromDIB(MemDIB);
  {------------- Fehler?}
  if (Bitmap = 0)
  then FehlerBehandeln(app_ConvertToBMP, BildName)
  else begin
       {-------- BMP in ImageObjekt einklinken}
       BildImage.Picture.Bitmap.Handle := Bitmap;
       {-------- Erfolg vermerken}
       Result := true;
  end;
  MPicViewMainForm.ActionGauge.Progress := 0;
end {function TMPicViewMainForm.BildLaden};
{----------------------------------------------	SetWindowSize}
procedure TMPicViewMainForm.SetWindowSize(BildName: string);
begin
  {------------ MainForm-Clientgröße anpassen}
  with MPicViewMainForm
  do begin
     ClientWidth  := BildImage.Picture.Width;
     ClientHeight := BildImage.Picture.Height;
     if ButtonPanel.Visible
     then ClientHeight := ClientHeight + ButtonPanel.Height;
     if StatusPanel.Visible
     then ClientHeight := ClientHeight + GroundPanel.Height;
     {---------- MainForm gegebenenfalls an Screengröße anpassen}
     if (Width > Screen.Width) then Width := Screen.Width;
     if (Height > Screen.Height) then Height := Screen.Height;
     {---------- MainForm gegebenenfalls an Mindestgröße anpassen}
     if (Width < MinWidth) then Width := MinWidth;
     if (Height < MinHeight) then Height := MinHeight;
  end {with MPicViewMainForm};
  {------------ gegebenenfalls Scroller anpassen}
  with ImageScrollBox
  do begin
     HorzScrollBar.Range := BildImage.Picture.Width;
     HorzScrollBar.Position := 0;
     VertScrollBar.Range := BildImage.Picture.Height;
     VertScrollBar.Position := 0;
  end {with ImageScrollBox};
  {------------ Statusanzeige}
  StatusPanel.Caption := ' ' + BildName;
end {procedure TMPicViewMainForm.SetWindowSize};
{----------------------------------------------	ShowNextPicture}
procedure TMPicViewMainForm.ShowNextPicture;
var
Buf             : string;
begin
  {------------ Sind überhaupt noch Bilder da?}
  if (AktBild < AnzBilder)
  then begin
       Buf := VerzeichnisPfad + VerzeichnisListe[AktBild];
       inc(AktBild);
       BildLaden(Buf);
       SetWindowSize(Buf);
  end
  else begin
       BilderShow := false;
       StatusPanel.Caption := LoadStr(rsPicShowEnding);
       DragAcceptFiles(handle, true);
  end;
end {procedure TMPicViewMainForm.ShowNextPicture};

{==============================================	automatische Methoden}

procedure TMPicViewMainForm.FormCreate(Sender: TObject);
var
ExtBuf          : string[4];
begin
  {------------ MainForm festlegen}
  Caption := Application.Title;
  Width   := MinWidth;
  Height  := MinHeight;
  Left    := 0;
  Top     := 0;
  {------------	Defaults setzen}
  if not(InitDefaults) then Application.Terminate;
  {------------ CallBack-Funktion an die DLL geben}
  mg_SetTheCallBack(@DMGrafik_CallBack);
  {------------ Dateiname wurde beim Start übergeben}
  if (ParamCount > 0)
  then begin
       PicOpenDatPfad := ParamStr(1);
       PicOpenPfdName := ExtractFilePath(PicOpenDatPfad);
       PicOpenDatName := ExtractFileName(PicOpenDatPfad);
       ExtBuf         := ExtractFileExt(PicOpenDatPfad);
       {-------- Extension prüfen}
       if CheckBildFormat(ExtBuf)
       {-------- Bild laden}
       then begin
            BildLaden(PicOpenDatPfad);
            SetWindowSize(PicOpenDatPfad);
       end;
  end;
  DragAcceptFiles(handle, true);
  EnableButtons;
end;

procedure TMPicViewMainForm.FormDestroy(Sender: TObject);
begin
  {------------ Bei Bedarf Hilfe freigeben}
  Application.HelpContext(help_Quit);
  {------------ gegebenenfalls alte DIB und Palette freigeben}
  mg_FreeTheDIB(MemDIB);;
end;

procedure TMPicViewMainForm.ExitSpeedButtonClick(Sender: TObject);
begin
  Close;
end;

procedure TMPicViewMainForm.HilfeSpeedButtonClick(Sender: TObject);
begin
  Application.HelpContext(1);
end;

procedure TMPicViewMainForm.PicLoadSpeedButtonClick(Sender: TObject);
var
ExtBuf          : string[4];
begin
  UserAbort := false;
  {------------ Bildnamen holen}
  with PicOpenDialog
  do begin
     Title := Application.Title + LoadStr(rs_PicOpen);
     FileName := '';
     InitialDir := PicOpenPfdName;
     if not(Execute) then exit;
     PicOpenDatPfad := FileName;
     PicOpenPfdName := ExtractFilePath(PicOpenDatPfad);
     PicOpenDatName := ExtractFileName(PicOpenDatPfad);
     ExtBuf         := ExtractFileExt(PicOpenDatPfad);
  end;
  {------------ Extension prüfen}
  if not(CheckBildFormat(ExtBuf))
  then begin
       FehlerBehandeln(MGERR_NotSupport, PicOpenDatPfad);
       exit;
  end;
  {------------ Bild laden}
  DragAcceptFiles(handle, false);
  BildLaden(PicOpenDatPfad);
  SetWindowSize(PicOpenDatPfad);
  DragAcceptFiles(handle, true);
  EnableButtons;
end;

procedure TMPicViewMainForm.ButtonleisteMenuItemClick(Sender: TObject);
begin
  ShowButtonLeiste := not(ShowButtonLeiste);
  ButtonPanel.Visible := ShowButtonLeiste;
  ButtonleisteMenuItem.Checked := ShowButtonLeiste;
  {------------ Fenstergröße anpassen}
  SetWindowSize(StatusPanel.Caption);
end;

procedure TMPicViewMainForm.StatusleisteMenuItemClick(Sender: TObject);
begin
  ShowStatusLeiste := not(ShowStatusLeiste);
  ActionGauge.Visible := ShowStatusLeiste;
  GroundPanel.Visible := ShowStatusLeiste;
  StatusPanel.Visible := ShowStatusLeiste;
  ActionPanel.Visible := ShowStatusLeiste;
  StatusleisteMenuItem.Checked := ShowStatusLeiste;
  {------------ Fenstergröße anpassen}
  SetWindowSize(StatusPanel.Caption);
end;

procedure TMPicViewMainForm.ShowDirSpeedButtonClick(Sender: TObject);
var
ExtBuf          : string[4];
Buf             : string;
FirstName       : string;
Erg             : integer;
FIB             : TSearchRec;
begin
  UserAbort := false;
  {------------ Verzeichnisnamen holen}
  with DirShowDialog
  do begin
     Title := Application.Title + LoadStr(rs_DirOpen);
     FileName := '';
     InitialDir := PicOpenPfdName;
     if not(Execute) then exit;
     VerzeichnisPfad := ExtractFilePath(FileName);
     FirstName       := ExtractFileName(FileName);
  end;
  {------------ StringList-Inhalt löschen}
  VerzeichnisListe.Clear;
  {------------ FIB initialisieren}
  Buf := '*.*';
  Erg := FindFirst(Buf, faAnyFile, FIB);
  while (Erg = 0)
  do begin
     {---------- nur Dateien berücksichtigen}
     if (FIB.Attr AND faDirectory = 0)
     then begin
          Buf := FIB.Name;
          ExtBuf := ExtractFileExt(Buf);
          if CheckBildFormat(ExtBuf) then VerzeichnisListe.Add(Buf);
     end {nur Dateien berücksichtigen};
     Erg := FindNext(FIB);
  end {while...};
  {------------ dieser Befehl soll für Win32 lebenswichtig sein}
  FindClose(FIB);
  {------------ sind überhaupt Einträge in der ListBox?}
  AnzBilder := VerzeichnisListe.Count;
  if (AnzBilder <= 0) then exit;
  {------------ angeklickten Namen finden}
  Erg := VerzeichnisListe.IndexOf(FirstName);
  if (Erg = lb_Err)
  then AktBild := 0
  else begin
       AktBild := Erg;
       BilderShow := true;
       DragAcceptFiles(handle, false);
       ShowNextPicture;
  end;
end;

procedure TMPicViewMainForm.FormKeyPress(Sender: TObject; var Key: Char);
begin
  if BilderShow
  then begin
       case Key of
            {--- Nächstes Bild}
            #32   :
            begin
              ShowNextPicture;
              Key := #0;
            end;
            {--- Bildershow abbrechen}
            #27   :
            begin
              UserAbort := true;
              BilderShow := false;
              Key := #0;
            end;
       end {case};
  end {if Bildershow}
  else case Key of
       {-------- bei ESCAPE-Taste immer UserAbort setzen}
       #27   :
       begin
         UserAbort := true;
         Key := #0;
       end;
  end {case};
end;

procedure TMPicViewMainForm.ExpandToTrueSpeedbuttonClick(Sender: TObject);
var
Bitmap          : hBitmap;
NewDIB          : pBitmapInfo;
begin
  UserAbort := false;
  if (BilderShow) then exit;
  NewDIB := mg_ExpandToTrueColor(MemDIB);
  if (NewDIB <> nil)
  then begin
       mg_FreeTheDIB(MemDIB);;
       MemDIB := NewDIB;
       {-------- DIB in BMP konvertieren}
       Bitmap := mg_MakeBMPfromDIB(MemDIB);
       {-------- Fehler?}
       if (Bitmap = 0)
       then begin
            FehlerBehandeln(app_ConvertToBMP, PicOpenDatPfad);
            MPicViewMainForm.ActionGauge.Progress := 0;
            exit;
       end;
       {-------- BMP in ImageObjekt einklinken}
       BildImage.Picture.Bitmap.Handle := Bitmap;
       SetWindowSize(PicOpenDatPfad)
  end
  else begin
       FehlerBehandeln(mg_GetLastError, PicOpenDatPfad);
       MPicViewMainForm.ActionGauge.Progress := 0;
       exit;
  end;
  MPicViewMainForm.ActionGauge.Progress := 0;
end;

procedure TMPicViewMainForm.BildSaveSpeedButtonClick(Sender: TObject);
var
bErg            : boolean;
begin
  {------------- Speicherdialog bringen}
  with BitmapSaveDialog
  do begin
     InitialDir := PicOpenPfdName;
     FileName   := ChangeFileExt(PicOpenDatName, '.bmp');
     Title := Application.Title + LoadStr(rs_PicSave);
     if not Execute then exit;
     {---------- geladenes DIB speichern}
     if (AnsiLowerCase(ExtractFileExt(FileName)) = '.jpg')
     then bErg := mg_SaveTheJPG(MemDIB, pChar(FileName))
     else bErg := mg_SaveTheDIB(MemDIB, pChar(FileName));
     MPicViewMainForm.ActionGauge.Progress := 0;
     if not(bErg) then Fehlerbehandeln(mg_GetLastError, FileName);
  end;
end;

procedure TMPicViewMainForm.TCUpSpeedButtonClick(Sender: TObject);
var
Bitmap          : hBitmap;
NewDib          : pBitmapInfo;
begin
  UserAbort := false;
  if (BilderShow) then exit;
  {------------- Bildgrößeneinstellung}
  SizeBreite := MemWid;
  SizeHoehe  := MemHei;
  if (SizeEinstellForm.ShowModal = id_Cancel) then exit;
  NewDIB := mg_TrueColorSizeUp(MemDIB, SizeBreite, SizeHoehe);
  MPicViewMainForm.ActionGauge.Progress := 0;
  if (NewDIB <> nil)
  then begin
       mg_FreeTheDIB(MemDIB);;
       MemDIB := NewDIB;
       MemWid := SizeBreite;
       MemHei := SizeHoehe;
       {-------- DIB in BMP konvertieren}
       Bitmap := mg_MakeBMPfromDIB(MemDIB);
       {-------- BMP in ImageObjekt einklinken}
       if (Bitmap <> 0)
       then begin
            BildImage.Picture.Bitmap.Handle := Bitmap;
            SetWindowSize(PicOpenDatPfad);
       end
       else FehlerBehandeln(app_ConvertToBMP, PicOpenDatPfad);
  end
  else FehlerBehandeln(mg_GetLastError, PicOpenDatPfad);
end;

procedure TMPicViewMainForm.TCtoGreySpeedButtonClick(Sender: TObject);
var
Bitmap          : hBitmap;
NewDIB          : pBitmapInfo;
begin
  UserAbort := false;
  if (BilderShow) then exit;
  NewDIB := mg_TrueColorToGrey(MemDIB);
  MPicViewMainForm.ActionGauge.Progress := 0;
  if (NewDIB <> nil)
  then begin
       mg_FreeTheDIB(MemDIB);;
       MemDIB := NewDIB;
       {-------- DIB in BMP konvertieren}
       Bitmap := mg_MakeBMPfromDIB(MemDIB);
       {-------- BMP in ImageObjekt einklinken}
       if (Bitmap <>0)
       then begin
            BildImage.Picture.Bitmap.Handle := Bitmap;
            SetWindowSize(PicOpenDatPfad);
       end
       else FehlerBehandeln(app_ConvertToBMP, PicOpenDatPfad);
  end
  else FehlerBehandeln(mg_GetLastError, PicOpenDatPfad);
end;

procedure TMPicViewMainForm.ResizeSpeedButtonClick(Sender: TObject);
var
Bitmap          : hBitmap;
NewDIB          : pBitmapInfo;
begin
  UserAbort := false;
  if (BilderShow) then exit;
  {------------- Bildgrößeneinstellung}
  SizeBreite := MemWid;
  SizeHoehe  := MemHei;
  if (SizeEinstellForm.ShowModal = id_Cancel) then exit;
  NewDIB := mg_ReSizePicture(MemDIB, SizeBreite, SizeHoehe);
  MPicViewMainForm.ActionGauge.Progress := 0;
  if (NewDIB <> nil)
  then begin
       mg_FreeTheDIB(MemDIB);;
       MemDIB := NewDIB;
       MemWid := SizeBreite;
       MemHei := SizeHoehe;
       {-------- DIB in BMP konvertieren}
       Bitmap := mg_MakeBMPfromDIB(MemDIB);
       {-------- BMP in ImageObjekt einklinken}
       if (Bitmap <> 0)
       then begin
            BildImage.Picture.Bitmap.Handle := Bitmap;
            SetWindowSize(PicOpenDatPfad);
       end
       else FehlerBehandeln(app_ConvertToBMP, PicOpenDatPfad);
  end
  else FehlerBehandeln(mg_GetLastError, PicOpenDatPfad);
end;

procedure TMPicViewMainForm.TCDownSpeedButtonClick(Sender: TObject);
var
Bitmap          : hBitmap;
NewDIB          : pBitmapInfo;
begin
  UserAbort := false;
  if (BilderShow) then exit;
  {------------- Bildgrößeneinstellung}
  SizeBreite := MemWid;
  SizeHoehe  := MemHei;
  if (SizeEinstellForm.ShowModal = id_Cancel) then exit;
  NewDIB := mg_TrueColorSizeDown(MemDIB, SizeBreite, SizeHoehe);
  MPicViewMainForm.ActionGauge.Progress := 0;
  if (NewDIB <> nil)
  then begin
       mg_FreeTheDIB(MemDIB);;
       MemDIB := NewDIB;
       MemWid := SizeBreite;
       MemHei := SizeHoehe;
       {-------- DIB in BMP konvertieren}
       Bitmap := mg_MakeBMPfromDIB(MemDIB);
       {-------- BMP in ImageObjekt einklinken}
       if (Bitmap <> 0)
       then begin
            BildImage.Picture.Bitmap.Handle := Bitmap;
            SetWindowSize(PicOpenDatPfad)
       end
       else FehlerBehandeln(app_ConvertToBMP, PicOpenDatPfad);
  end
  else FehlerBehandeln(mg_GetLastError, PicOpenDatPfad);
end;

procedure TMPicViewMainForm.TCto256SpeedButtonClick(Sender: TObject);
var
Bitmap          : hBitmap;
NewDIB          : pBitmapInfo;
begin
  UserAbort := false;
  if (BilderShow) then exit;
  NewDIB := mg_TrueColorTo256(MemDIB);
  MPicViewMainForm.ActionGauge.Progress := 0;
  if (NewDIB <> nil)
  then begin
       mg_FreeTheDIB(MemDIB);;
       MemDIB := NewDIB;
       {-------- DIB in BMP konvertieren}
       Bitmap := mg_MakeBMPfromDIB(MemDIB);
       {-------- BMP in ImageObjekt einklinken}
       if (Bitmap <> 0)
       then begin
            BildImage.Picture.Bitmap.Handle := Bitmap;
            SetWindowSize(PicOpenDatPfad)
       end
       else FehlerBehandeln(app_ConvertToBMP, PicOpenDatPfad);
  end
  else FehlerBehandeln(mg_GetLastError, PicOpenDatPfad);
end;

procedure TMPicViewMainForm.JPEGOptsMenuItemClick(Sender: TObject);
begin
  if (JPEGOptsForm.ShowModal = idOK)
  then begin
       {------------- und JPEG-Optionen gleich setzen}
       mg_JPGIn_Options((JPEG_In_OutColors = tCol_256),
                        (JPEG_In_OutColors = tCol_Gray),
                         JPEG_In_2Pass, integer(JPEG_In_Dither));
       mg_JPGOut_SetQuality(JPEG_Out_Quality);
  end;
end;

end.
