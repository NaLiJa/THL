unit VText;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Buttons;

type TVTextFile = class(TObject)
     private
       vtFile : file;
     public
       procedure VOpenFileWrite( Filename : string );
       procedure VOpenFileRead( Filename : string );
       procedure VCloseFile;
       procedure VWriteLn( Line : string );
       procedure VReadLn( Var st : string );
     end;

implementation

procedure TVTextFile.VOpenFileWrite( Filename : string );
begin
  AssignFile( vtFile, Filename );
  Rewrite(vtFile);
end;

procedure TVTextFile.VOpenFileRead( Filename : string );
begin
  AssignFile( vtFile, Filename );
  Reset(vtFile,1);
end;

procedure TVTextFile.VCloseFile;
begin
  CloseFile( vtFile );
end;

procedure TVTextFile.VWriteLn( Line : string );
Var Buffer          : array[0..256] of char;
    i,
    NumWritten      : Integer;
begin
  i := 0;
  for i:=1 to Length(Line) do
    Buffer[i-1]:= Line[i];
  Buffer[i] := chr(13);
  Buffer[i+1] := chr(10);
  BlockWrite(vtFile,Buffer,Length(Line)+2,NumWritten);
end;

procedure TVTextFile.VReadLn( Var st : string );
begin
end;

end.
