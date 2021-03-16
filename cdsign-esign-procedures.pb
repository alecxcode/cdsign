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
; The settings are:  name of the GPG executable, and the last genarated key ID
Procedure LoadSettings()
    
  If FileSize(GetHomeDirectory()+prefdir$) = -1
    res = CreateDirectory(GetHomeDirectory()+prefdir$)
    If res = 0 : MessageRequester("Error", "Error writing to the user home directory") : EndIf
  EndIf
  
  If OpenPreferences(GetHomeDirectory()+prefdir$+#PS$+"cdsign-esign.ini")
    prog$ = ReadPreferenceString("prog", prog$)
    keyid$ = ReadPreferenceString("keyid", keyid$)
    ;MessageRequester("Info", prog$+";"+keyid$)
  Else
    CreatePreferences(GetHomeDirectory()+prefdir$+#PS$+"cdsign-esign.ini")
    ;MessageRequester("Info", Str(res))
    WritePreferenceString("prog", prog$)
    WritePreferenceString("keyid", keyid$)
  EndIf
  ClosePreferences()

EndProcedure

; Save the last ganarated key ID
Procedure SaveKeyID()
  If OpenPreferences(GetHomeDirectory()+prefdir$+#PS$+"cdsign-esign.ini")
    WritePreferenceString("keyid", keyid$)
    ClosePreferences()
  Else
    MessageRequester("Error", "Error saving key ID")
  EndIf
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

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 10
; Folding = -
; EnableXP