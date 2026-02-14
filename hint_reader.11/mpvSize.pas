
unit Mpvsize;

{===============================================================}
{ Größenänderungen, Testprojekt MPicView für die DMGrafik.dll   }
{ Copyright (C) 1996 Detlef Meister                             }
{								}
               Interface
{								}
{===============================================================}

uses WinTypes, WinProcs, Classes, Graphics, Forms, Controls, Buttons,
  StdCtrls, ExtCtrls, Spin;

type
  TSizeEinstellForm = class(TForm)
    HelpBtn                       : TBitBtn;
    Bevel1                        : TBevel;
    VerzerrungCheckBox            : TCheckBox;
    BreiteSpinEdit                : TSpinEdit;
    HoeheSpinEdit                 : TSpinEdit;
    Label1                        : TLabel;
    Label2                        : TLabel;
    Label3                        : TLabel;
    CancelButton                  : TButton;
    OKButton                      : TButton;
    procedure FormActivate(Sender: TObject);
    procedure HoeheSpinEditExit(Sender: TObject);
    procedure BreiteSpinEditExit(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
  private
    { Private declarations }
    function  GetMass(o1, z1, z2: longint): word;
  public
    { Public declarations }
  end;

var
  SizeEinstellForm: TSizeEinstellForm;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses MPVdaten;

{$R *.DFM}

{==============================================	private Methoden}

{----------------------------------------------	GetMass}
function TSizeEinstellForm.GetMass(o1, z1, z2: longint): word;
var
Faktor          : single;
begin
  {------------- Faktor = gewünschte Zielgröße * 100 / Quellgröße}
  Faktor := 100 * z1 / o1;
  {------------- Bildmaß berechnen: Zielgröße = Quellgröße * Faktor / 100}
  Result := round(z2 * Faktor / 100);
end {function TSizeEinstellForm.GetMass};

{==============================================	autonatische Methoden}

procedure TSizeEinstellForm.FormActivate(Sender: TObject);
begin
  {------------- Titel}
  Caption := Application.Title + ' - neue Bildmaße';
  {------------- Schalter und Werte setzen}
  if SizeVerzerr
  then VerzerrungCheckBox.Checked := true
  else VerzerrungCheckBox.Checked := false;
  BreiteSpinEdit.Value := SizeBreite;
  HoeheSpinEdit.Value  := SizeHoehe;
  {------------- Sizingfaktoren berechnen}
  if not(SizeVerzerr)
  then SizeHoehe := GetMass(MemWid, SizeBreite, MemHei);
  {------------- Arbeitserleichterung}
  BreiteSpinEdit.SetFocus;
end;

procedure TSizeEinstellForm.HoeheSpinEditExit(Sender: TObject);
begin
  {------------- Sizingfaktoren berechnen}
  if not(VerzerrungCheckBox.Checked)
  then BreiteSpinEdit.Value := GetMass(MemHei, HoeheSpinEdit.Value, MemWid);
end;

procedure TSizeEinstellForm.BreiteSpinEditExit(Sender: TObject);
begin
  {------------- Sizingfaktoren berechnen}
  if not(VerzerrungCheckBox.Checked)
  then HoeheSpinEdit.Value := GetMass(MemWid, BreiteSpinEdit.Value, MemHei);
end;

procedure TSizeEinstellForm.OKButtonClick(Sender: TObject);
begin
  if VerzerrungCheckBox.Checked then SizeVerzerr := true else SizeVerzerr := false;
  SizeBreite := BreiteSpinEdit.Value;
  SizeHoehe  := HoeheSpinEdit.Value;
end;

end.
