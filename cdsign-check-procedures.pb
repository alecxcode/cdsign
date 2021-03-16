; Copyright (C) 2021  Alexander Vankov
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.

; Load application settings
; The settings are: name of the GPG executable
Procedure LoadSettings()
  
  If FileSize(GetHomeDirectory()+prefdir$) = -1
    res = CreateDirectory(GetHomeDirectory()+prefdir$)
    If res = 0 : MessageRequester("Error", "Error writing to the user home directory") : EndIf
  EndIf
  
  If OpenPreferences(GetHomeDirectory()+prefdir$+#PS$+"cdsign-check.ini")
    prog$ = ReadPreferenceString("prog", prog$)
  Else
    CreatePreferences(GetHomeDirectory()+prefdir$+#PS$+"cdsign-check.ini")
    WritePreferenceString("prog", prog$)
  EndIf
  ClosePreferences()

EndProcedure

; Open a file or URL
Procedure ShellOpen(addr$)
  
  curdir$ = GetCurrentDirectory()
  CompilerSelect #PB_Compiler_OS
    CompilerCase #PB_OS_Linux
      RunProgram("xdg-open", addr$, curdir$)
    CompilerCase #PB_OS_MacOS
      RunProgram("open", addr$, curdir$)
    CompilerCase #PB_OS_Windows
      RunProgram(addr$, "", curdir$)
  CompilerEndSelect             

EndProcedure

; Find key id key data
Procedure.s GetSigID(gpgdata$)
  
  keyid$ = "No key found"
  Dim Result$(0)
  regexpr = 0
  ; Find key ID with regular expression
  If CreateRegularExpression(regexpr, "( key| с идентификатором) [0-9A-Z]+")
    nbfound = ExtractRegularExpression(regexpr, gpgdata$, Result$())
    If nbfound
      keyid$ = ReplaceString(Result$(0), " key", "")
      keyid$ = ReplaceString(keyid$, " с идентификатором", "")
      keyid$ = Trim(keyid$)
    EndIf
  EndIf
  FreeRegularExpression(regexpr)
  FreeArray(Result$())
  ProcedureReturn keyid$

EndProcedure

; Find key creation date and expiration term in key packets data
Procedure.s GetKeyDates(packetsdata$)
  
  keydates$ = "No dates found"
  Dim ResultCreated$(0)
  Dim ResultExpires$(0)
  regexpr = 0
  ; Find key creation date with regular expression
  If CreateRegularExpression(regexpr, "\(sig created .+\)")
    nbfound = ExtractRegularExpression(regexpr, packetsdata$, ResultCreated$())
    If nbfound
      created$ = ReplaceString(ResultCreated$(0), "(sig created", "")
      created$ = ReplaceString(created$, ")", "")
      created$ = Trim(created$)
    EndIf
  EndIf
  FreeRegularExpression(regexpr)
  ; Find key expiration term with regular expression
  If CreateRegularExpression(regexpr, "\(key expires after .+\)")
    nbfound = ExtractRegularExpression(regexpr, packetsdata$, ResultExpires$())
    If nbfound
      expires$ = ReplaceString(ResultExpires$(0), "(key expires after", "")
      expires$ = ReplaceString(expires$, ")", "")
      expires$ = Trim(expires$)
    Else
      expires$ = "permanent"
    EndIf
  EndIf
  FreeRegularExpression(regexpr)
  FreeArray(ResultCreated$())
  FreeArray(ResultExpires$())
  keydates$ = "DS key duration:" + #CRLF$ + "created: " + created$+ " expires after: " + expires$
  ProcedureReturn keydates$

EndProcedure

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 18
; Folding = -
; EnableXP