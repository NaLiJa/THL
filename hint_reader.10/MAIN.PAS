unit Main;

{
  Todo:
  -------------------------------------------
  Hilfedatei;
  Homepage
  Installer
  -------------------------------------------
}
interface

uses
  SysUtils, Windows, Messages, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, Buttons, ExtCtrls, Menus, ComCtrls, Registry;

type
  EntryType   = (etTopic,etHint,etPic,etMM);

  TMainForm = class(TForm)
    MainMenu: TMainMenu;
    FileOpenItem: TMenuItem;
    FileExitItem: TMenuItem;
    HelpContentsItem: TMenuItem;
    HelpSearchItem: TMenuItem;
    HelpHowToUseItem: TMenuItem;
    HelpAboutItem: TMenuItem;
    StatusLine: TStatusBar;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    PrintDialog: TPrintDialog;
    PrintSetupDialog: TPrinterSetupDialog;
    SpeedBar: TPanel;
    SpeedButton1: TSpeedButton;  { &Öffnen... }
    SpeedButton2: TSpeedButton;  { &Inhalt }
    SpeedButton3: TSpeedButton;  { &Info... }
    SpeedButton4: TSpeedButton;
    Compiler1: TMenuItem;
    Syntaxberprfung1: TMenuItem;
    Panel1: TPanel;
    Image1: TImage;
    Dateiladen1: TMenuItem;
    SpeedButton5: TSpeedButton;
    SpeedButton6: TSpeedButton;
    Sprache1: TMenuItem;
    Deutsch1: TMenuItem;
    SpeedButton7: TSpeedButton;
    N2: TMenuItem;
    SaveLang: TMenuItem;
    VerboseOpen: TMenuItem;  { &Beenden }
    procedure FormCreate(Sender: TObject);
    procedure ShowHint(Sender: TObject);
    procedure FileNew(Sender: TObject);
    procedure FileOpen(Sender: TObject);
    procedure FileSave(Sender: TObject);
    procedure FileSaveAs(Sender: TObject);
    procedure FilePrint(Sender: TObject);
    procedure FilePrintSetup(Sender: TObject);
    procedure FileExit(Sender: TObject);
    procedure HelpContents(Sender: TObject);
    procedure HelpSearch(Sender: TObject);
    procedure HelpHowToUse(Sender: TObject);
    procedure HelpAbout(Sender: TObject);
    procedure Syntaxberprfung1Click(Sender: TObject);
    procedure Dateiladen1Click(Sender: TObject);
    procedure Deutsch1Click(Sender: TObject);
    procedure SpeedButton7Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure SaveLangClick(Sender: TObject);
  private
    Messages : array[1..1] of string;
    HLangLib : THandle;
    LSI_Name : string;
  public
    procedure AdaptLanguage( sFilename : string );
    procedure SetLanguage( HL : THandle );
    procedure CmdParse;
    procedure Initialize;
  end;

  TStringsPack = class(TObject)
    sComplex  : TStringList;
    sComplex2 : TStringList;
    sSimple   : string;
    constructor Create;
    destructor Free;
  end;

  THEntry = class(TObject)
  public
    HType      : EntryType;
    sEntries   : TStringsPack;
    constructor Create( HT : EntryType);
    destructor Free;
    procedure GetAndSetEntry;
    procedure EditEntry;
    procedure DeleteEntry;
    function IsValid:Boolean;
    function GetText:string;
  protected
    function GetAndSetTopic:TStringsPack;
    function GetAndSetHint:TStringsPack;
    function GetAndSetPic:TStringsPack;
    function GetAndSetMM:TStringsPack;
  end;

const PRG_VER : string = '100';

var
  MainForm: TMainForm;

implementation

uses hredit, topedit, hntedit, about, pcedit, reader, mumeedit, vopen,
  picview, hntwnd, MediaWnd, LDMsgDlg, langDlg;

{$R *.DFM}

{----------------- THEntry -----------------------------}
constructor THEntry.Create( HT : EntryType);
begin
   HType := HT;
   sEntries := TStringsPack.Create;
end;

destructor THEntry.Free;
begin
  sEntries.Free;
end;

procedure THEntry.GetAndSetEntry;
begin
  case HType of
    etTopic : sEntries := GetAndSetTopic;
    etHint  : sEntries := GetAndSetHint;
    etPic   : sEntries := GetAndSetPic;
    etMM    : sEntries := GetAndSetMM;
  end;
end;

function THEntry.GetAndSetTopic:TStringsPack;
begin
  GetAndSetTopic := TopicEdit.MakeNew;
