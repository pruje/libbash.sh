########################################################
#                                                      #
#  libbash.sh GUI                                      #
#  Functions to extend bash scripts to GUI tools       #
#                                                      #
#  MIT License                                         #
#  Copyright (c) 2017 Jean Prunneaux                   #
#  Website: https://github.com/pruje/libbash.sh        #
#                                                      #
#  Version 1.6.3 (2017-11-13)                          #
#                                                      #
########################################################

# Index
#
#   * Main variables
#   * Internal functions
#       lbg_get_console_size
#       lbg_dialog_size
#   * GUI tools
#       lbg_get_gui
#       lbg_set_gui
#   * Messages and notifications
#       lbg_display_info
#       lbg_display_warning
#       lbg_display_error
#       lbg_notify
#   * User interaction
#       lbg_yesno
#       lbg_choose_option
#       lbg_input_text
#       lbg_input_password
#   * Files and directories
#       lbg_choose_directory
#       lbg_choose_file
#       lbg_open_directory
#   * Aliases and compatibility
#       lbg_display_critical
#       lbg_critical
#       lbg_display_debug
#       lbg_debug
#       lbg_info
#       lbg_warning
#       lbg_error
#   * Initialization


# test if libbash.sh is loaded
if [ -z "$lb_version" ] ; then
	echo >&2 "Error: libbash core not loaded!"
	echo >&2 "Please load it in your script before loading this library with command:"
	echo >&2 "   source \"/path/to/libbash.sh\""
	return 1
fi


####################
#  MAIN VARIABLES  #
####################

# libbash GUI path
lbg_path=$BASH_SOURCE

# set supported GUIs
lbg_supported_gui=(kdialog zenity osascript cscript dialog console)

# GUI tool
lbg_gui=""

# console size
lbg_console_width=""
lbg_console_height=""

# VB script and cscript command for Windows
lbg_vbscript_directory="$lb_directory/inc"
lbg_vbscript="libbash_gui.vbs"
lbg_cscript=(cscript /NoLogo "$lbg_vbscript")


##################################
#  INTERNAL FUNCTIONS            #
#  DO NOT PUBLISH DOCUMENTATION  #
##################################

# Get console size and update lbg_console_width and lbg_console_height variables
# Usage: lbg_get_console_size()
# Exit codes:
#   0: OK
#   1: No terminal available
lbg_get_console_size() {

	# get console width and height
	lbg_console_width=$(tput cols 2> /dev/null)
	lbg_console_height=$(tput lines 2> /dev/null)

	# if error (script not running in a terminal)
	if [ -z "$lbg_console_width" ] || [ -z "$lbg_console_height" ] ; then
		return 1
	fi
}


# Set dialog size to fit console
# Usage: lbg_dialog_size MAX_WIDTH MAX_HEIGHT
# Return: "HEIGHT WIDTH"
# e.g. dialog --msgbox "Hello world" $(lbg_dialog_size 50 10)
lbg_dialog_size() {

	# given size
	local lbg_dialog_width=$1
	local lbg_dialog_height=$2

	# if max width > console width, fit to console width
	if [ "$lbg_dialog_width" -gt "$lbg_console_width" ] ; then
		lbg_dialog_width=$lbg_console_width
	fi

	# if max height > console height, fit to console height
	if [ "$lbg_dialog_height" -gt "$lbg_console_height" ] ; then
		lbg_dialog_height=$lbg_console_height
	fi

	# return "height width"
	echo $lbg_dialog_height $lbg_dialog_width
}


###############
#  GUI TOOLS  #
###############

# Get current GUI tool
# Usage: lbg_get_gui
lbg_get_gui() {

	# if no GUI tool defined
	if [ -z "$lbg_gui" ] ; then
		return 1
	fi

	# return current GUI tool
	echo "$lbg_gui"
}


# Set GUI display to use
# Usage: lbg_set_gui [GUI_TOOL...]
lbg_set_gui() {

	# default options
	local lbg_setgui_tools=(${lbg_supported_gui[@]})
	local lbg_setgui_res=0

	# if args set, test list of commands
	if [ $# -gt 0 ] ; then
		lbg_setgui_tools=($*)
	fi

	# test GUI tools
	for lbg_sgt in ${lbg_setgui_tools[@]} ; do

		# set console mode is always OK
		if [ "$lbg_sgt" == console ] ; then
			lbg_setgui_res=0
			break
		fi

		# test if GUI is supported
		if ! lb_array_contains "$lbg_sgt" "${lbg_supported_gui[@]}" ; then
			lbg_setgui_res=1
			continue
		fi

		# test if command exists
		if ! lb_command_exists "$lbg_sgt" ; then
			lbg_setgui_res=3
			continue
		fi

		# dialog command
		case $lbg_sgt in
			dialog)
				# get console size
				if ! lbg_get_console_size ; then
					lbg_setgui_res=4
					continue
				fi
				;;
			osascript)
				# test OS
				if [ "$lb_current_os" != macOS ] ; then
					lbg_setgui_res=4
					continue
				fi
				;;
			cscript)
				# test OS
				if [ "$lb_current_os" != Windows ] ; then
					lbg_setgui_res=4
					continue
				fi

				# test VB script
				if ! [ -f "$lbg_vbscript_directory/$lbg_vbscript" ] ; then
					lbg_setgui_res=4
					continue
				fi
				;;
			*)
				# test if X server started (only for Linux and Windows)
				if [ "$lb_current_os" != macOS ] ; then
					if [ -z "$DISPLAY" ] ; then
						lbg_setgui_res=4
						continue
					fi
				fi
				;;
		esac

		# all tests passed: tool can be set
		lbg_setgui_res=0
		break
	done

	# set gui tool
	if [ $lbg_setgui_res == 0 ] ; then
		lbg_gui=$lbg_sgt
	fi

	return $lbg_setgui_res
}


