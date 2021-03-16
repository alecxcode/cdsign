; Contract or any document e-sign

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

; Some global variables: name of the GPG executable, keyid and settings directory
CompilerIf #PB_Compiler_OS = #PB_OS_Linux
  Global prog$ = "gpg"
CompilerElse
  Global prog$ = "gpgbin"+#PS$+"gpg"
CompilerEndIf

Global keyid$ = "nokey"
Global prefdir$ = ".edm"

IncludeFile "cdsign-esign-form.pbf"
IncludeFile "cdsign-esign-make.pbf"
IncludeFile "cdsign-esign-progress.pbf"
IncludeFile "cdsign-esign-procedures.pb"

LoadSettings()

OpenMain_Window()
DisableGadget(View_CD, #True)  ; disable view the file to sign button
DisableGadget(Sign_CD, #True)  ; disable sign button

If keyid$ = "" Or keyid$ = "nokey"
  SetGadgetText(Result_Text, "Key ID not found in the settings " + #CRLF$ + "Creation of DS keys required")
  keypresent = #False
Else
  SetGadgetText(Result_Text, "Your last generated key ID: " + keyid$ + #CRLF$ + "You can sign files")
  keypresent = #True
EndIf

; Main loop
Repeat
  Event = WaitWindowEvent()
  
  Select Event

    ; Close Create DS window by system close button   
    Case #PB_Event_CloseWindow
      If EventWindow() = MakeDS_Window
        CloseWindow(MakeDS_Window)
        HideWindow(Main_Window, #False)
      EndIf

    ; Events handling
    Case #PB_Event_Gadget
      Select EventGadget()
          
        ; Button to load the document to sign
        Case File_CD
          If EventType() = #PB_EventType_LeftClick
            filetk$ = OpenFileRequester("Select a document file", "", "All files|*.*|Documents (Word, PDF, txt)|*.doc;*.docx;*.odt;*.pdf;*.txt", 0)
            SetGadgetText(String_Contract, filetk$)
            If filetk$ = ""
              DisableGadget(View_CD, #True) ; disable view the file to sign button
              DisableGadget(Sign_CD, #True) ; disable sign button
            ElseIf keypresent
              DisableGadget(View_CD, #False) ; enable view the file to sign button
              DisableGadget(Sign_CD, #False) ; enable sign button
            EndIf
          EndIf
          
          
        ; Open Create DS window
        Case Make_DS
          If EventType() = #PB_EventType_LeftClick
            If keyid$ = "" Or keyid$ = "nokey"
              OpenMakeDS_Window()
              HideWindow(Main_Window, #True)
            Else
              confirmmakeDS = MessageRequester("Confirm to open DS creation window", "DS keys was already created before. " + #CRLF$ + "Normally you don't have to create them again. " + #CRLF$ + "Continue anyway?", #PB_MessageRequester_YesNo)
              If confirmmakeDS = #PB_MessageRequester_Yes
                OpenMakeDS_Window()
                HideWindow(Main_Window, #True)
              EndIf
            EndIf
          EndIf
          
          
        ; Quit Create DS window by Cancel button
        Case Button_Cancel
          If EventType() = #PB_EventType_LeftClick
            CloseWindow(MakeDS_Window)
            HideWindow(Main_Window, #False)
          EndIf
          
          
        ; Create DS keys
        Case Button_Make
          If EventType() = #PB_EventType_LeftClick
            FullName$ = GetGadgetText(String_Name)
            email$ = GetGadgetText(String_email)
            Job$ = GetGadgetText(String_Job)
            Company$ = GetGadgetText(String_Company)
            Some_ID$ = GetGadgetText(String_ID)
            Anyother$ = GetGadgetText(String_Add)
            If Not Job$ = ""
              Job$ = ";Job:" + Job$
            EndIf
            If Not Company$ = ""
              Company$ = ";Company:" + Company$
            EndIf
            If Not Some_ID$ = ""
              Some_ID$ = ";ID:" + Some_ID$
            EndIf
            If Not Anyother$ = ""
              Anyother$ = ";Add.info:" + Anyother$
            EndIf
            AddData$ = LTrim(Job$ + Company$ + Some_ID$ + Anyother$, ";")
            ; Close Create DS keys window, show progress window
            CloseWindow(MakeDS_Window)
            OpenProgress_Window()
            SetGadgetState(Progress_DS, 90)
            ; Run GPG
            Output$ = "" 
            curdir$ = GetCurrentDirectory()  
            params$ = "--charset utf-8 --full-generate-key --batch"
            exegpg = RunProgram(prog$, params$, curdir$, #PB_Program_Hide | #PB_Program_Open | #PB_Program_Read | #PB_Program_Write | #PB_Program_Error | #PB_Program_UTF8)
            If exegpg
              WriteProgramStringN(exegpg, "%echo Creating DS keys", #PB_UTF8)
              WriteProgramStringN(exegpg, "%no-protection", #PB_UTF8)
              WriteProgramStringN(exegpg, "Key-Type: RSA", #PB_UTF8)
              WriteProgramStringN(exegpg, "Key-Length: 3072", #PB_UTF8)
              WriteProgramStringN(exegpg, "Subkey-Type: RSA", #PB_UTF8)
              WriteProgramStringN(exegpg, "Subkey-Length: 3072", #PB_UTF8)
              WriteProgramStringN(exegpg, "Name-Real: " + FullName$, #PB_UTF8)
              WriteProgramStringN(exegpg, "Name-Comment: " + AddData$, #PB_UTF8)
              WriteProgramStringN(exegpg, "Name-Email: " + email$, #PB_UTF8)
              WriteProgramStringN(exegpg, "Expire-Date: 0", #PB_UTF8)
              WriteProgramStringN(exegpg, "%commit", #PB_UTF8)
              WriteProgramStringN(exegpg, "%echo Creation finished", #PB_UTF8)
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
              Output$ = Output$ + "Run finished"
              CloseProgram(exegpg)
              ; Changre result fields
              SetGadgetText(Result_Text, Output$)
              goodcrea = CountString(Output$, "public and secret key created and signed") + CountString(Output$, "открытый и секретный ключи созданы и подписаны")
              goodocur = CountString(Output$, "marked as ultimately trusted") + CountString(Output$, "помечен как абсолютно доверенный")
              noargs = CountString(Output$, "missing argument") + CountString(Output$, "no User-ID specified")
              If goodcrea > 0
                keypresent = #True
                SetGadgetText(Result_Bool, "DS KEYS CREATED")
                SetGadgetColor(Result_Bool, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                SetGadgetColor(Result_Bool, #PB_Gadget_BackColor, RGB(0, 255, 0))
              ElseIf goodocur > 0
                keypresent = #True
                SetGadgetText(Result_Bool, "DS KEYS CREATED")
                SetGadgetColor(Result_Bool, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                SetGadgetColor(Result_Bool, #PB_Gadget_BackColor, RGB(0, 255, 0))
              ElseIf noargs > 0
                SetGadgetText(Result_Bool, "MISSING PARAMETERS FOR DS KEYS")
                SetGadgetColor(Result_Bool, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                SetGadgetColor(Result_Bool, #PB_Gadget_BackColor, RGB(255, 0, 0))
              Else
                SetGadgetText(Result_Bool, "UNABLE TO CREATE DS KEYS:" + #CRLF$ + "Unknown error")
                SetGadgetColor(Result_Bool, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                SetGadgetColor(Result_Bool, #PB_Gadget_BackColor, RGB(255, 0, 0))
              EndIf
              ; Find a key ads save data about it to the settings
              If goodcrea Or goodocur
                Dim Result$(0)
                regexpr = 0
                ; Here we find key ID with regular expression in order to save and use it later
                If CreateRegularExpression(regexpr, "(key|ключ) [0-9A-Z]+ ")
                  nbfound = ExtractRegularExpression(regexpr, Output$, Result$())
                  keyid$ = Trim(ReplaceString(ReplaceString(Result$(0), "key", ""), "ключ", ""))
                  SetGadgetText(Result_Bool, "DS KEYS CREATED" + #CRLF$ + "Key: " + keyid$)
                  SaveKeyID() ; this saves key ID to the settings file
                EndIf
                FreeRegularExpression(regexpr)
                FreeArray(Result$())
              EndIf
            EndIf
            ; Show main window, close progress window
            HideWindow(Main_Window, #False)
            CloseWindow(Progress_Window)
            ; Activate sign button if a file is already selected
            If keypresent And Not filetk$ = ""
              DisableGadget(View_CD, #False) ; enable view the file to sign button
              DisableGadget(Sign_CD, #False) ; enable sign button
            EndIf
          EndIf
          
          
        ; Sign a file with DS
        Case Sign_CD
          If EventType() = #PB_EventType_LeftClick
            If filetk$
              writeerror = 0
              goodsign = 0
              ; Readeing a file to sign into a buffer
              Output$ = "" 
              curdir$ = GetCurrentDirectory()
              params$ = "--charset utf-8 -ba --yes --default-key " + keyid$ + " --batch"            
              If filetk$
                If ReadFile(0, filetk$)
                  length = Lof(0)                           ; get the length of opened file
                  *MemoryF = AllocateMemory(length)         ; allocate the needed memory
                  If *MemoryF
                    bytes = ReadData(0, *MemoryF, length)   ; read opened file into the memory
                  EndIf
                  CloseFile(0)
                EndIf
              EndIf
              ; Run GPG
              exegpg = RunProgram(prog$, params$, curdir$, #PB_Program_Hide | #PB_Program_Open | #PB_Program_Read | #PB_Program_Write | #PB_Program_Error | #PB_Program_UTF8)
              If exegpg And bytes
                WriteProgramData(exegpg, *MemoryF, bytes)
                WriteProgramData(exegpg, #PB_Program_Eof, 1024)
                While ProgramRunning(exegpg)
                  If AvailableProgramOutput(exegpg)
                    Output$ = Output$ + ReadProgramString(exegpg, #PB_UTF8) + #CRLF$
                  EndIf
                Wend
                ; Writing a file and a signature
                If CountString(Output$, "END PGP SIGNATURE")
                  goodsign = 1 ; later used for Result_Bool_Sign indicator
                  sigfile$ = filetk$ + ".asc"
                  If CreateFile(1, sigfile$)
                    WriteString(1, Output$, #PB_UTF8)
                    CloseFile(1)
                    Output$ = ""
                  Else
                    writeerror = 1 ; later used for Result_Bool_Sign indicator
                  EndIf
                EndIf
                ; GPG outputs to stderr, read from stderr
                t$ = ReadProgramError(exegpg, #PB_UTF8)
                While t$
                  Output$ + t$ + #CRLF$
                  t$ = ReadProgramError(exegpg, #PB_UTF8)
                Wend
                CloseProgram(exegpg)
                Output$ = Output$ + "Signing a file with DS: " + GetFilePart(filetk$) + #CRLF$
                Output$ = Output$ + "Run finished" + #CRLF$ + "In case of successful signing the signature file can be found in a directory with signed file"
                ; Changre result fields
                SetGadgetText(Result_Text, Output$)
                If goodsign = 1
                  SetGadgetText(Result_Bool_Sign, "SIGN COMPLETED")
                  SetGadgetColor(Result_Bool_Sign, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                  SetGadgetColor(Result_Bool_Sign, #PB_Gadget_BackColor, RGB(0, 255, 0))
                Else
                  SetGadgetText(Result_Bool_Sign, "ERROR SIGNING")
                  SetGadgetColor(Result_Bool_Sign, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                  SetGadgetColor(Result_Bool_Sign, #PB_Gadget_BackColor, RGB(255, 0, 0))
                EndIf
                If writeerror = 1
                  SetGadgetText(Result_Bool_Sign, "ERROR WRITING FILE")
                  SetGadgetColor(Result_Bool_Sign, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                  SetGadgetColor(Result_Bool_Sign, #PB_Gadget_BackColor, RGB(255, 0, 0))
                EndIf
              EndIf
            EndIf
          EndIf
          
          
        ; Export of the public key
        Case Key_Export
          If EventType() = #PB_EventType_LeftClick   
            readytowrite = 0
            writeerror = 0
            goodexport = 0
            curuser$ = UserName()
            Output$ = "" 
            curdir$ = GetCurrentDirectory()
            params$ = "--export --yes -a " + keyid$
            pubkey$ = SaveFileRequester("Save public key file", curuser$, "DS keys|*.key|All files|*.*|", 0)
            If pubkey$
              fname$ = GetFilePart(pubkey$, #PB_FileSystem_NoExtension)
              fpath$ = GetPathPart(pubkey$)
              pubkey$ = fpath$ + fname$ + ".key" ; always saves with extension *.key
              readytowrite = 1
            EndIf
            ; Run GPG
            If readytowrite = 1
              exegpg = RunProgram(prog$, params$, curdir$, #PB_Program_Hide | #PB_Program_Open | #PB_Program_Read | #PB_Program_Error | #PB_Program_UTF8)
              If exegpg
                While ProgramRunning(exegpg)
                  If AvailableProgramOutput(exegpg)
                    Output$ = Output$ + ReadProgramString(exegpg, #PB_UTF8) + #LF$
                  EndIf
                Wend
                ; Check if the string have key ending wording
                If CountString(Output$, "END PGP PUBLIC KEY BLOCK")
                  goodexport = 1 ; later used for Result_Bool indicator
                  If CreateFile(2, pubkey$)
                    WriteString(2, Output$, #PB_UTF8)
                    CloseFile(2)
                    Output$ = ""
                  Else
                    writeerror = 1 ; later used for Result_Bool indicator
                  EndIf
                EndIf
                ; GPG outputs to stderr, read from stderr
                t$ = ReadProgramError(exegpg, #PB_UTF8)
                While t$
                  Output$ + t$ + #CRLF$
                  t$ = ReadProgramError(exegpg, #PB_UTF8)
                Wend
                CloseProgram(exegpg)
                Output$ = Output$ + "Run finished" + #CRLF$ + "In case of successful export the public key file can be found in the selected directory"
                ; Change result fields
                SetGadgetText(Result_Text, Output$)
                If goodexport = 1
                  SetGadgetText(Result_Bool, "EXPORT COMPLETED")
                  SetGadgetColor(Result_Bool, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                  SetGadgetColor(Result_Bool, #PB_Gadget_BackColor, RGB(0, 255, 0))
                Else
                  SetGadgetText(Result_Bool, "ERROR EXPORT")
                  SetGadgetColor(Result_Bool, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                  SetGadgetColor(Result_Bool, #PB_Gadget_BackColor, RGB(255, 0, 0))
                EndIf
                If writeerror = 1
                  SetGadgetText(Result_Bool, "ERROR WRITING FILE")
                  SetGadgetColor(Result_Bool, #PB_Gadget_FrontColor, RGB(0, 0, 0))
                  SetGadgetColor(Result_Bool, #PB_Gadget_BackColor, RGB(255, 0, 0))
                EndIf
              EndIf
            EndIf
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
            ShellOpen("docs"+#PS$+"help-esign.html")
          EndIf
        ; Open README
        Case Button_About
          If EventType() = #PB_EventType_LeftClick
            ShellOpen("docs"+#PS$+"README-esign.txt")
          EndIf
          
          
      EndSelect
  EndSelect
  
Until Event = #PB_Event_CloseWindow And EventWindow() = Main_Window

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 289
; Folding = -
; EnableXP