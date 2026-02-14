unit InfoWnd;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Main;

type
  TInfoWindow = class(TForm)
    InfoMemo: TMemo;
    InfoCombo: TComboBox;
    procedure InfoComboChange(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    InfoLinks : TList;
    procedure FillComboBox;
    { Private-Deklarationen }
  public
    procedure ShowForm( OwnerLinks : TList );
    { Public-Deklarationen }
  end;

var
  InfoWindow: TInfoWindow;

implementation

uses reader;

{$R *.DFM}

procedure TInfoWindow.ShowForm( OwnerLinks : TList );
begin
  InfoLinks := OwnerLinks;
  if WindowState <> wsNormal then
    WindowState := wsNormal;
  FillComboBox;
  Show;
end;

procedure TInfoWindow.FillComboBox;
Var i       : Integer;
    OneNode : TNodeLink;
begin
  InfoCombo.Items.Clear;
  if InfoLinks.Count > 0 then begin
    for i:=0 to InfoLinks.Count-1 do begin
      OneNode := TNodeLink(InfoLinks.Items[i]);
      InfoCombo.Items.Add(OneNode.sDescription);
    end;
    InfoCombo.Enabled := True;
  end
  else
    InfoCombo.Enabled := False;
end;

procedure TInfoWindow.InfoComboChange(Sender: TObject);
Var SelNode : TNodeLink;
begin
  SelNode := TNodeLink(InfoLinks.Items[InfoCombo.ItemIndex]);
  ReaderForm.ParseLinkRequest(SelNode.iNodeIdx);
end;

procedure TInfoWindow.FormResize(Sender: TObject);
begin
  InfoMemo.Width := InfoWindow.ClientWidth;
  InfoMemo.height := InfoWindow.ClientHeight-10-InfoCombo.Height;
  InfoCombo.Top := InfoWindow.ClientHeight-5-InfoCombo.Height;
end;

end.