################################
#  MESSAGES AND NOTIFICATIONS  #
################################

# Display an info dialog
# Usage: lbg_display_info [OPTIONS] TEXT
lbg_display_info() {

	# default options
	local lbg_dinf_title=$lb_current_script_name

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			-t|--title)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_dinf_title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if no text to display
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# prepare command
	case $lbg_gui in
		kdialog)
			lbg_dinf_cmd=(kdialog --title "$lbg_dinf_title" --msgbox "$*")
			;;

		zenity)
			lbg_dinf_cmd=(zenity --title "$lbg_dinf_title" --info --text "$*")
			;;

		osascript)
			# run command
			osascript &> /dev/null << EOF
display dialog "$*" with title "$lbg_dinf_title" with icon note buttons {"$lb_default_ok_label"} default button 1
EOF
			# if command error
			if [ $? != 0 ] ; then
				return 2
			fi

			# quit
			return 0
			;;

		cscript)
			lbg_dinf_cmd=("${lbg_cscript[@]}")
			lbg_dinf_cmd+=(lbg_display_info "$(echo -e "$*")" "$lbg_dinf_title")

			# run VBscript into a context (cscript does not work with absolute paths)
			$(cd "$lbg_vbscript_directory" && "${lbg_dinf_cmd[@]}")

			# command failed
			if [ $? != 0 ] ; then
				return 2
			fi

			return 0
			;;

		dialog)
			dialog --title "$lbg_dinf_title" --clear --msgbox "$*" $(lbg_dialog_size 50 10) 2> /dev/null
			lbg_dinf_res=$?

			# clear console
			clear

			# command error
			if [ $lbg_dinf_res != 0 ] ; then
				return 2
			fi

			# quit
			return 0
			;;

		*)
			# console mode
			lbg_dinf_cmd=(lb_display_info "$*")
			;;
	esac

	# run command
	"${lbg_dinf_cmd[@]}" 2> /dev/null

	# command error
	if [ $? != 0 ] ; then
		return 2
	fi
}


# Display a warning message
# Usage: lbg_display_warning [OPTIONS] TEXT
lbg_display_warning() {

	# default options
	local lbg_dwn_title=$lb_current_script_name

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			-t|--title)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_dwn_title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if no text to display
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# prepare command
	case $lbg_gui in
		kdialog)
			lbg_dwn_cmd=(kdialog --title "$lbg_dwn_title" --sorry "$*")
			;;

		zenity)
			lbg_dwn_cmd=(zenity --title "$lbg_dwn_title" --warning --text "$*")
			;;

		osascript)
			# run command
			osascript &> /dev/null << EOF
display dialog "$*" with title "$lbg_dwn_title" with icon caution buttons {"$lb_default_ok_label"} default button 1
EOF
			# command error
			if [ $? != 0 ] ; then
				return 2
			fi

			# quit
			return 0
			;;

		cscript)
			lbg_dwn_cmd=("${lbg_cscript[@]}")
			lbg_dwn_cmd+=(lbg_display_warning "$(echo -e "$*")" "$lbg_dwn_title")

			# run VBscript into a context (cscript does not work with absolute paths)
			$(cd "$lbg_vbscript_directory" && "${lbg_dwn_cmd[@]}")

			# command failed
			if [ $? != 0 ] ; then
				return 2
			fi

			return 0
			;;

		dialog)
			# same command as lbg_display_info, but we add warning prefix
			lbg_dwn_cmd=(lbg_display_info "$lb_default_warning_label: $*")
			;;

		*)
			# console mode
			lbg_dwn_cmd=(lb_display_warning "$*")
			;;
	esac

	# run command
	"${lbg_dwn_cmd[@]}" 2> /dev/null

	# command error
	if [ $? != 0 ] ; then
		return 2
	fi
}


# Display an error message
# Usage: lbg_display_error [OPTIONS] TEXT
lbg_display_error() {

	# default options
	local lbg_derr_title=$lb_current_script_name

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			-t|--title)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_derr_title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if no text to display
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# prepare command
	case $lbg_gui in
		kdialog)
			lbg_derr_cmd=(kdialog --title "$lbg_derr_title" --error "$*")
			;;

		zenity)
			lbg_derr_cmd=(zenity --title "$lbg_derr_title" --error --text "$*")
			;;

		osascript)
			# run command
			osascript &> /dev/null << EOF
display dialog "$*" with title "$lbg_derr_title" with icon stop buttons {"$lb_default_ok_label"} default button 1
EOF
			# command error
			if [ $? != 0 ] ; then
				return 2
			fi

			# quit
			return 0
			;;

		cscript)
			lbg_derr_cmd=("${lbg_cscript[@]}")
			lbg_derr_cmd+=(lbg_display_error "$(echo -e "$*")" "$lbg_derr_title")

			# run VBscript into a context (cscript does not work with absolute paths)
			$(cd "$lbg_vbscript_directory" && "${lbg_derr_cmd[@]}")

			# command failed
			if [ $? != 0 ] ; then
				return 2
			fi

			return 0
			;;

		dialog)
			# same command as lbg_display_info, but we add error prefix
			lbg_derr_cmd=(lbg_display_info "$lb_default_error_label: $*")
			;;

		*)
			# console mode
			lbg_derr_cmd=(lb_display_error $*)
			;;
	esac

	# run command
	"${lbg_derr_cmd[@]}" 2> /dev/null

	# command error
	if [ $? != 0 ] ; then
		return 2
	fi
}


