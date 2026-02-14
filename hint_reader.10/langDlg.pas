unit langDlg;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons;

type
  TLangSel = class(TForm)
    ListBox1: TListBox;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    HiddenList : TstringList;
    sResult    : string;
    { Private-Deklarationen }
  public
    function GetNewLanguage : string;
    procedure SetLAnguage( HL : THandle );
    { Public-Deklarationen }
  end;

var
  LangSel: TLangSel;

implementation

{$R *.DFM}

function TLangSel.GetNewLanguage;
Var SearchRec : TSearchRec;
    FHead     : TextFile;
    sTmp      : string;
    iResult   : Integer;
    sSearchR  : string;
    sSearch   : string;
begin
    HiddenList.Clear;
    ListBox1.Items.Clear;
    sSearchR := ExtractFilePath(Application.Exename);
    if sSearchR[Length(sSearchR)]<>'\' then sSearchR:=sSearchR+'\';
    sSearch:=sSearchR+'*.lsi';
    iResult := FindFirst(sSearch, 0, SearchRec);
    while iResult = 0 do
    begin
      { Header lesen }
      HiddenList.Add(sSearchR+SearchRec.Name);
      try
        AssignFile(FHead,sSearchR+SearchRec.Name);
        Reset(FHead);
        ReadLn(FHead,sTmp);
        ListBox1.Items.Add(sTmp);
      finally
        CloseFile(FHead);
      end;
      iResult := FindNext(SearchRec);
    end;
    FindClose(SearchRec);
    ShowModal;
    GetNewLanguage := sResult;
end;

procedure TLangSel.FormCreate(Sender: TObject);
begin
  HiddenList := TStringList.Create;
end;

procedure TLangSel.FormDestroy(Sender: TObject);
begin
  HiddenList.Free;
end;

procedure TLangSel.BitBtn2Click(Sender: TObject);
begin
  sResult := '';
  Close;
end;

procedure TLangSel.BitBtn1Click(Sender: TObject);
begin
  if ListBox1.ItemIndex >= 0 then
    sResult := HiddenList[ListBox1.ItemIndex]
  else
    sResult := '';
  Close;
end;

procedure TLangSel.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,700,Buffer,sizeof(Buffer));
  LangSel.Caption := StrPas(Buffer);
  LoadString(HL,701,Buffer,sizeof(Buffer));
  LangSel.BitBtn1.Caption := StrPas(Buffer);
  LoadString(HL,702,Buffer,sizeof(Buffer));
  LangSel.BitBtn2.Caption := StrPas(Buffer);
end;

end.
