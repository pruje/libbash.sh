' ########################################################
' #                                                      #
' #  libbash.sh GUI for Windows                          #
' #  Functions for display GUI tools using VBScript      #
' #                                                      #
' #  MIT License                                         #
' #  Copyright (c) 2017-2018 Jean Prunneaux              #
' #  Website: https://github.com/pruje/libbash.sh        #
' #                                                      #
' #  Version 1.9.2 (2018-08-26)                          #
' #                                                      #
' ########################################################

' Index
'
'   * Init
'   * Internal functions
'       test_arguments
'   * Functions
'       lbg_display_info
'       lbg_display_warning
'       lbg_display_error
'       lbg_yesno
'       lbg_input_text
'       lbg_choose_directory


' ##########
' #  INIT  #
' ##########

' force every variables to be declared
Option Explicit

' declare exitcode as global variable
Dim exitcode


' ########################
' #  INTERNAL FUNCTIONS  #
' ########################

' Test arguments or a function
' Usage: test_arguments ARGS MIN_NUMBER
Function test_arguments(args, min)

	test_arguments = false

	' verify if there are enough arguments
	If UBound(args) >= min Then
		test_arguments = true
	End If

End Function


' ###############
' #  FUNCTIONS  #
' ###############

' Display an info message
' Usage: lbg_display_info TEXT [TITLE]
Function lbg_display_info(args)

	' catch usage errors
	If Not test_arguments(args, 1) Then
		exitcode = 1
		Exit Function
	End If

	' display dialog
	MsgBox args(0), vbInformation, args(1)

End Function


' Display a warning message
' Usage: lbg_display_warning TEXT [TITLE]
Function lbg_display_warning(args)

	' catch usage errors
	If Not test_arguments(args, 1) Then
		exitcode = 1
		Exit Function
	End If

	' display dialog
	MsgBox args(0), vbExclamation, args(1)

End Function


' Display an error message
' Usage: lbg_display_error TEXT [TITLE]
Function lbg_display_error(args)

	' catch usage errors
	If Not test_arguments(args, 1) Then
		exitcode = 1
		Exit Function
	End If

	' display dialog
	MsgBox args(0), vbCritical, args(1)

End Function


' Prompt user to confirm an action
' Usage: lbg_yesno TEXT [TITLE] [DEFAULT_YES]
' TODO: test button labels
Function lbg_yesno(args)

	' define local variables
	Dim lbg_yesno_opts, lbg_yesno_result, lbg_yesno_yesdefault

	lbg_yesno_yesdefault = false
	lbg_yesno_opts = vbYesNo+vbQuestion

	' catch usage errors
	If Not test_arguments(args, 1) Then
		exitcode = 1
		Exit Function
	End If

	' get yes by default option
	If UBound(args) >= 3 Then
		If args(2) = "true" Then
			lbg_yesno_yesdefault = true
		End If
	End If

	If Not lbg_yesno_yesdefault Then
		lbg_yesno_opts = lbg_yesno_opts + vbDefaultButton2
	End If

	lbg_yesno_result = MsgBox(args(0), lbg_yesno_opts, args(1))

	If lbg_yesno_result <> vbYes Then
		exitcode = 2
	End If

End Function


' Ask user to enter a text
' Usage: lbg_input_text TEXT [TITLE] [DEFAULT]
Function lbg_input_text(args)

	' define local variables
	Dim lbg_input_result, lbg_input_default

	' catch usage errors
	If Not test_arguments(args, 1) Then
		exitcode = 1
		Exit Function
	End If

	' get default option
	If UBound(args) >= 3 Then
		lbg_input_default = args(2)
	End If

	lbg_input_result = InputBox(args(0), args(1), lbg_input_default)

	' cancelled
	If IsEmpty(lbg_input_result) Then
		exitcode = 2
		Exit Function
	End If

	' print text
	WScript.Echo lbg_input_result

End Function


' Ask user to choose an existing directory
' Usage: lbg_choose_directory LABEL
Function lbg_choose_directory(args)

	' define local variables
	Dim lbg_chdir_shell, lbg_chdir_choice

	' catch usage errors
	If Not test_arguments(args, 1) Then
		exitcode = 1
		Exit Function
	End If

	' Create a dialog object
	Set lbg_chdir_shell  = CreateObject("Shell.Application")
	Set lbg_chdir_choice = lbg_chdir_shell.BrowseForFolder(0, args(0), &H0071)

	' Return the path of the selected folder
	If (lbg_chdir_choice is nothing) Then
		exitcode = 2
	Else
		WScript.Echo lbg_chdir_choice.Self.Path
	End If

End Function


' ####################
' #  INITIALIZATION  #
' ####################

exitcode = 0

' get arguments of the current script
Dim script_arguments
Set script_arguments = WScript.Arguments

' missing arguments: error
If script_arguments.Count = 0 Then
	WScript.Quit 1
End If

Dim lbg_func
Set lbg_func = GetRef(script_arguments(0))

' get function arguments
Dim func_args(), i
For i = 1 To script_arguments.Count - 1
	ReDim Preserve func_args(i)
	func_args(i-1) = script_arguments(i)
Next

' execute function
lbg_func(func_args)

' quit with returning exit code
WScript.Quit exitcode