# Display a notification popup
# Usage: lbg_notify [OPTIONS] TEXT
lbg_notify() {

	# default options
	local lbg_notify_title=$lb_current_script_name
	local lbg_notify_timeout=""
	local lbg_notify_use_notifysend=true

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			-t|--title)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_notify_title=$2
				shift
				;;
			--timeout)
				if ! lb_is_integer $2 ; then
					return 1
				fi
				lbg_notify_timeout=$2
				shift
				;;
			--no-notify-send)
				# do not use notify-send command if available
				lbg_notify_use_notifysend=false
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if no text
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# if notify-send is installed, use it by default,
	# as it is better than zenity or other system
	if lb_command_exists notify-send ; then
		if $lbg_notify_use_notifysend ; then
			# do not override kdialog because it has the best integration to KDE desktop
			# do not use it on macOS nor in console mode
			if ! lb_array_contains "$lbg_gui" kdialog osascript console ; then
				# execute command with timeout in milliseconds
				if [ -n "$lbg_notify_timeout" ] ; then
					lbg_notify_opts="-t $(($lbg_notify_timeout * 1000)) "
				fi

				# push notification and return
				notify-send $lbg_notify_opts"$lbg_notify_title" "$*"
				if [ $? == 0 ] ; then
					return 0
				else
					return 2
				fi
			fi
		fi
	fi

	# run command
	case $lbg_gui in
		kdialog)
			kdialog --title "$lbg_notify_title" --passivepopup "$*" $lbg_notify_timeout 2> /dev/null
			;;

		zenity)
			lbg_notify_opts=""

			# set a timeout
			if [ -n "$lbg_notify_timeout" ] ; then
				lbg_notify_opts="--timeout=$lbg_notify_timeout"
			fi

			# run command
			zenity --notification $lbg_notify_opts --text "$*" 2> /dev/null
			;;

		osascript)
			osascript &> /dev/null << EOF
display notification "$*" with title "$lbg_notify_title"
EOF
			;;

		# no dialog command, because it doesn't make sense in console

		*)
			# print in console mode
			lb_display "[$lb_default_info_label]  $*"
			;;
	esac

	# command error
	if [ $? != 0 ] ; then
		return 2
	fi
}


######################
#  USER INTERACTION  #
######################

# Prompt user to confirm an action
# Usage: lbg_yesno [OPTIONS] TEXT
# SOME OPTIONS ARE NOT AVAILABLE ON WINDOWS
lbg_yesno() {

	# default options
	local lbg_yn_defaultyes=false
	local lbg_yn_yeslbl=""
	local lbg_yn_nolbl=""
	local lbg_yn_title=$lb_current_script_name
	local lbg_yn_cmd=()

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			-y|--yes)
				lbg_yn_defaultyes=true
				;;
			--yes-label)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_yn_yeslbl=$2
				shift
				;;
			--no-label)
				lbg_yn_nolbl=$2
				shift
				;;
			-t|--title)
				lbg_yn_title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if no text to display
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# prepare command
	case $lbg_gui in
		kdialog)
			lbg_yn_cmd=(kdialog --title "$lbg_yn_title")
			if [ -n "$lbg_yn_yeslbl" ] ; then
				lbg_yn_cmd+=(--yes-label "$lbg_yn_yeslbl")
			fi
			if [ -n "$lbg_yn_nolbl" ] ; then
				lbg_yn_cmd+=(--no-label "$lbg_yn_nolbl")
			fi
			lbg_yn_cmd+=(--yesno "$*")
			;;

		zenity)
			lbg_yn_cmd=(zenity --question --title "$lbg_yn_title" --text "$*")
			;;

		osascript)
			# set button labels
			if [ -z "$lbg_yn_yeslbl" ] ; then
				lbg_yn_yeslbl=$lb_default_yes_label
			fi
			if [ -z "$lbg_yn_nolbl" ] ; then
				lbg_yn_nolbl=$lb_default_no_label
			fi

			# set options
			lbg_yn_opts="default button "
			if $lbg_yn_defaultyes ; then
				lbg_yn_opts+="1"
			else
				lbg_yn_opts+="2"
			fi

			# run command
			lbg_yn_res=$(osascript << EOF
set question to (display dialog "$*" with title "$lbg_yn_title" buttons {"$lbg_yn_yeslbl", "$lbg_yn_nolbl"} $lbg_yn_opts)
set answer to button returned of question
if answer is equal to "$lbg_yn_yeslbl" then
	return 0
else
	return 2
end if
EOF)
			# return choice
			return $lbg_yn_res
			;;

		cscript)
			lbg_yn_cmd=("${lbg_cscript[@]}")
			lbg_yn_cmd+=(lbg_yesno "$(echo -e "$*")" "$lbg_yn_title")
			if $lbg_yn_defaultyes ; then
				lbg_yn_cmd+=(true)
			fi

			# run VBscript into a context (cscript does not work with absolute paths)
			$(cd "$lbg_vbscript_directory" && "${lbg_yn_cmd[@]}")

			# command failed or response is no
			if [ $? != 0 ] ; then
				return 2
			fi

			return 0
			;;

		dialog)
			lbg_yn_cmd=(dialog --title "$lbg_yn_title")
			if ! $lbg_yn_defaultyes ; then
				lbg_yn_cmd+=(--defaultno)
			fi
			if [ -n "$lbg_yn_yeslbl" ] ; then
				lbg_yn_cmd+=(--yes-label "$lbg_yn_yeslbl")
			fi
			if [ -n "$lbg_yn_nolbl" ] ; then
				lbg_yn_cmd+=(--no-label "$lbg_yn_nolbl")
			fi
			lbg_yn_cmd+=(--clear --yesno "$*" $(lbg_dialog_size 100 10))

			# run command
			"${lbg_yn_cmd[@]}"
			lbg_yn_res=$?

			# clear console
			clear

			# return result
			case $lbg_yn_res in
				0)
					return 0
					;;
				255)
					# cancelled
					return 3
					;;
				*)
					return 2
					;;
			esac
			;;

		*)
			# console mode
			lbg_yn_cmd=(lb_yesno)
			if $lbg_yn_defaultyes ; then
				lbg_yn_cmd+=(-y)
			fi
			if [ -n "$lbg_yn_yeslbl" ] ; then
				lbg_yn_cmd+=(--yes-label "$lbg_yn_yeslbl")
			fi
			if [ -n "$lbg_yn_nolbl" ] ; then
				lbg_yn_cmd+=(--no-label "$lbg_yn_nolbl")
			fi
			lbg_yn_cmd+=("$*")
			;;
	esac

	# run command
	"${lbg_yn_cmd[@]}" 2> /dev/null

	# command error
	if [ $? != 0 ] ; then
		return 2
	fi
}


