; Contract or any document e-sign check

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

; Some global variables: name of the GPG executable, temporary and settings directory
CompilerIf #PB_Compiler_OS = #PB_OS_Linux
  Global prog$ = "gpg"
CompilerElse
  Global prog$ = "gpgbin"+#PS$+"gpg"
CompilerEndIf

Global prefdir$ = ".edm"
Global tempdir$ = GetTemporaryDirectory() + "cdsign"

IncludeFile "cdsign-check-form.pbf"
IncludeFile "cdsign-check-procedures.pb"

LoadSettings()
OpenMain_Window()
DisableGadget(View_CD, #True)  ; disable show signed document button

Repeat
  Event = WaitWindowEvent()
  
  Select Event
    Case #PB_Event_Gadget
      Select EventGadget()
          
          
        ; Select document file
        Case File_CD
          If EventType() = #PB_EventType_LeftClick
            filetk$ = OpenFileRequester("Select a document file", DefaultFile$, "All files|*.*|Documents (Word, PDF, txt)|*.doc;*.docx;*.odt;*.pdf;*.txt", 0)
            SetGadgetText(String_Contract, filetk$)
            If filetk$ = ""
              DisableGadget(View_CD, #True)  ; disable show signed document button
            EndIf
          EndIf
          
          
        ; Select DS file
        Case File_DS
          If EventType() = #PB_EventType_LeftClick
            fileds$ = OpenFileRequester("Select a digital signature file", DefaultFile$, "All files|*.*|DS files (asc, sig)|*.asc;*.sig", 0)
            SetGadgetText(String_Signature, fileds$)
          EndIf
          
          
        ; Select key file
        Case Key_Import
          If EventType() = #PB_EventType_LeftClick
            filepubkey$ = OpenFileRequester("Select a key file", DefaultFile$, "All files|*.*|Key files (key)|*.key", 0)
            SetGadgetText(String_Key, filepubkey$)
          EndIf
          
          
        ; Check DS
        Case Check_DS
          
          If EventType() = #PB_EventType_LeftClick
            Output$ = ""
            GPGKey$ = ""
            curdir$ = GetCurrentDirectory()
            
            ; Key import code
            If filepubkey$
              If ReadFile(0, filepubkey$)
                While Eof(0) = 0
                  GPGKey$ = GPGKey$ + ReadString(0) + #LF$
                Wend
                CloseFile(0)
              EndIf
              ; Run GPG
              params$ = "--charset utf8 --import --batch"
              exegpg = RunProgram(prog$, params$, curdir$, #PB_Program_Hide | #PB_Program_Open | #PB_Program_Read | #PB_Program_Write | #PB_Program_Error | #PB_Program_UTF8)
              If exegpg
                WriteProgramString(exegpg, GPGKey$, #PB_UTF8)
                WriteProgramData(exegpg, #PB_Program_Eof, 1024)
                While ProgramRunning(exegpg)
                  If AvailableProgramOutput(exegpg)
                    Output$ = Output$ + ReadProgramString(exegpg, #PB_UTF8) + #CRLF$
                  EndIf
                Wend
                ; GPG outputs to stderr, read from stderr
                t$ = ReadProgramError(exegpg, #PB_UTF8)
                While t$
                  Output$ + t$ + #CRLF$
                  t$ = ReadProgramError(exegpg, #PB_UTF8)
                Wend
                CloseProgram(exegpg)
                SetGadgetText(Result_Text, Output$)
              EndIf
            EndIf
            ; End of key import code
            
            ; Check DS code
            ; Create temp subdirectory in temp directory
            ; Temp subdirectory required because of encoding problems in some OSes (e.g. Windows)
            If FileSize(tempdir$) = -2 : DeleteDirectory(tempdir$, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force) : EndIf
            If CreateDirectory(tempdir$)
              tempfiletk$ = tempdir$ + #PS$ + "esign-check-tk"
              tempfileds$ = tempdir$ + #PS$ + "esign-check-ds"
              If CopyFile(filetk$, tempfiletk$) And CopyFile(fileds$, tempfileds$)
                Output$ = Output$ + "Ready to DS check" + #CRLF$
              Else
                tempfiletk$ = filetk$
                tempfileds$ = fileds$
                Output$ = Output$ + "Not all required files selected or ready" + #CRLF$
              EndIf
            Else
              Output$ = Output$ + "Error writing to temporary directory" + #CRLF$
            EndIf
            ; Run GPG
            params$ = "--charset utf8 --verify " +  #DQUOTE$ + tempfileds$ + #DQUOTE$ + " " + #DQUOTE$ + tempfiletk$ + #DQUOTE$
            exegpg = RunProgram(prog$, params$, curdir$, #PB_Program_Hide | #PB_Program_Open | #PB_Program_Read | #PB_Program_Write | #PB_Program_Error | #PB_Program_UTF8)
            If exegpg
              While ProgramRunning(exegpg)
                If AvailableProgramOutput(exegpg)
                  Output$ = Output$ + ReadProgramString(exegpg, #PB_UTF8) + #CRLF$
                EndIf
              Wend
              ; GPG outputs to stderr, read from stderr
              t$ = ReadProgramError(exegpg, #PB_UTF8)
              While t$
                Output$ + t$ + #CRLF$
                t$ = ReadProgramError(exegpg, #PB_UTF8)
              Wend
              CloseProgram(exegpg)
              SetGadgetText(Result_Text, Output$)
              goodocur = CountString(Output$, "Good signature") + CountString(Output$, "Действительная подпись") + CountString(Output$, "Хорошая подпись")
              badocur = CountString(Output$, "BAD signature") + CountString(Output$, "ПЛОХАЯ подпись")
              nokey = CountString(Output$, "No public key") + CountString(Output$, "Нет открытого ключа")
              ; nosign = CountString(Output$, "the signature could not be verified") + CountString(Output$, "Не могу проверить подпись")
              If goodocur > 0
                DisableGadget(View_CD, #False) ; enable show signed document button
              Else
                DisableGadget(View_CD, #True)  ; disable show signed document button
              EndIf
              ; Find key creation date and expiration term in key packets data
              If goodocur > 0 Or badocur > 0
                keyid$ = GetSigID(Output$)
                params$ = "--charset utf8 -a --export --batch " + keyid$
                exegpg = RunProgram(prog$, params$, curdir$, #PB_Program_Hide | #PB_Program_Open | #PB_Program_Read | #PB_Program_Write | #PB_Program_Error | #PB_Program_UTF8)
                If exegpg
                  While ProgramRunning(exegpg)
                    If AvailableProgramOutput(exegpg)
                      keytolistpackets$ = keytolistpackets$ + ReadProgramString(exegpg, #PB_UTF8) + #LF$
                    EndIf
                  Wend
                EndIf
                params$ = "--charset utf8 --list-packets --batch"
                exegpg = RunProgram(prog$, params$, curdir$, #PB_Program_Hide | #PB_Program_Open | #PB_Program_Read | #PB_Program_Write | #PB_Program_Error | #PB_Program_UTF8)
                If exegpg
                  WriteProgramString(exegpg, keytolistpackets$, #PB_UTF8)
                  WriteProgramData(exegpg, #PB_Program_Eof, 1024)
                  While ProgramRunning(exegpg)
                    If AvailableProgramOutput(exegpg)
                      keypackets$ = keypackets$ + ReadProgramString(exegpg, #PB_UTF8) + #CRLF$
                    EndIf
                  Wend
                  t$ = ReadProgramError(exegpg, #PB_UTF8)
                  While t$
                    Output$ + t$ + #CRLF$
                    t$ = ReadProgramError(exegpg, #PB_UTF8)
                  Wend
                EndIf
                keydates$ = GetKeyDates(keypackets$)
                Output$ = Output$ + keydates$ + #CRLF$
                SetGadgetText(Result_Text, Output$)
                Output$ = Output$ + "Run finished"
              EndIf
              ; Change result fields
              If goodocur > 0
                SetGadgetText(Result_Bool, "SIGNATURE VALID")
                SetGadgetColor(Result_Bool, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                SetGadgetColor(Result_Bool, #PB_Gadget_BackColor, RGB(0, 255, 0))
              ElseIf badocur > 0
                SetGadgetText(Result_Bool, "SIGNATURE INVALID")
                SetGadgetColor(Result_Bool, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                SetGadgetColor(Result_Bool, #PB_Gadget_BackColor, RGB(255, 0, 0))
              ElseIf nokey > 0
                SetGadgetText(Result_Bool, "NO PUBLIC KEY")
                SetGadgetColor(Result_Bool, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                SetGadgetColor(Result_Bool, #PB_Gadget_BackColor, RGB(255, 0, 0))
              Else
                SetGadgetText(Result_Bool, "CANNOT VERIFY SIGNATURE")
                SetGadgetColor(Result_Bool, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                SetGadgetColor(Result_Bool, #PB_Gadget_BackColor, RGB(255, 0, 0))
              EndIf
            EndIf
            ; Delete temporary files and subdirectory
            If DeleteDirectory(tempdir$, "", #PB_FileSystem_Recursive | #PB_FileSystem_Force)
              Output$ = Output$ + #CRLF$ + "Temp directory removed"
            Else
              Output$ = Output$ + #CRLF$ + "Error writing to temporary directory" + #CRLF$
              SetGadgetText(Result_Text, Output$)
            EndIf
            ; Check DS code end
            
          EndIf
          
        ; Additional buttons
        ; Open a file to sign
        Case View_CD
          If filetk$ And EventType() = #PB_EventType_LeftClick
            ShellOpen(filetk$)
          EndIf
        ; Open help
        Case Button_Help
          If EventType() = #PB_EventType_LeftClick
            ShellOpen("docs"+#PS$+"help-check.html")
          EndIf
        ; Open README
        Case Button_About
          If EventType() = #PB_EventType_LeftClick
            ShellOpen("docs"+#PS$+"README-check.txt")
          EndIf
          
          
      EndSelect
  EndSelect
  
Until Event = #PB_Event_CloseWindow

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 61
; Folding = -
; EnableXP