end;

function THEntry.GetAndSetHint:TStringsPack;
begin
  GetAndSetHint := HintEdit.MakeNew;
end;

function THEntry.GetAndSetPic:TStringsPack;
begin
  GetAndSetPic := PicEdit.MakeNew;
end;

function THEntry.GetAndSetMM:TStringsPack;
begin
  GetAndSetMM := MMEdit.MakeNew;
end;

function THEntry.IsValid:Boolean;
Var bRes : Boolean;
begin
  bRes := True;
  if (HType = etTopic) AND (sEntries.sSimple = '') then
    bRes := False;
  if (HType = etHint) AND (sEntries.sComplex.Count = 0) then
    bRes := False;
  if (HType = etPic) AND (sEntries.sSimple = '') then
    bRes := False;
  if (HType = etMM) AND (sEntries.sComplex.Count <> 2) then
    bRes := False;
  IsValid := bRes;
end;

function THEntry.GetText:String;
Var sRes : String;
begin
  if HType = etHint then begin
    sRes := 'HINT ('+Copy(sEntries.sComplex.Strings[0],1,30)+'...)';
    if sEntries.sSimple <>'' then
      sRes := sRes+',PIC ('+Copy(sEntries.sSimple,1,30)+')';
  end;
  if HType = etTopic then
    sRes := Copy(sEntries.sSimple,1,30)+'...';
  if HType = etPic then
    sRes := 'PIC ('+Copy(sEntries.sSimple,1,30)+')';
  if HType = etMM then
    sRes := 'MM ('+Copy(sEntries.sComplex.Strings[0],1,30)+'...)';
  GetText := sRes;
end;

procedure THEntry.EditEntry;
begin
  case HType of
    etTopic : TopicEdit.EditEntry(sEntries);
    etHint  : HintEdit.EditEntry(sEntries);
    etPic   : PicEdit.EditEntry(sEntries);
    etMM    : MMEdit.EditEntry(sEntries);
  end;
end;

procedure THEntry.DeleteEntry;
begin
  sEntries.Free;
end;

{-----------------------------------------------------------------}

{----------------- TStringsPack---------------------------}

constructor TStringsPack.Create;
begin
  sComplex  := TStringList.Create;
  sComplex2 := TStringList.Create;
end;

destructor TStringsPack.Free;
begin
  sComplex.Free;
  sComplex2.Free;
end;

{-----------------------------------------------------------------}

procedure TMainForm.FormCreate(Sender: TObject);
Var Year,Month,Day : Word;
begin
  hLangLib := 0;
{
  DecodeDate(Date,Year,Month,Day);
  if ((Year>1997) or
     ((Year=1997) and (Month>1)) or
     ((Year=1997) and (Month=1) and (Day>1)))then begin
    LDMessageDlg('Diese BETA-Version ist nur bis zum 01.01.97 lauffähig!'+#13+
               'This BETA-version expires on 01-01-97!',mtError,[mbOK],0);
    Application.Terminate;
  end;
}
  Application.OnHint := ShowHint;
  Application.HintHidePause := 10000;
end;

procedure TMainForm.ShowHint(Sender: TObject);
begin
  StatusLine.SimpleText := Application.Hint;
end;

procedure TMainForm.FileNew(Sender: TObject);
begin
  { Programmcode zum Erzeugen einer neuen Datei hier einfügen }
end;

procedure TMainForm.FileOpen(Sender: TObject);
begin
  if OpenDialog.Execute then
  begin
    { Programmcode zum Öffnen von OpenDialog.FileName hier einfügen }
    ReaderForm.ShowForm(OpenDialog.Filename);
  end;
end;

procedure TMainForm.FileSave(Sender: TObject);
begin
   { Programmcode zum Speichern der aktuellen Datei unter ihrem Namen hier einfügen }
end;

procedure TMainForm.FileSaveAs(Sender: TObject);
begin
  if SaveDialog.Execute then
  begin
    { Programmcode zum Speichern der aktuellen Datei unter SaveDialog.Filename hier einfügen }
  end;
end;

procedure TMainForm.FilePrint(Sender: TObject);
begin
  if PrintDialog.Execute then
  begin
    { Programmcode zum Drucken der aktuellen Datei hier einfügen }
  end;
end;

procedure TMainForm.FilePrintSetup(Sender: TObject);
begin
  PrintSetupDialog.Execute;
end;