# Ask user to choose an option
# Usage: lbg_choose_option [OPTIONS] CHOICE [CHOICE...]
lbg_choose_option=""
lbg_choose_option() {

	# reset result
	lbg_choose_option=""

	# default options and local variables
	local lbg_chop_default=0
	# options: initialize with an empty first value (option ID starts to 1, not 0)
	local lbg_chop_options=("")
	local lbg_chop_title=$lb_current_script_name
	local lbg_chop_label=$lb_default_chopt_label

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			-d|--default)
				if ! lb_is_integer $2 ; then
					return 1
				fi
				lbg_chop_default=$2
				shift
				;;
			-l|--label)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_chop_label=$2
				shift
				;;
			-t|--title)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_chop_title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if missing at least 1 choice option
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# prepare options
	while [ -n "$1" ] ; do
		lbg_chop_options+=("$1")
		shift
	done

	# verify if default option is valid
	if [ $lbg_chop_default -lt 0 ] || [ $lbg_chop_default -ge ${#lbg_chop_options[@]} ] ; then
		return 1
	fi

	# prepare command
	case $lbg_gui in
		kdialog)
			lbg_chop_cmd=(kdialog --title "$lbg_chop_title" --radiolist "$lbg_chop_label")

			# add options
			for ((lbg_chop_i=1 ; lbg_chop_i <= ${#lbg_chop_options[@]}-1 ; lbg_chop_i++)) ; do
				lbg_chop_cmd+=($lbg_chop_i "${lbg_chop_options[$lbg_chop_i]}")
				if [ $lbg_chop_i == $lbg_chop_default ] ; then
					lbg_chop_cmd+=(on)
				else
					lbg_chop_cmd+=(off)
				fi
			done

			# run command
			lbg_choose_option=$("${lbg_chop_cmd[@]}" 2> /dev/null)
			;;

		zenity)
			lbg_chop_cmd=(zenity --list --title "$lbg_chop_title" --text "$lbg_chop_label" --radiolist --column "" --column "" --column "")

			# add options
			for ((lbg_chop_i=1 ; lbg_chop_i <= ${#lbg_chop_options[@]}-1 ; lbg_chop_i++)) ; do
				if [ $lbg_chop_i == $lbg_chop_default ] ; then
					lbg_chop_cmd+=(TRUE)
				else
					lbg_chop_cmd+=(FALSE)
				fi

				lbg_chop_cmd+=($lbg_chop_i "${lbg_chop_options[$lbg_chop_i]}")
			done

			# run command
			lbg_choose_option=$("${lbg_chop_cmd[@]}" 2> /dev/null)
			;;

		osascript)
			lbg_chop_default_option=""

			# prepare options
			local lbg_chop_opts="{"

			for ((lbg_chop_i=1 ; lbg_chop_i <= ${#lbg_chop_options[@]}-1 ; lbg_chop_i++)) ; do
				lbg_chop_opts+="\"${lbg_chop_options[$lbg_chop_i]}\","

				# set default option
				if [ $lbg_chop_default != 0 ] ; then
					if [ $lbg_chop_default == $lbg_chop_i ] ; then
						lbg_chop_default_option=${lbg_chop_options[$lbg_chop_i]}
					fi
				fi
			done

			# delete last comma
			lbg_chop_opts="${lbg_chop_opts%?}}"

			# execute command
			lbg_chop_choice=$(osascript 2> /dev/null <<EOF
set answer to (choose from list $lbg_chop_opts with prompt "$lbg_chop_label" default items "$lbg_chop_default_option" with title "$lbg_chop_title")
EOF)
			# if empty, error
			if [ -z "$lbg_chop_choice" ] ; then
				return 2
			fi

			# macOS case: find result
			for ((lbg_chop_i=1 ; lbg_chop_i <= ${#lbg_chop_options[@]}-1 ; lbg_chop_i++)) ; do
				if [ "$lbg_chop_choice" == "${lbg_chop_options[$lbg_chop_i]}" ] ; then
					lbg_choose_option=$lbg_chop_i
				fi
			done
			;;

		cscript)
			# avoid \n in label
			lbg_chop_label=$(echo -e "$lbg_chop_label")

			# add options to the label, with a line return between each option
			for ((lbg_chop_i=1 ; lbg_chop_i <= ${#lbg_chop_options[@]}-1 ; lbg_chop_i++)) ; do
				lbg_chop_label+=$(echo -e "\n   $lbg_chop_i. ${lbg_chop_options[$lbg_chop_i]}")
			done

			# prepare command (inputbox)
			lbg_chop_cmd=("${lbg_cscript[@]}")
			lbg_chop_cmd+=(lbg_input_text "$lbg_chop_label" "$lbg_chop_title")
			if [ $lbg_chop_default != 0 ] ; then
				lbg_chop_cmd+=("$lbg_chop_default")
			fi

			# run VBscript into a context (cscript does not work with absolute paths)
			lbg_choose_option=$(cd "$lbg_vbscript_directory" && "${lbg_chop_cmd[@]}")

			# cancelled
			if [ $? != 0 ] ; then
				return 2
			fi

			# remove \r ending character
			lbg_choose_option=${lbg_choose_option:0:${#lbg_choose_option}-1}
			;;

		dialog)
			lbg_chop_cmd=(dialog --title "$lbg_chop_title" --clear --radiolist "$lbg_chop_label" $(lbg_dialog_size 100 30) 1000)

			# add options
			for ((lbg_chop_i=1 ; lbg_chop_i <= ${#lbg_chop_options[@]}-1 ; lbg_chop_i++)) ; do
				lbg_chop_cmd+=($lbg_chop_i "${lbg_chop_options[$lbg_chop_i]}")
				if [ $lbg_chop_i == $lbg_chop_default ] ; then
					lbg_chop_cmd+=(on)
				else
					lbg_chop_cmd+=(off)
				fi
			done

			# run command (complex case)
			exec 3>&1
			lbg_choose_option=$("${lbg_chop_cmd[@]}" 2>&1 1>&3)
			exec 3>&-

			# clear console
			clear
			;;

		*)
			# console mode
			lbg_chop_cmd=(lb_choose_option)
			if [ $lbg_chop_default -gt 0 ] ; then
				lbg_chop_cmd+=(-d $lbg_chop_default)
			fi
			lbg_chop_cmd+=(-l "$lbg_chop_label")

			# add options
			for ((lbg_chop_i=1 ; lbg_chop_i <= ${#lbg_chop_options[@]}-1 ; lbg_chop_i++)) ; do
				lbg_chop_cmd+=("${lbg_chop_options[$lbg_chop_i]}")
			done

			# execute console function
			"${lbg_chop_cmd[@]}"
			if [ $? == 0 ] ; then
				# forward result
				lbg_choose_option=$lb_choose_option
			fi
			;;
	esac

	# if empty, cancelled
	if [ -z "$lbg_choose_option" ] ; then
		return 2
	fi

	# check if user choice is an integer
	if ! lb_is_integer $lbg_choose_option ; then
		# reset result and return error
		lbg_choose_option=""
		return 3
	fi

	# check if user choice is valid
	if [ "$lbg_choose_option" -lt 1 ] || [ "$lbg_choose_option" -ge ${#lbg_chop_options[@]} ] ; then
		# reset result and return error
		lbg_choose_option=""
		return 3
	fi
}


# Ask user to enter a text
# Usage: lbg_input_text [OPTIONS] TEXT
lbg_input_text=""
lbg_input_text() {

	# reset result
	lbg_input_text=""

	# default options
	local lbg_inp_default=""
	local lbg_inp_title=$lb_current_script_name

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			-d|--default)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_inp_default=$2
				shift
				;;
			-t|--title)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_inp_title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if no text to display
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# run command
	case $lbg_gui in
		kdialog)
			lbg_input_text=$(kdialog --title "$lbg_inp_title" --inputbox "$*" "$lbg_inp_default" 2> /dev/null)
			;;

		zenity)
			lbg_input_text=$(zenity --entry --title "$lbg_inp_title" --entry-text "$lbg_inp_default" --text "$*" 2> /dev/null)
			;;

		osascript)
			lbg_input_text=$(osascript 2> /dev/null << EOF
set answer to the text returned of (display dialog "$*" with title "$lbg_inp_title" default answer "$lbg_inp_default")
EOF)
			;;

		cscript)
			# prepare command
			lbg_inp_cmd=("${lbg_cscript[@]}")
			lbg_inp_cmd+=(lbg_input_text "$(echo -e "$*")" "$lbg_inp_title")
			if [ -n "$lbg_inp_default" ] ; then
				lbg_inp_cmd+=("$lbg_inp_default")
			fi

			# run VBscript into a context (cscript does not work with absolute paths)
			lbg_input_text=$(cd "$lbg_vbscript_directory" && "${lbg_inp_cmd[@]}")

			# cancelled
			if [ $? != 0 ] ; then
				return 2
			fi

			# remove \r ending character
			lbg_input_text=${lbg_input_text:0:${#lbg_input_text}-1}
			;;

		dialog)
			# run command (complex case)
			exec 3>&1
			lbg_input_text=$(dialog --title "$lbg_inp_title" --clear --inputbox "$*" $(lbg_dialog_size 100 10) "$lbg_inp_default" 2>&1 1>&3)
			exec 3>&-

			# clear console
			clear
			;;

		*)
			# console mode
			lbg_inp_cmd=(lb_input_text)
			if [ -n "$lbg_inp_default" ] ; then
				lbg_inp_cmd+=(-d "$lbg_inp_default")
			fi
			lbg_inp_cmd+=("$*")

			# execute console function
			"${lbg_inp_cmd[@]}"
			if [ $? == 0 ] ; then
				# forward result
				lbg_input_text=$lb_input_text
			fi
			;;
	esac

	# if empty, return cancelled
	if [ -z "$lbg_input_text" ] ; then
		return 2
	fi
}


# Ask user to enter a password
# Usage: lbg_input_password [OPTIONS] [TEXT]
lbg_input_password=""
lbg_input_password() {

	# reset result
	lbg_input_password=""

	# default options
	local lbg_inpw_label=$lb_default_pwd_label
	local lbg_inpw_confirm=false
	local lbg_inpw_confirm_label=$lb_default_pwd_confirm_label
	local lbg_inpw_title=$lb_current_script_name
	local lbg_inpw_minsize=0

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			-l|--label) # old option kept for compatibility
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_inpw_label=$2
				shift
				;;
			-c|--confirm)
				lbg_inpw_confirm=true
				;;
			--confirm-label)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_inpw_confirm_label=$2
				shift
				;;
			-m|--min-size)
				if ! lb_is_integer $2 ; then
					return 1
				fi
				if [ $2 -lt 1 ] ; then
					return 1
				fi
				lbg_inpw_minsize=$2
				shift
				;;
			-t|--title)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_inpw_title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# text label
	if [ -n "$*" ] ; then
		lbg_inpw_label=$*
	fi

	# display dialog
	for lbg_inpw_i in 1 2 ; do

		# run command
		case $lbg_gui in
			kdialog)
				lbg_input_password=$(kdialog --title "$lbg_inpw_title" --password "$lbg_inpw_label" 2> /dev/null)
				;;

			zenity)
				# zenity does not support labels, so we put it in the dialog title
				lbg_input_password=$(zenity --title "$lbg_inpw_label" --password 2> /dev/null)
				;;

			osascript)
				lbg_input_password=$(osascript 2> /dev/null << EOF
set answer to the text returned of (display dialog "$lbg_inpw_label" with title "$lbg_inpw_title" default answer "" hidden answer true)
EOF)
				;;

			dialog)
				# run command (complex case)
				exec 3>&1
				lbg_input_password=$(dialog --title "$lbg_inpw_title" --clear --passwordbox "$lbg_inpw_label" $(lbg_dialog_size 50 10) 2>&1 1>&3)
				exec 3>&-

				# clear console
				clear
				;;

			*)
				# console mode
				# execute console function
				lb_input_password --label "$lbg_inpw_label"
				lbg_inpw_res=$?
				if [ $lbg_inpw_res == 0 ] ; then
					# forward result
					lbg_input_password=$lb_input_password
				else
					return $lbg_inpw_res
				fi
				;;
		esac

		# if empty, return cancelled
		if [ -z "$lbg_input_password" ] ; then
			return 2
		fi

		# check password size (if --min-size option is set)
		if [ $lbg_inpw_minsize -gt 0 ] ; then
			if [ $(echo -n "$lbg_input_password" | wc -m) -lt $lbg_inpw_minsize ] ; then
				lbg_input_password=""
				return 4
			fi
		fi

		# if no confirm, quit
		if ! $lbg_inpw_confirm ; then
			return 0
		fi

		# if first iteration,
		if [ $lbg_inpw_i == 1 ] ; then
			# save password
			lbg_inpw_password_confirm=$lbg_input_password

			# set new confirm label and continue
			lbg_inpw_label=$lbg_inpw_confirm_label
		else
			# if 2nd iteration (confirmation)
			# comparison with confirm password
			if [ "$lbg_input_password" != "$lbg_inpw_password_confirm" ] ; then
				lbg_input_password=""
				return 3
			fi

			# quit
			return 0
		fi
	done

	return 0
}


###########################
#  FILES AND DIRECTORIES  #
###########################

# Ask user to choose an existing directory
# Usage: lbg_choose_directory [OPTIONS] [PATH]
lbg_choose_directory=""
lbg_choose_directory() {

	# reset result
	lbg_choose_directory=""

	# default options
	local lbg_chdir_title=$lb_current_script_name
	local lbg_chdir_absolute=false

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			-a|--absolute-path)
				lbg_chdir_absolute=true
				;;
			-t|--title)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_chdir_title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# if no path specified, use current
	if lb_test_arguments -eq 0 $* ; then
		lbg_chdir_path=$lb_current_path
	else
		lbg_chdir_path=$*
	fi

	# if path is not a directory, usage error
	if ! [ -d "$lbg_chdir_path" ] ; then
		return 1
	fi

	# run command
	case $lbg_gui in
		kdialog)
			lbg_chdir_choice=$(kdialog --title "$lbg_chdir_title" --getexistingdirectory "$lbg_chdir_path" 2> /dev/null)
			;;

		zenity)
			lbg_chdir_choice=$(zenity --title "$lbg_chdir_title" --file-selection --directory --filename "$lbg_chdir_path" 2> /dev/null)
			;;

		osascript)
			lbg_chdir_choice=$(osascript 2> /dev/null <<EOF
set answer to POSIX path of (choose folder with prompt "$lbg_chdir_title" default location "$lbg_chdir_path")
EOF)
			;;

		cscript)
			# prepare command
			lbg_chdir_cmd=("${lbg_cscript[@]}")
			lbg_chdir_cmd+=(lbg_choose_directory)

			# if title is not defined,
			if [ "$lbg_chdir_title" == "$lb_current_script_name" ] ; then
				# print default label
				lbg_chdir_cmd+=("$lb_default_chdir_label")
			else
				# print title as label
				lbg_chdir_cmd+=("$lbg_chdir_title")
			fi

			# run VBscript into a context (cscript does not work with absolute paths)
			lbg_chdir_choice=$(cd "$lbg_vbscript_directory" && "${lbg_chdir_cmd[@]}")

			# cancelled
			if [ $? != 0 ] ; then
				return 2
			fi

			# remove \r ending character
			lbg_chdir_choice=${lbg_chdir_choice:0:${#lbg_chdir_choice}-1}
			;;

		dialog)
			# run command (complex case)
			exec 3>&1
			lbg_chdir_choice=$(dialog --title "$lbg_chdir_title" --clear --dselect "$lbg_chdir_path" $(lbg_dialog_size 100 30) 2>&1 1>&3)
			exec 3>&-

			# clear console
			clear
			;;

		*)
			# console mode
			lbg_chdir_cmd=(lb_input_text -d "$lbg_chdir_path")

			# set dialog title as label
			if [ "$lbg_chdir_title" == "$lb_current_script_name" ] ; then
				lbg_chdir_cmd+=("$lb_default_chdir_label")
			else
				lbg_chdir_cmd+=("$lbg_chdir_title")
			fi

			# execute console function
			"${lbg_chdir_cmd[@]}"
			if [ $? == 0 ] ; then
				# forward result
				lbg_chdir_choice=$lb_input_text
			fi
			;;
	esac

	# if empty, cancelled
	if [ -z "$lbg_chdir_choice" ] ; then
		return 2
	fi

	# return windows paths
	if [ "$lb_current_os" == "Windows" ] ; then
		lbg_chdir_choice=$(lb_realpath "$lbg_chdir_choice")
		if [ $? != 0 ] ; then
			return 3
		fi
	fi

	# if not a directory, return error
	if ! [ -d "$lbg_chdir_choice" ] ; then
		return 3
	fi

	# save path
	lbg_choose_directory=$lbg_chdir_choice

	# return absolute path if option set
	if $lbg_chdir_absolute ; then
		lbg_choose_directory=$(lb_abspath "$lbg_choose_directory")
		if [ $? != 0 ] ; then
			# in case of error, user can get returned path
			return 4
		fi
	fi
}


