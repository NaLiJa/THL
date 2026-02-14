unit vopen;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, FileCtrl, Main;

type
  TVerbOpen = class(TForm)
    DirectoryListBox1: TDirectoryListBox;
    DriveComboBox1: TDriveComboBox;
    VFilename: TEdit;
    FileLister: TListBox;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    procedure DirectoryListBox1Change(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FileListerClick(Sender: TObject);
    procedure FileListerDblClick(Sender: TObject);
  private
    HiddenList : TStringList;
    { Private-Deklarationen }
  public
    procedure SetLanguage( HL : Thandle );
    { Public-Deklarationen }
  end;

var
  VerbOpen: TVerbOpen;

implementation

uses Reader;
{$R *.DFM}

procedure TVerbOpen.DirectoryListBox1Change(Sender: TObject);
Var SearchRec : TSearchRec;
    FHead     : TextFile;
    sTmp      : string;
    Result    : Integer;
    sSearchR  : string;
    sSearch   : string;
begin
    HiddenList.Clear;
    FileLister.Items.Clear;
    sSearchR := sSearch+DirectoryListBox1.Directory;
    if sSearchR[Length(sSearchR)]<>'\' then sSearchR:=sSearchR+'\';
    sSearch:=sSearchR+'*.thl';
    Result := FindFirst(sSearch, 0, SearchRec);
    while Result = 0 do
    begin
      { Header lesen }
      HiddenList.Add(sSearchR+SearchRec.Name);
      try
        AssignFile(FHead,sSearchR+SearchRec.Name);
        Reset(FHead);
        { Version }
        ReadLn(FHead,sTmp);
        { Titel }
        ReadLn(FHead,sTmp);
        FileLister.Items.Add(ReaderForm.DecodeLine(sTmp,'THL'));
      finally
        CloseFile(FHead);
      end;
      Result := FindNext(SearchRec);
    end;
    FindClose(SearchRec);
end;

procedure TVerbOpen.BitBtn1Click(Sender: TObject);
begin
  Close;
end;

procedure TVerbOpen.BitBtn2Click(Sender: TObject);
begin
  VFilename.Text := '';
  Close;
end;

procedure TVerbOpen.FormCreate(Sender: TObject);
begin
  HiddenList := TStringList.Create;
end;

procedure TVerbOpen.FormDestroy(Sender: TObject);
begin
  HiddenList.Free;
end;

procedure TVerbOpen.FormActivate(Sender: TObject);
begin
  DirectoryListBox1Change(Sender);
end;

procedure TVerbOpen.FileListerClick(Sender: TObject);
begin
  VFilename.Text := HiddenList[FileLister.ItemIndex];
end;

procedure TVerbOpen.FileListerDblClick(Sender: TObject);
begin
  VFilename.Text := HiddenList[FileLister.ItemIndex];
  Close;
end;

procedure TVerbOpen.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,150,Buffer,sizeof(Buffer));
  VerbOpen.Caption := StrPas(Buffer);
  LoadString(HL,151,Buffer,sizeof(Buffer));
  BitBtn2.Caption := StrPas(Buffer);
  LoadString(HL,152,Buffer,sizeof(Buffer));
  BitBtn1.Caption := StrPas(Buffer);
end;

end.
