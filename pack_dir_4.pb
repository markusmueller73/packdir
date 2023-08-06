EnableExplicit

UseZipPacker()
UseLZMAPacker()
UseTARPacker()

CompilerIf Not Defined(PB_Editor_BuildCount, #PB_Constant)
    #PB_Editor_BuildCount = 0
CompilerEndIf

#PRG_NAME  = "PackDir"
#PRG_MAJOR = 0
#PRG_MINOR = 4
#PRG_MICRO = #PB_Editor_BuildCount

CompilerIf #PB_Compiler_OS = #PB_OS_Linux
    #DEFAULT_PACKER = #PB_PackerPlugin_Tar | #PB_Packer_Bzip2
CompilerElse
    #DEFAULT_PACKER = #PB_PackerPlugin_Zip
CompilerEndIf
#DEFAULT_COMPRESSION = 7

Structure _CONFIG
    silent.b
    nodate.b
    add_date.b
    packer.l
    clevel.l
    ext.s
    input.s
    output.s
    prefix.s
    suffix.s
    packfile.s
    packoutput.s
EndStructure

Global LAST_ERROR.s = #Null$
Define config._CONFIG

Procedure.s RepeatString( String$ , Length.l ) ;- Create a new string of the given 'Length' with the string of 'String$'
    Protected i.l, result.s = #Null$
    For i = 1 To Length
        result + String$
    Next
    ProcedureReturn result
EndProcedure

Macro dbg( text )
    CompilerIf #PB_Compiler_Debugger
        If config\silent = 0
            ConsoleColor(6,0)
            PrintN("DEBUG: line " + #PB_Compiler_Line + " :: " + text)
            ConsoleColor(7,0)
        Else
            Debug "DEBUG: line " + #PB_Compiler_Line + " :: " + text
        EndIf
    CompilerEndIf
EndMacro

Macro err( text )
    LAST_ERROR = text
    If config\silent = 0
        ConsoleColor(4,0)
        If #PB_Compiler_Procedure = #Null$
            PrintN("ERROR: in file '" + #PB_Compiler_Filename + "' :: " + text + " in line " + #PB_Compiler_Line)
        Else
            PrintN("ERROR: in function '" + #PB_Compiler_Procedure + "()' :: " + text + " in line " + #PB_Compiler_Line)
        EndIf
        ConsoleColor(7,0)
    EndIf
EndMacro

Macro prnt( text )
    If config\silent = 0
        Print(text)
    EndIf
EndMacro

Macro prntn( text )
    If config\silent = 0
        PrintN(text)
    EndIf
EndMacro

Macro inpt()
    If config\silent = 0
        Input()
    EndIf
EndMacro

Macro close_cnsl()
    If config\silent = 0
        CompilerIf #PB_Compiler_Debugger
            Print("Press [ENTER] to quit...") : Input()
        CompilerEndIf
        CloseConsole()
    EndIf
EndMacro

Macro show_usage()
    If config\silent = 0
        PrintN("")
        PrintN("Usage:")
        PrintN(GetFilePart(ProgramFilename()) + " [arguments] (<directory>)")
        PrintN("")
        PrintN("Arguments:")
        PrintN("----------")
        PrintN("--7zip" + Space(5) + "-7" + Space(3) + "set the compression algorythm to LZMA, better known as 7zip")
        CompilerIf #PB_Compiler_OS = #PB_OS_Linux
            PrintN("--tar" + Space(6) + "-t" + Space(3) + "set the compression algorythm to TAR with Bzip2 (default)")
            PrintN("--zip" + Space(6) + "-z" + Space(3) + "set the compression algorythm to ZIP")
        CompilerElse
            PrintN("--tar" + Space(6) + "-t" + Space(3) + "set the compression algorythm to TAR with Bzip2")
            PrintN("--zip" + Space(6) + "-z" + Space(3) + "set the compression algorythm to ZIP (default)")
        CompilerEndIf
        PrintN("--clevel" + Space(3) + "-c" + Space(3) + "set the compression level: 1 (save only) to 10 (best), default level is " + Str(#DEFAULT_COMPRESSION))
        PrintN("--input" + Space(4) + "-i" + Space(3) + "use this input file or directory to compress")
        PrintN("--output" + Space(3) + "-o" + Space(3) + "the folder to save the archive, default folder is your desktop")
        PrintN("--prefix" + Space(8) + "a text phrase at start of archive name")
        PrintN("--suffix" + Space(8) + "a text phrase at the end of the archive name")
        PrintN("--nodate" + Space(3) + "-n" + Space(3) + "don't add the creation date at the filename")
        PrintN("--silent" + Space(3) + "-s" + Space(3) + "set the silent mode, no output generated")
        PrintN("--version" + Space(2) + "-v" + Space(3) + "shows the program version")
        PrintN("")
        PrintN("If you already set a file or directory with the '--input' argument, the <directory> argument will be ignored.")
        PrintN("")
        PrintN("Examples:")
        PrintN("---------")
        CompilerIf #PB_Compiler_OS = #PB_OS_Windows
            PrintN(GetFilePart(ProgramFilename()) + " "+Chr(34)+"C:\Eigene Dateien"+Chr(34))
            PrintN("^ this command compress the directory 'C:\Eigene Dateien' in an archive on your desktop")
            PrintN("")
            PrintN(GetFilePart(ProgramFilename()) + " -o D:\Backup\ "+Chr(34)+"C:\Eigene Dateien"+Chr(34))
            PrintN("^ this command compress the directory 'C:\Eigene Dateien' in an archive in the directoy D:\Backup")
        CompilerElse
            PrintN(GetFilePart(ProgramFilename()) + " /home/documents")
            PrintN("^ this command compress the directory /home/documents in an archive on your desktop")
            PrintN("")
            PrintN(GetFilePart(ProgramFilename()) + " -o /opt/backup /home/documents")
            PrintN("^ this command compress the directory /home/documents in an archive in the directoy /opt/backup")
        CompilerEndIf
        PrintN("")
        PrintN("Notes:")
        PrintN("------")
        PrintN("Be careful, a directory or file name with spaces or special characters must be set in doublequotes or escape it out.")
        PrintN("And if you add a prefix or suffix with spaces, it must be set in doublequotes too.")
        PrintN("")
        CompilerIf #PB_Compiler_OS = #PB_OS_Linux
            PrintN("The default compression algorythm is TAR with Bzip2.")
        CompilerElse
            PrintN("The default compression algorythm is ZIP.")
        CompilerEndIf
        PrintN("")
        CompilerIf #PB_Compiler_Debugger
            Print("Press [ENTER] to quit...") : Input()
        CompilerEndIf
        CloseConsole()
    EndIf
    End 1
EndMacro

Procedure.s format_time( miliseconds.q )
    
    Protected.l seconds, d, h, m, s, ms
    
    If miliseconds < 1000
        ProcedureReturn "0." + RSet(Str(miliseconds), 3, "0") + " secs"
    EndIf
    
;     seconds = miliseconds / 1000
;     d = seconds / 86400 : seconds - (d * 86400)
;     h = seconds / 3600  : seconds - (h * 3600)
;     m = seconds / 60    : seconds - (m * 60)
;     s = seconds
    
    ms = miliseconds % 1000
    seconds = miliseconds / 1000
    
    If seconds < 60
        s = seconds
        ProcedureReturn Str(s) + "." + RSet(Str(ms), 3, "0") + " seconds"
    ElseIf seconds >= 60 And seconds < 3600
        m = seconds / 60    : seconds - (m * 60)
        s = seconds
        ProcedureReturn Str(m) + ":" + RSet(Str(s), 2, "0") + "." + RSet(Str(ms), 3, "0") + " minutes"
    ElseIf seconds >= 3600 And seconds < 86400
        h = seconds / 3600  : seconds - (h * 3600)
        m = seconds / 60    : seconds - (m * 60)
        s = seconds
        ProcedureReturn Str(h) + ":" + RSet(Str(m), 2, "0") + ":" + RSet(Str(s), 2, "0") + "." + RSet(Str(ms), 3, "0") + " hours"
    ElseIf seconds >= 86400
        d = seconds / 86400 : seconds - (d * 86400)
        h = seconds / 3600  : seconds - (h * 3600)
        m = seconds / 60    : seconds - (m * 60)
        s = seconds
        ProcedureReturn Str(d) + " days, " + RSet(Str(h), 2, "0") + ":" + RSet(Str(m), 2, "0") + ":" + RSet(Str(s), 2, "0") + "." + RSet(Str(ms), 3, "0") + " hours"
    EndIf
    
EndProcedure

Procedure.l check_params()
    
    Shared config
    
    Macro _dq_
        "
    EndMacro
    
    Macro check_next_arg( config_var )
        If Left(argv(n+1),1) <> "-" And Left(argv(n+1),2) <> "--"
            config_var = argv(n+1) : dbg(_dq_ config_var _dq_ + " = " + argv(n+1))
            n+1
        Else
            PrintN("The use of the arguments is incorrect: '"+argv(n)+Space(1)+argv(n+1)+"'.")
            show_usage()
        EndIf
    EndMacro
    
    Protected n.l
    Protected args.l = CountProgramParameters()
    
    If args = 0
        show_usage()
    EndIf
    
    Dim argv.s(args-1)
    
    For n = 0 To args-1
        argv(n) = ProgramParameter(n)
    Next
        
    For n = 0 To args-1
        
        Select LCase(argv(n))
                
            Case "-c", "--compression"
                
                If Left(argv(n+1),1) <> "-" And Left(argv(n+1),2) <> "--"
                    config\clevel = Val(argv(n+1)) - 1
                    n + 1
                Else
                    PrintN("The use of the arguments is incorrect: '"+argv(n)+Space(1)+argv(n+1)+"'.")
                    show_usage()
                EndIf
                
            Case "-i", "--input"
                
                If config\input = #Null$
                    check_next_arg(config\input)
                Else
                    prntn("Input file/dir is already set.")
                EndIf
                
            Case "-o", "--output"
                
                If config\output = #Null$
                    check_next_arg(config\output)
                Else
                    prntn("Output directory is already set.")
                EndIf
                
            Case "-n", "--nodate"
                
                If config\nodate = 0
                    config\nodate = 1
                Else
                    prntn("creation date is already supressed.")
                EndIf
                
            Case "--prefix"
                
                If config\prefix = #Null$
                    check_next_arg(config\prefix)
                Else
                    prntn("Prefix of output file is already set.")
                EndIf

            Case "--suffix"
                
                If config\suffix = #Null$
                    check_next_arg(config\suffix)
                Else
                    prntn("Suffix of output file is already set.")
                EndIf
                
            Case "-s","--silent"
                
                If config\silent = 0
                    config\silent = 1
                Else
                    prntn("Silent mode is already enabled.")
                EndIf
                
            Case "-v","--version"
                
                prntn(#PRG_NAME + " version " + Str(#PRG_MAJOR) + "." + Str(#PRG_MINOR) + "." + Str(#PRG_MICRO))
                ;prntn("")
                End 1
                
            Case "-7","--7zip"
                
                If config\packer = #Null
                    config\packer = #PB_PackerPlugin_Lzma
                    config\ext = "7z"
                Else
                    prntn("Pack algorythm is already set.")
                EndIf
                
            Case "-z","--zip"
                
                If config\packer = #Null
                    config\packer = #PB_PackerPlugin_Zip
                    config\ext = "zip"
                Else
                    prntn("Pack algorythm is already set.")
                EndIf
                
            Case "-t","--tar"
                
                If config\packer = #Null
                    config\packer = #PB_PackerPlugin_Tar|#PB_Packer_Bzip2
                    config\ext = "tar"
                Else
                    prntn("Pack algorythm is already set.")
                EndIf
            
        EndSelect
        
    Next
    
    If config\packer = #Null
        config\packer = #DEFAULT_PACKER
        If config\packer = #PB_PackerPlugin_Zip
            config\ext = "zip"
        ElseIf config\packer = #PB_PackerPlugin_Tar
            config\ext = "tar"
        EndIf
    EndIf
    
    If config\clevel < 0 And config\clevel > 9
        config\clevel = #DEFAULT_COMPRESSION
    EndIf
    
    If config\input = #Null$
        config\input = argv(args-1)
    EndIf
    
    If config\output = #Null$
        config\output = GetUserDirectory(#PB_Directory_Desktop)
    EndIf
    
    FreeArray(argv())
    
    ProcedureReturn args
    
EndProcedure

Procedure.q get_directory_content( root_dir$ , List files$() )
    
    Shared config
    
    Protected h_dir.i
    Protected nb_of_bytes.q
    Protected sub_dir$
    
    If FileSize(root_dir$) <> -2
        err("The directory '"+root_dir$+"' didn't exist.")
        ProcedureReturn 0
    EndIf
    
    If Right(root_dir$, 1) <> #PS$
        root_dir$ + #PS$
    EndIf : dbg("examine dir: " + root_dir$)
    
    h_dir = ExamineDirectory(#PB_Any, root_dir$, "*")
    If IsDirectory(h_dir)
        
        While NextDirectoryEntry(h_dir)
            
            If DirectoryEntryType(h_dir) = #PB_DirectoryEntry_Directory
                
                sub_dir$ = DirectoryEntryName(h_dir)
                If sub_dir$ <> "." And sub_dir$ <> ".."
                    nb_of_bytes + get_directory_content(root_dir$ + sub_dir$, files$())
                EndIf
                
            ElseIf DirectoryEntryType(h_dir) = #PB_DirectoryEntry_File
                
                AddElement(files$())
                files$() = root_dir$ + DirectoryEntryName(h_dir)
                
                nb_of_bytes + DirectoryEntrySize(h_dir)
                
            EndIf
            
        Wend
        
        FinishDirectory(h_dir)
        
    Else
        err("Can't open directory '"+root_dir$+"'.")
        ProcedureReturn 0
    EndIf
    
    ProcedureReturn nb_of_bytes
    
EndProcedure

OpenConsole(ProgramFilename())

If check_params() = 0
    show_usage()
EndIf

If config\silent <> 0
    CloseConsole()
EndIf

If FileSize(config\output) = -2
    
    With config
        
        If Right(\output, 1) <> #PS$
            \output + #PS$
        EndIf
        
        If \prefix <> #Null$
            \prefix + "_"
        EndIf
        
        If \suffix <> #Null$
            \suffix = "_" + \suffix
        EndIf
        
    EndWith

Else
    err("The output argument insn't a directory.")
    close_cnsl()
    End 3
EndIf

Define timer.q
Define nb_of_bytes.q

NewList file$()

If FileSize(config\input) = -2      ; = directory
    
    If Right(config\input, 1) <> #PS$
        config\input + #PS$
    EndIf
        
    prntn("Examining directory: " + config\input)
    
    timer       = ElapsedMilliseconds()
    nb_of_bytes = get_directory_content(config\input, file$())
    
    If  ListSize(file$()) = 0
        prntn("Nothing to pack. Bye.")
        FreeList(file$())
        close_cnsl()
        End 3
    EndIf
    
    prntn("Found "+Str(ListSize(file$()))+" files in "+format_time(ElapsedMilliseconds()-timer)+".")
    
    config\packoutput = StringField(config\input, CountString(config\input, #PS$), #PS$)
    
ElseIf FileSize(config\input) > 0   ; = file
    
    AddElement(file$())
    file$() = config\input
    
    config\packoutput = GetFilePart(config\input, #PB_FileSystem_NoExtension)
    
Else
    FreeList(file$())
    err("The file or dir to compress didn't exist.")
    close_cnsl()
    End 4
EndIf

If config\nodate
    config\packfile   = config\output + config\prefix + config\packoutput + config\suffix + "." + config\ext
Else
    config\packfile   = config\output + config\prefix + FormatDate("%yyyy-%mm-%dd-%hh-%ii", Date()) + "_" + config\packoutput + config\suffix + "." + config\ext
EndIf
prntn("Creating archive file '"+config\packfile+"'")

Define one_percent.f = nb_of_bytes / 100 : dbg("1% = " + StrF(one_percent,4))
Define cur_percent.l
Define cur_bytes.q
Define last_percent.l
Define h_console.i
Define x.l, y.l, n.l
Define packname$

timer = ElapsedMilliseconds()
If CreatePack(0, config\packfile, config\packer, config\clevel)
    
    prnt("  0%|")
    
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        
        Define sb_info.CONSOLE_SCREEN_BUFFER_INFO
        
        EnableGraphicalConsole(1)
        h_console = GetStdHandle_(#STD_OUTPUT_HANDLE)
        
        GetConsoleScreenBufferInfo_(h_console, sb_info)
        x = sb_info\dwCursorPosition\x
        y = sb_info\dwCursorPosition\y
        
        ForEach file$()
            
            cur_bytes   = cur_bytes + FileSize(file$())
            cur_percent = Round(cur_bytes / one_percent, #PB_Round_Nearest) : dbg("actual percent: " + Str(cur_percent))
            
            For n = 0 To cur_percent / 2
                ConsoleLocate(x+n, y)
                prnt("-")
            Next
            ConsoleLocate(x+51, y)
            prnt("|" + RSet(Str(cur_percent), 3) + "%")
            
            packname$ = RemoveString(file$(), config\input, #PB_String_CaseSensitive, 1, 1)
            packname$ = config\packoutput + #PS$ + packname$
            If FindString(packname$, ":", 1)
                packname$ = RemoveString(file$(), ":", #PB_String_NoCase, 1, 1)
            EndIf
            
            CompilerIf #PB_Compiler_Debugger
                Delay(50)
            CompilerElse
                AddPackFile(0, file$(), packname$)
            CompilerEndIf
            
        Next
            
    CompilerElse
        
        ForEach file$()
            
            cur_bytes   = cur_bytes + FileSize(file$())
            cur_percent = Round(cur_bytes / one_percent, #PB_Round_Nearest) : dbg("actual percent: " + Str(cur_percent))
            prnt(RepeatString("-",(cur_percent/2)-last_percent))
            last_percent = cur_percent/2
            
            packname$ = RemoveString(file$(), config\input, #PB_String_CaseSensitive, 1, 1)
            packname$ = config\packoutput + #PS$ + packname$
            If FindString(packname$, ":", 1)
                packname$ = RemoveString(file$(), ":", #PB_String_NoCase, 1, 1)
            EndIf
            
            AddPackFile(0, file$(), packname$)
            
        Next
        
        prnt("|100%")
        
    CompilerEndIf
    
    ClosePack(0)
    
    prntn(" Done!")
    
    prntn("Successfully created in "+format_time(ElapsedMilliseconds()-timer)+".")
    
Else
    err("Can't create archive file.")
    FreeList(file$())
    close_cnsl()
    End 5
EndIf

FreeList(file$())

close_cnsl()

End 0


; IDE Options = PureBasic 6.00 LTS (Windows - x64)
; ExecutableFormat = Console
; CursorPosition = 488
; FirstLine = 447
; Folding = ---
; Optimizer
; Executable = packdir.exe
; CommandLine = -i "C:\Users\Markus Müller\OneDrive\Programmierung\PureBasic\001.bmp" -n
; Compiler = PureBasic 6.00 LTS - C Backend (Windows - x64)
; EnablePurifier
; EnableCompileCount = 76
; EnableBuildCount = 24
; EnableExeConstant