# Ask user to choose a file
# Usage: lbg_choose_file [OPTIONS] [PATH]
lbg_choose_file=""
lbg_choose_file() {

	# reset result
	lbg_choose_file=""

	# default options
	local lbg_choosefile_save=false
	local lbg_choosefile_title=$lb_current_script_name
	local lbg_choosefile_path=""
	local lbg_choosefile_filters=()
	local lbg_choosefile_absolute=false

	# catch options
	while [ -n "$1" ] ; do
		case $1 in
			-s|--save)
				lbg_choosefile_save=true
				;;
			-f|--filter)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_choosefile_filters+=("$2")
				shift
				;;
			-a|--absolute-path)
				lbg_choosefile_absolute=true
				;;
			-t|--title)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_choosefile_title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# if no path specified, use current directory
	if lb_test_arguments -eq 0 $* ; then
		lbg_choosefile_path=$lb_current_path
	else
		lbg_choosefile_path=$*
	fi

	# if directory does not exists (save mode), error
	if $lbg_choosefile_save ; then
		if ! [ -d "$(dirname "$lbg_choosefile_path")" ] ; then
			return 1
		fi
	else
		# if path does not exists (open mode), error
		if ! [ -e "$lbg_choosefile_path" ] ; then
			return 1
		fi
	fi

	# display dialog
	case $lbg_gui in
		kdialog)
			# kdialog has a strange behaviour: it takes a path but only as a file name.
			# it starts on the current directory path. This is a hack to work:
			lbg_choosefile_pathfile="."
			if ! [ -d "$lbg_choosefile_path" ] ; then
				lbg_choosefile_pathfile=$(basename "$lbg_choosefile_path")
				lbg_choosefile_path=$(dirname "$lbg_choosefile_path")
			fi

			# set mode (open or save)
			if $lbg_choosefile_save ; then
				lbg_choosefile_mode="--getsavefilename"
			else
				lbg_choosefile_mode="--getopenfilename"
			fi

			# go into the directory then open kdialog
			lbg_choosefile_choice=$(cd "$lbg_choosefile_path" &> /dev/null; kdialog --title "$lbg_choosefile_title" $lbg_choosefile_mode "$lbg_choosefile_pathfile" "${lbg_choosefile_filters[@]}" 2> /dev/null)
			;;

		zenity)
			local lbg_choosefile_opts=""
			if [ ${#lbg_choosefile_filters[@]} -gt 0 ] ; then
				lbg_choosefile_opts=--file-filter="${lbg_choosefile_filters[@]}"
			fi

			# set save mode
			if $lbg_choosefile_save ; then
				lbg_choosefile_opts="--save"
			fi

			lbg_choosefile_choice=$(zenity --title "$lbg_choosefile_title" --file-selection $lbg_choosefile_opts --filename "$lbg_choosefile_path" "$lbg_choosefile_opts" 2> /dev/null)
			;;

		osascript)
			local lbg_choosefile_opts=""
			local lbg_choosefile_file=$lb_default_newfile_name

			# set save mode
			if $lbg_choosefile_save ; then
				lbg_choosefile_mode="name"

				if ! [ -d "$lbg_choosefile_path" ] ; then
					lbg_choosefile_file=$(basename "$lbg_choosefile_path")
					lbg_choosefile_path=$(dirname "$lbg_choosefile_path")
				fi

				lbg_choosefile_opts="default name \"$lbg_choosefile_file\""
			fi

			lbg_choosefile_choice=$(osascript 2> /dev/null <<EOF
set answer to POSIX path of (choose file $lbg_choosefile_mode with prompt "$lbg_choosefile_title" $lbg_choosefile_opts default location "$lbg_choosefile_path")
EOF)
			;;

		dialog)
			# execute dialog (complex case)
			exec 3>&1
			lbg_choosefile_choice=$(dialog --title "$lbg_choosefile_title" --clear --fselect "$lbg_choosefile_path" $(lbg_dialog_size 100 30) 2>&1 1>&3)
			exec 3>&-

			# clear console
			clear
			;;

		*)
			# console mode
			lbg_choosefile_cmd=(lb_input_text -d "$lbg_choosefile_path")

			# set dialog title as label
			if [ "$lbg_choosefile_title" == "$lb_current_script_name" ] ; then
				lbg_choosefile_cmd+=("$lb_default_chfile_label")
			else
				lbg_choosefile_cmd+=("$lbg_choosefile_title")
			fi

			# execute console function
			"${lbg_choosefile_cmd[@]}"
			if [ $? == 0 ] ; then
				# forward result
				lbg_choosefile_choice=$lb_input_text
			fi
			;;
	esac

	# if empty, cancelled
	if [ -z "$lbg_choosefile_choice" ] ; then
		return 2
	fi

	# return windows paths
	if [ "$lb_current_os" == "Windows" ] ; then

		# beware the save mode where file does not exists!
		if $lbg_choosefile_save ; then
			lbg_choosefile_choice="$(lb_realpath "$(dirname "$lbg_choosefile_choice")")/$(basename "$lbg_choosefile_choice")"
		else
			lbg_choosefile_choice=$(lb_realpath "$lbg_choosefile_choice")
		fi
		if [ $? != 0 ] ; then
			return 3
		fi
	fi

	# if save mode,
	if $lbg_choosefile_save ; then
		# if directory parent does not exists, reset variable and return error
		if ! [ -d "$(dirname "$lbg_choosefile_choice")" ] ; then
			return 3
		fi

		# if exists but is not a file, return error
		if [ -e "$lbg_choosefile_choice" ] ; then
			if ! [ -f "$lbg_choosefile_choice" ] ; then
				return 3
			fi
		fi
	else
		# open mode
		# if file does not exists, reset variable and return error
		if ! [ -f "$lbg_choosefile_choice" ] ; then
			return 3
		fi
	fi

	# return absolute path if option set
	if $lbg_choosefile_absolute ; then
		lbg_choose_file=$(lb_abspath "$lbg_choosefile_choice")
		if [ $? != 0 ] ; then
			# in case of error, user can get returned path
			return 4
		fi
	else
		# return choice
		lbg_choose_file=$lbg_choosefile_choice
	fi
}