procedure TMainForm.FileExit(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.HelpContents(Sender: TObject);
begin
  Application.HelpCommand(HELP_CONTENTS, 0);
end;

procedure TMainForm.HelpSearch(Sender: TObject);
const
  EmptyString: PChar = '';
begin
  Application.HelpCommand(HELP_PARTIALKEY, Longint(EmptyString));
end;

procedure TMainForm.HelpHowToUse(Sender: TObject);
begin
  Application.HelpCommand(HELP_HELPONHELP, 0);
end;

procedure TMainForm.HelpAbout(Sender: TObject);
begin
  { Programmcode zum Anzeigen des Info-Dialogs hier einfügen }
  AboutBox.ShowModal;
end;

procedure TMainForm.Syntaxberprfung1Click(Sender: TObject);
begin
  HREditor.Initialise;
  HREditor.Show;
end;

procedure TMainForm.Dateiladen1Click(Sender: TObject);
begin
  HREditor.Initialise;
  HREditor.Show;
  HREditor.OpenExistFile('');
end;

procedure TMainForm.Deutsch1Click(Sender: TObject);
Var sNewLang : string;
begin
  sNewLang := LangSel.GetNewLanguage;
  if sNewLang <> '' then begin
    AdaptLanguage(sNewLang);
  end;
end;

procedure TMainForm.AdaptLanguage( sFilename : string);
Var sLDll   : string;
    sHelp   : string;
    FLang   : TextFile;
    CBuffer : array[0..254] of char;
    sTmp    : string;
    sAuthor : string;
begin
  if HLangLib <> 0 then
    FreeLibrary(HLangLib);
  try
    AssignFile(FLang,sFilename);
    Reset(FLang);
    ReadLn(FLang,sTmp); { welche Sprache }
    sAuthor := sTmp;
    ReadLn(FLang,sTmp); { Autor }
    sAuthor := sAuthor +': '+sTmp;
    ReadLn(FLang,sLDll);
    ReadLn(FLang,sHelp);
  finally
    CloseFile(FLang);
  end;
  AboutBox.LangLabel.Caption := sAuthor;
  StrPCopy(cBuffer,sLDll);
  HLangLib := LoadLibrary(cBuffer);
  if (HLangLib = 0) then begin
    LDMessageDlg('Error loading module',mtError,[mbOk],0);
    Application.Terminate;
  end
  else begin
    Application.HelpFile := ExtractFilePath(Application.Exename);
    if Application.HelpFile[Length(Application.Helpfile)] <> '\' then
      Application.Helpfile := Application.Helpfile+'\';
    Application.HelpFile := Application.HelpFile+'help\'+sHelp;
    LangSel.SetLanguage(HLangLib);
    MainForm.SetLanguage(HLangLib);
    VerbOpen.SetLanguage(HLangLib);
    MMEdit.SetLanguage(HLangLib);
    PicEdit.SetLanguage(HLangLib);
    ReaderForm.SetLanguage(HLangLib);
    ShowPic.SetLanguage(HLangLib);
    HintWindow.SetLanguage(HLangLib);
    MMWnd.SetLanguage(HLangLib);
    HREditor.SetLanguage(HLangLib);
    HintEdit.SetLanguage(HLangLib);
    TopicEdit.SetLanguage(HLangLib);
    LDMSG_Language := HLangLib;
    LSI_Name := sFilename;
  end;
end;

procedure TMainForm.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,100,Buffer,sizeof(Buffer));
  MainMenu.Items[0].Caption := StrPas(Buffer);
  LoadString(HL,101,Buffer,sizeof(Buffer));
  MainMenu.Items[1].Caption := StrPas(Buffer);
  LoadString(HL,102,Buffer,sizeof(Buffer));
  MainMenu.Items[2].Caption := StrPas(Buffer);
  LoadString(HL,103,Buffer,sizeof(Buffer));
  MainMenu.Items[3].Caption := StrPas(Buffer);
  LoadString(HL,104,Buffer,sizeof(Buffer));
  FileOpenItem.Caption := StrPas(Buffer);
  LoadString(HL,105,Buffer,sizeof(Buffer));
  FileOpenItem.Hint := StrPas(Buffer);
  LoadString(HL,106,Buffer,sizeof(Buffer));
  FileExitItem.Caption := StrPas(Buffer);
  LoadString(HL,107,Buffer,sizeof(Buffer));
  FileExitItem.Hint := StrPas(Buffer);
  LoadString(HL,108,Buffer,sizeof(Buffer));
  Syntaxberprfung1.Caption := StrPas(Buffer);
  LoadString(HL,109,Buffer,sizeof(Buffer));
  Dateiladen1.Caption := StrPas(Buffer);
  LoadString(HL,110,Buffer,sizeof(Buffer));
  Deutsch1.Caption := StrPas(Buffer);
  LoadString(HL,111,Buffer,sizeof(Buffer));
  HelpContentsItem.Caption := StrPas(Buffer);
  LoadString(HL,112,Buffer,sizeof(Buffer));
  HelpSearchItem.Caption := StrPas(Buffer);
  LoadString(HL,113,Buffer,sizeof(Buffer));
  HelpHowToUseItem.Caption := StrPas(Buffer);
  LoadString(HL,114,Buffer,sizeof(Buffer));
  HelpAboutItem.Caption := StrPas(Buffer);
  LoadString(HL,115,Buffer,sizeof(Buffer));
  SaveLang.Caption := StrPas(Buffer);
  LoadString(HL,116,Buffer,sizeof(Buffer));
  VerboseOpen.Caption := StrPas(Buffer);
  LoadString(HL,117,Buffer,sizeof(Buffer));
  Messages[1] := StrPas(Buffer);
  LoadString(HL,118,Buffer,sizeof(Buffer));
  SpeedButton1.Hint := StrPas(Buffer);
  LoadString(HL,119,Buffer,sizeof(Buffer));
  SpeedButton5.Hint := StrPas(Buffer);
  LoadString(HL,120,Buffer,sizeof(Buffer));
  SpeedButton6.Hint := StrPas(Buffer);
  LoadString(HL,121,Buffer,sizeof(Buffer));
  SpeedButton2.Hint := StrPas(Buffer);
  LoadString(HL,122,Buffer,sizeof(Buffer));
  SpeedButton3.Hint := StrPas(Buffer);
  LoadString(HL,123,Buffer,sizeof(Buffer));
  SpeedButton4.Hint := StrPas(Buffer);
  LoadString(HL,124,Buffer,sizeof(Buffer));
  SpeedButton7.Hint := StrPas(Buffer);
