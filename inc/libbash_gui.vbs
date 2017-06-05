' ########################################################
' #                                                      #
' #  libbash.sh GUI for Windows                          #
' #  VBScript to extend GUI functions to Windows         #
' #                                                      #
' #  MIT License                                         #
' #  Copyright (c) 2017 Jean Prunneaux                   #
' #  Website: https://github.com/pruje/libbash.sh        #
' #                                                      #
' #  Version 1.1.0 (2017-06-05)                          #
' #                                                      #
' ########################################################


' ###############
' #  FUNCTIONS  #
' ###############

' Display an info message
' Usage: lbg_display_info TEXT [TITLE]
Function lbg_display_info(args)
	MsgBox args(0), vbInformation, args(1)
End Function


' Display a warning message
' Usage: lbg_display_warning TEXT [TITLE]
Function lbg_display_warning(args)
	MsgBox args(0), vbExclamation, args(1)
End Function


' Display an error message
' Usage: lbg_display_error TEXT [TITLE]
Function lbg_display_error(args)
	MsgBox args(0), vbCritical, args(1)
End Function


' Prompt user to confirm an action
' Usage: lbg_yesno TEXT [TITLE] [DEFAULT_YES]
' TODO: test button labels
Function lbg_yesno(args)

	lbg_yesno_opts = vbYesNo+vbQuestion

	If args(2) != true Then
		lbg_yesno_opts = lbg_yesno_opts + vbDefaultButton2
	End If

	MsgBox args(0), lbg_yesno_opts, args(1)
End Function


' ####################
' #  INITIALIZATION  #
' ####################

exitcode = 0

' get arguments of the current script
Set script_arguments = WScript.Arguments

' missing arguments: error
If script_arguments.Count = 0 Then
	WScript.Echo "Bad Usage"
	WScript.Quit 1
End If

' get function name to execute
Set func = GetRef(script_arguments(0))

' get function arguments
Dim func_args()
For i = 1 To script_arguments.Count - 1
	ReDim Preserve func_args(i)
	func_args(i-1) = script_arguments(i)
Next

' execute function
func func_args

' forward exit code
WScript.Quit exitcode