# Open a directory in the folder explorer
# Usage: lbg_open_directory [OPTIONS] [PATH...]
lbg_open_directory() {

	# default options
	local lbg_opdir_explorer=""
	local lbg_opdir_paths=()
	local lbg_opdir_result=0

	# catch options
	while [ -n "$1" ] ; do
		case $1 in
			-e|--explorer)
				if [ -z "$2" ] ; then
					return 1
				fi
				lbg_opdir_explorer="$2"
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# if no path specified, use current directory
	if [ -z "$*" ] ; then
		lbg_opdir_paths=("$lb_current_path")
	fi

	# get specified path(s)
	while [ -n "$1" ] ; do
		# if not a directory, ignore it
		if [ -d "$1" ] ; then
			lbg_opdir_paths+=("$1")
		else
			lbg_opdir_result=4
		fi
		shift
	done

	# if no existing directory, usage error
	if [ ${#lbg_opdir_paths[@]} == 0 ] ; then
		return 1
	fi

	# set OS explorer if not specified
	if [ -z "$lbg_opdir_explorer" ] ; then
		case $lb_current_os in
			Linux)
				lbg_opdir_explorer=xdg-open
				;;
			macOS)
				lbg_opdir_explorer=open
				;;
			Windows)
				lbg_opdir_explorer=explorer
				;;
		esac
	fi

	# test explorer command
	if ! lb_command_exists "$lbg_opdir_explorer" ; then
		return 2
	fi

	# open directories one by one
	for ((lbg_opdir_i=0; lbg_opdir_i<${#lbg_opdir_paths[@]}; lbg_opdir_i++)) ; do
		lbg_opdir_path=${lbg_opdir_paths[$lbg_opdir_i]}

		if [ "lb_current_os" == Windows ] ; then
			# particular case where explorer will not work if path finishes with '/'
			if [ "${lbg_opdir_path:${#lbg_opdir_path}-1}" == "/" ] ; then
				lbg_opdir_path=${lbg_opdir_path:0:${#lbg_opdir_path}-1}
			fi

			# convert to Windows paths
			lbg_opdir_path=$(cygpath -w "$lbg_opdir_path")
		fi

		# open file explorer
		"$lbg_opdir_explorer" "$lbg_opdir_path"
		if [ $? != 0 ] ; then
			lbg_opdir_result=3
		fi
	done

	return $lbg_opdir_result
}


###############################
#  ALIASES AND COMPATIBILITY  #
###############################

# Display a critical dialog
# See lbg_display_error for usage
lbg_display_critical() {
	# basic command
	lbg_cmd=(lbg_display_error)

	# parse arguments
	while [ -n "$1" ] ; do
		lbg_cmd+=("$1")
		shift
	done

	# run command
	"${lbg_cmd[@]}"
}

lbg_critical() {
	# basic command
	lbg_cmd=(lbg_display_error)

	# parse arguments
	while [ -n "$1" ] ; do
		lbg_cmd+=("$1")
		shift
	done

	# run command
	"${lbg_cmd[@]}"
}

# Display a debug dialog
# See lbg_display_info for usage
lbg_display_debug() {
	# basic command
	lbg_cmd=(lbg_display_info)

	# parse arguments
	while [ -n "$1" ] ; do
		lbg_cmd+=("$1")
		shift
	done

	# run command
	"${lbg_cmd[@]}"
}

lbg_debug() {
	# basic command
	lbg_cmd=(lbg_display_info)

	# parse arguments
	while [ -n "$1" ] ; do
		lbg_cmd+=("$1")
		shift
	done

	# run command
	"${lbg_cmd[@]}"
}

# Aliases for dialogs
lbg_info() {
	# basic command
	lbg_cmd=(lbg_display_info)

	# parse arguments
	while [ -n "$1" ] ; do
		lbg_cmd+=("$1")
		shift
	done

	# run command
	"${lbg_cmd[@]}"
}

lbg_warning() {
	# basic command
	lbg_cmd=(lbg_display_warning)

	# parse arguments
	while [ -n "$1" ] ; do
		lbg_cmd+=("$1")
		shift
	done

	# run command
	"${lbg_cmd[@]}"
}

lbg_error() {
	# basic command
	lbg_cmd=(lbg_display_error)

	# parse arguments
	while [ -n "$1" ] ; do
		lbg_cmd+=("$1")
		shift
	done

	# run command
	"${lbg_cmd[@]}"
}


####################
#  INITIALIZATION  #
####################

# set the default GUI tool
lbg_set_gui
