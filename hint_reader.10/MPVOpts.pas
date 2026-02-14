
unit MPVOpts;

{===============================================================}
{ Optionen für das Testprojekt MPicView für die DMGrafik.dll    }
{ Copyright (C) 1996 Detlef Meister                             }
{								}
               Interface
{								}
{===============================================================}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, Spin;

type
  TJPEGOptsForm = class(TForm)
    Label1                    : TLabel;
    Bevel1                    : TBevel;
    AbbruchButton             : TButton;
    OKButton                  : TButton;
    GroupBox1                 : TGroupBox;
    JPEGInOriginalRadioButton : TRadioButton;
    JPEGIn256RadioButton      : TRadioButton;
    JPEGInGrayRadioButton     : TRadioButton;
    GroupBox2                 : TGroupBox;
    JPEGIn1PassRadioButton    : TRadioButton;
    JPEGIn2PassRadioButton    : TRadioButton;
    GroupBox3                 : TGroupBox;
    JPEGInNoDitherRadioButton : TRadioButton;
    JPEGInOrdDitherRadioButton: TRadioButton;
    JPEGInFSDitherRadioButton : TRadioButton;
    HelpButton                : TButton;
    Label2                    : TLabel;
    GroupBox4                 : TGroupBox;
    JPEGOutQualitySpinEdit    : TSpinEdit;
    Label3                    : TLabel;
    procedure FormActivate(Sender: TObject);
    procedure JPEGInOriginalRadioButtonClick(Sender: TObject);
    procedure JPEGIn256RadioButtonClick(Sender: TObject);
    procedure JPEGInGrayRadioButtonClick(Sender: TObject);
    procedure OKButtonClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  JPEGOptsForm: TJPEGOptsForm;

{===============================================================}
{								}
               Implementation
{								}
{===============================================================}

uses MPVDaten;
{$R *.DFM}


{==============================================	automatische Methoden}

procedure TJPEGOptsForm.FormActivate(Sender: TObject);
begin
  Caption := Application.Title + ' - JPEG-Einstellungen';
  JPEGOutQualitySpinEdit.Value := JPEG_Out_Quality;
  {------------- Dither-Option}
  case JPEG_In_Dither of
       tDit_No   : JPEGInNoDitherRadioButton.Checked  := true;
       tDit_Ord  : JPEGInOrdDitherRadioButton.Checked := true;
       tDit_FS   : JPEGInFSDitherRadioButton.Checked  := true;
  end;
  {------------- Pass-Quantisierung}
  case JPEG_In_2Pass of
       false     : JPEGIn1PassRadioButton.Checked := true;
       true      : JPEGIn2PassRadioButton.Checked := true;
  end;
  {------------- Farbkonvertierung}
  case JPEG_In_OutColors of
       tCol_No   : begin
                     JPEGInOriginalRadioButton.Checked  := true;
                     JPEGInNoDitherRadioButton.Enabled  := false;
                     JPEGInOrdDitherRadioButton.Enabled := false;
                     JPEGInFSDitherRadioButton.Enabled  := false;
                     JPEGIn1PassRadioButton.Enabled     := false;
                     JPEGIn2PassRadioButton.Enabled     := false;
                   end;

       tCol_256  : begin
                     JPEGIn256RadioButton.Checked := true;
                     JPEGInNoDitherRadioButton.Enabled := true;
                     JPEGInOrdDitherRadioButton.Enabled := true;
                     JPEGInFSDitherRadioButton.Enabled := true;
                     JPEGIn1PassRadioButton.Enabled := true;
                     JPEGIn2PassRadioButton.Enabled := true;
                   end;
       tCol_Gray : begin
                     JPEGInGrayRadioButton.Checked := true;
                     JPEGInNoDitherRadioButton.Enabled := false;
                     JPEGInOrdDitherRadioButton.Enabled := false;
                     JPEGInFSDitherRadioButton.Enabled := false;
                     JPEGIn1PassRadioButton.Enabled := false;
                     JPEGIn2PassRadioButton.Enabled := false;
                   end;
  end;

end;

procedure TJPEGOptsForm.JPEGInOriginalRadioButtonClick(Sender: TObject);
begin
  JPEGInNoDitherRadioButton.Enabled := false;
  JPEGInOrdDitherRadioButton.Enabled := false;
  JPEGInFSDitherRadioButton.Enabled := false;
  JPEGIn1PassRadioButton.Enabled := false;
  JPEGIn2PassRadioButton.Enabled := false;
end;

procedure TJPEGOptsForm.JPEGIn256RadioButtonClick(Sender: TObject);
begin
  JPEGInNoDitherRadioButton.Enabled := true;
  JPEGInOrdDitherRadioButton.Enabled := true;
  JPEGInFSDitherRadioButton.Enabled := true;
  JPEGIn1PassRadioButton.Enabled := true;
  JPEGIn2PassRadioButton.Enabled := true;
end;

procedure TJPEGOptsForm.JPEGInGrayRadioButtonClick(Sender: TObject);
begin
  JPEGInNoDitherRadioButton.Enabled := false;
  JPEGInOrdDitherRadioButton.Enabled := false;
  JPEGInFSDitherRadioButton.Enabled := false;
  JPEGIn1PassRadioButton.Enabled := false;
  JPEGIn2PassRadioButton.Enabled := false;
end;

procedure TJPEGOptsForm.OKButtonClick(Sender: TObject);
begin
  JPEG_Out_Quality := JPEGOutQualitySpinEdit.Value;
  {------------- Dither-Option}
  if JPEGInNoDitherRadioButton.Checked
  then JPEG_In_Dither := tDit_No
  else if JPEGInOrdDitherRadioButton.Checked
  then JPEG_In_Dither := tDit_Ord
  else JPEG_In_Dither := tDit_FS;
  {------------- Pass-Quantisierung}
  if JPEGIn1PassRadioButton.Checked
  then JPEG_In_2Pass := false
  else JPEG_In_2Pass := true;
  {------------- Farbkonvertierung}
  if JPEGInOriginalRadioButton.Checked
  then JPEG_In_OutColors := tCol_No
  else if JPEGIn256RadioButton.Checked
  then JPEG_In_OutColors := tCol_256
  else JPEG_In_OutColors := tCol_Gray;
end;

end.
