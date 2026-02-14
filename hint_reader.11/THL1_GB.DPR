library thl1_gb;

{ Wichtiger Hinweis zur DLL-Speicherverwaltung: ShareMem muß die
erste Unit im Uses-Anweisungsteil des Interface-Abschnitts Ihrer
Unit sein, wenn Ihre DLL Prozeduren oder Funktionen exportiert, die
String-Parameter oder Funktionsergebnisse übergeben. Dies gilt für
alle Strings die an und von Ihrer DLL übergeben werden --  selbst
für diese, die in Records oder Klassen verschachtelt sind. ShareMem
ist die Schnittstellen-Unit zur DELPHIMM.DLL, welche Sie mit Ihrer
DLL weitergeben müssen. Um die Verwendung von DELPHIMM.DLL zu
vermeiden, übergeben Sie String-Parameter unter Verwendung von
PChar- oder ShortString-Parametern. }
uses thlif_gb;
begin
end.