end;

procedure TMainForm.SpeedButton7Click(Sender: TObject);
begin
  VerbOpen.ShowModal;
  if VerbOpen.VFilename.Text <> '' then
    ReaderForm.ShowForm(VerbOpen.VFilename.Text);

end;

procedure TMainForm.CmdParse;
Var CLine : string;
    iPos  : Integer;
begin
  CLine := StrPas(CmdLine);
  iPos := Pos(' ',cLine);
  if iPos = 0 then
    CLine := ''
  else
    Delete(CLine,1,iPos);  
  if CLine <> '' then begin
    if UpperCase(ExtractFileExt(CLine)) = '.THR' then begin
      HREditor.Initialise;
      HREditor.Show;
      HREditor.OpenExistFile(CLine);
      HREditor.BringToFront;
    end;
    if UpperCase(ExtractFileExt(CLine)) = '.THL' then begin
      ReaderForm.ShowForm(CLine);
    end;
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
Var R     : TRegIniFile;
    wRes  : Word;
begin
  if SaveLang.Checked then begin
    try
      R := TRegIniFile.Create('Software\The Hint Library');
      R.WriteString('Optionen','Language',ExtractFileName(LSI_Name));
    finally
      R.Free;
    end;
  end;
end;

procedure TMainForm.Initialize;
Var R        : TRegIniFile;
    sOpt     : string;
    ExePath  : string;
    Button   : integer;
    sNewLang : string;
begin
  try
    R := TRegIniFile.Create('Software\The Hint Library');
    sOpt := R.ReadString('Optionen','Language','deutsch.lsi');
    ExePath := ExtractFilePath(Application.Exename);
    if ExePath[Length(ExePath)]<>'\' then ExePath:=ExePath+'\';
    ExePath:=ExePath+sOpt;
    if FileExists( ExePath ) then
      AdaptLanguage( ExePath )
    else begin
      Button := Application.MessageBox('Language package not found!'+
                                       'Select a different package ?',
                                       'Error', mb_YESNO + mb_DefButton1);
      if Button = IDYES then begin
        sNewLang := LangSel.GetNewLanguage;
        if sNewLang <> '' then begin
          AdaptLanguage(sNewLang);
        end;
      end
      else
        Application.Terminate;
    end;
  finally
    R.Free;
  end;
end;

procedure TMainForm.SaveLangClick(Sender: TObject);
begin
  SaveLang.Checked := not SaveLang.Checked;
end;


end.
