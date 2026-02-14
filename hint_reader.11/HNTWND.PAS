unit hntwnd;

{ LANG TEXT RANGE: 400-402 }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons, Main;

type
  THintWindow = class(TForm)
    BitBtn1: TBitBtn;
    HintMemo: TMemo;
    BitBtn2: TBitBtn;
    HintCombo: TComboBox;
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HintComboChange(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    HintLinks : TList;
    procedure FillComboBox;
    { Private-Deklarationen }
  public
    procedure SetLanguage( HL : THandle );
    procedure ShowForm( OwnerLinks : TList );
    { Public-Deklarationen }
  end;

var
  HintWindow: THintWindow;

implementation

uses reader;

{$R *.DFM}

procedure THintWindow.BitBtn2Click(Sender: TObject);
begin
  Close;
  HintMemo.Color := HintMemo.Font.Color;
  BitBtn2.Enabled := False;
  HintMemo.Lines.Clear;
  HintCombo.Enabled := False;
end;

procedure THintWindow.BitBtn1Click(Sender: TObject);
begin
  HintMemo.Color := clWindow;
  BitBtn2.Enabled := True;
  if HintLinks.Count > 0 then
    HintCombo.Enabled := True;
end;

procedure THintWindow.SetLanguage( HL : THandle );
Var Buffer : array[0..254] of char;
begin
  LoadString(HL,400,Buffer,sizeof(Buffer));
    HintWindow.Caption := StrPas(Buffer);
  LoadString(HL,401,Buffer,sizeof(Buffer));
    BitBtn1.Caption := StrPas(Buffer);
  LoadString(HL,402,Buffer,sizeof(Buffer));
    BitBtn2.Caption := StrPas(Buffer);
end;

procedure THintWindow.FormCreate(Sender: TObject);
begin
  HintMemo.Color := HintMemo.Font.Color;
end;

procedure THintWindow.ShowForm( OwnerLinks : TList );
begin
  HintLinks := OwnerLinks;
  HintMemo.Color := HintMemo.Font.Color;
  BitBtn2.Enabled := False;
  if WindowState <> wsNormal then
    WindowState := wsNormal;
  FillComboBox;
  Show;
end;

procedure THintWindow.FillComboBox;
Var i       : Integer;
    OneNode : TNodeLink;
begin
  HintCombo.Items.Clear;
  if HintLinks.Count > 0 then begin
    for i:=0 to HintLinks.Count-1 do begin
      OneNode := TNodeLink(HintLinks.Items[i]);
      HintCombo.Items.Add(OneNode.sDescription);
    end;
    HintCombo.Enabled := True;
  end
  else
    HintCombo.Enabled := False;  
end;

procedure THintWindow.HintComboChange(Sender: TObject);
Var SelNode : TNodeLink;
begin
  SelNode := TNodeLink(HintLinks.Items[HintCombo.ItemIndex]);
  ReaderForm.ParseLinkRequest(SelNode.iNodeIdx);
end;

procedure THintWindow.FormResize(Sender: TObject);
begin
  if ClientWidth < 478 then ClientWidth := 478;
  if ClientHeight < 214 then ClientHeight := 214;
  BitBtn2.Left := HintWindow.ClientWidth-10-BitBtn2.Width;
  BitBtn2.Top := HintWindow.ClientHeight-10-BitBtn2.Height;
  HintCombo.Top := HintWindow.ClientHeight-10-HintCombo.Height;
  BitBtn1.Left := (HintWindow.ClientWidth-BitBtn1.Width) Div 2;
  HintMemo.Width := ClientWidth-32;
  HintMemo.Height := ClientHeight-HintMemo.Top-20-BitBtn2.Height;
end;

end.
