########################################################
#                                                      #
#  libbash.sh GUI                                      #
#  Functions to extend bash scripts to GUI tools       #
#                                                      #
#  MIT License                                         #
#  Copyright (c) 2017-2019 Jean Prunneaux              #
#  Website: https://github.com/pruje/libbash.sh        #
#                                                      #
#  Version 1.10.0 (2019-01-19)                         #
#                                                      #
########################################################

# Index
#
#   * Main variables
#   * Internal functions
#       lbg_get_console_size
#       lbg_dialog_size
#       lbg_osascript
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
# Return: HEIGHT WIDTH
# e.g. dialog --msgbox "Hello world" $(lbg_dialog_size 50 10)
lbg_dialog_size() {

	# given size
	local dialog_width=$1 dialog_height=$2

	# if max width > console width, fit to console width
	if [ "$dialog_width" -gt "$lbg_console_width" ] ; then
		dialog_width=$lbg_console_width
	fi

	# if max height > console height, fit to console height
	if [ "$dialog_height" -gt "$lbg_console_height" ] ; then
		dialog_height=$lbg_console_height
	fi

	# return height width
	echo $dialog_height $dialog_width
}


###############
#  GUI TOOLS  #
###############

# Get current GUI tool
# Usage: lbg_get_gui
lbg_get_gui() {

	# no GUI tool defined
	[ -z "$lbg_gui" ] && return 1

	# return current GUI tool
	echo $lbg_gui
}


# Set GUI display to use
# Usage: lbg_set_gui [GUI_TOOL...]
lbg_set_gui() {

	# default options
	local gui_tools=(${lbg_supported_gui[@]}) result=0

	# if args set, test list of commands
	if [ $# -gt 0 ] ; then
		gui_tools=($*)
	fi

	# test GUI tools
	local gui
	for gui in ${gui_tools[@]} ; do

		# set console mode is always OK
		if [ "$gui" == console ] ; then
			result=0
			break
		fi

		# test if GUI is supported
		if ! lb_in_array "$gui" "${lbg_supported_gui[@]}" ; then
			result=1
			continue
		fi

		# test if command exists
		if ! lb_command_exists "$gui" ; then
			result=3
			continue
		fi

		# dialog command
		case $gui in
			dialog)
				# get console size
				if ! lbg_get_console_size ; then
					result=4
					continue
				fi
				;;
			osascript)
				# test OS
				if [ "$lb_current_os" != macOS ] ; then
					result=4
					continue
				fi
				;;
			cscript)
				# test OS
				if [ "$lb_current_os" != Windows ] ; then
					result=4
					continue
				fi

				# test VB script
				if ! [ -f "$lbg_vbscript_directory/$lbg_vbscript" ] ; then
					result=4
					continue
				fi
				;;
			*)
				# test if X server started (only for Linux and Windows)
				if [ "$lb_current_os" != macOS ] ; then
					if [ -z "$DISPLAY" ] ; then
						result=4
						continue
					fi
				fi
				;;
		esac

		# all tests passed: tool can be set
		result=0
		break
	done

	# set gui tool
	if [ $result == 0 ] ; then
		lbg_gui=$gui
	fi

	return $result
}


################################
#  MESSAGES AND NOTIFICATIONS  #
################################

# Display an info dialog
# Usage: lbg_display_info [OPTIONS] TEXT
lbg_display_info() {

	# default options
	local title=$lb_current_script_name

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-t|--title)
				[ -z "$2" ] && return 1
				title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if no text to display
	[ -z "$1" ] && return 1

	# prepare command
	local cmd
	case $lbg_gui in
		kdialog)
			cmd=(kdialog --title "$title" --msgbox "$*")
			;;

		zenity)
			cmd=(zenity --title "$title" --info --text "$*")
			;;

		osascript)
			# run command
			$(osascript &> /dev/null << EOF
display dialog "$*" with title "$title" with icon note buttons {"$lb_default_ok_label"} default button 1
EOF) || return 2

			return 0
			;;

		cscript)
			cmd=("${lbg_cscript[@]}")
			cmd+=(lbg_display_info "$(echo -e "$*")" "$title")

			# run VBscript into a context (cscript does not work with absolute paths)
			# and quit
			$(cd "$lbg_vbscript_directory" && "${cmd[@]}") || return 2
			return 0
			;;

		dialog)
			local result=0
			dialog --title "$title" --clear --msgbox "$*" $(lbg_dialog_size 50 10) 2> /dev/null || result=$?

			# clear console
			clear

			# command error
			[ $result != 0 ] && return 2
			return 0
			;;

		*)
			# console mode
			cmd=(lb_display_info "$*")
			;;
	esac

	# run command
	"${cmd[@]}" 2> /dev/null || return 2
}


# Display a warning message
# Usage: lbg_display_warning [OPTIONS] TEXT
lbg_display_warning() {

	# default options
	local title=$lb_current_script_name

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-t|--title)
				[ -z "$2" ] && return 1
				title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if no text to display
	[ -z "$1" ] && return 1

	# prepare command
	local cmd
	case $lbg_gui in
		kdialog)
			cmd=(kdialog --title "$title" --sorry "$*")
			;;

		zenity)
			cmd=(zenity --title "$title" --warning --text "$*")
			;;

		osascript)
			# run command
			$(osascript &> /dev/null << EOF
display dialog "$*" with title "$title" with icon caution buttons {"$lb_default_ok_label"} default button 1
EOF) || return 2

			return 0
			;;

		cscript)
			cmd=("${lbg_cscript[@]}")
			cmd+=(lbg_display_warning "$(echo -e "$*")" "$title")

			# run VBscript into a context (cscript does not work with absolute paths)
			$(cd "$lbg_vbscript_directory" && "${cmd[@]}") || return 2
			return 0
			;;

		dialog)
			# same command as lbg_display_info, but we add warning prefix
			cmd=(lbg_display_info "$lb_default_warning_label: $*")
			;;

		*)
			# console mode
			cmd=(lb_display_warning "$*")
			;;
	esac

	# run command
	"${cmd[@]}" 2> /dev/null || return 2
}


# Display an error message
# Usage: lbg_display_error [OPTIONS] TEXT
lbg_display_error() {

	# default options
	local title=$lb_current_script_name

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-t|--title)
				[ -z "$2" ] && return 1
				title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if no text to display
	[ -z "$1" ] && return 1

	# prepare command
	local cmd
	case $lbg_gui in
		kdialog)
			cmd=(kdialog --title "$title" --error "$*")
			;;

		zenity)
			cmd=(zenity --title "$title" --error --text "$*")
			;;

		osascript)
			# run command
			$(osascript &> /dev/null << EOF
display dialog "$*" with title "$title" with icon stop buttons {"$lb_default_ok_label"} default button 1
EOF) || return 2

			return 0
			;;

		cscript)
			cmd=("${lbg_cscript[@]}")
			cmd+=(lbg_display_error "$(echo -e "$*")" "$title")

			# run VBscript into a context (cscript does not work with absolute paths)
			$(cd "$lbg_vbscript_directory" && "${cmd[@]}") || return 2
			return 0
			;;

		dialog)
			# same command as lbg_display_info, but we add error prefix
			cmd=(lbg_display_info "$lb_default_error_label: $*")
			;;

		*)
			# console mode
			cmd=(lb_display_error $*)
			;;
	esac

	# run command
	"${cmd[@]}" 2> /dev/null || return 2
}


# Display a notification popup
# Usage: lbg_notify [OPTIONS] TEXT
lbg_notify() {

	# default options
	local timeout use_notifysend=true title=$lb_current_script_name

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-t|--title)
				[ -z "$2" ] && return 1
				title=$2
				shift
				;;
			--timeout)
				lb_is_integer $2 || return 1
				timeout=$2
				shift
				;;
			--no-notify-send)
				# do not use notify-send command if available
				use_notifysend=false
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if no text
	[ -z "$1" ] && return 1

	local opts

	# if notify-send is installed, use it by default,
	# as it is better than zenity or other system
	if lb_command_exists notify-send ; then
		if $use_notifysend ; then
			# do not override kdialog because it has the best integration to KDE desktop
			# do not use it on macOS nor in console mode
			if ! lb_in_array "$lbg_gui" kdialog osascript console ; then
				# execute command with timeout in milliseconds
				if [ -n "$timeout" ] ; then
					opts="-t $(($timeout * 1000)) "
				fi

				# push notification and return
				notify-send $opts"$title" "$*" || return 2
				return 0
			fi
		fi
	fi

	# run command
	case $lbg_gui in
		kdialog)
			kdialog --title "$title" --passivepopup "$*" $timeout 2> /dev/null || return 2
			;;

		zenity)
			opts=""

			# set a timeout
			if [ -n "$timeout" ] ; then
				opts="--timeout=$timeout"
			fi

			# run command
			zenity --notification $opts --text "$*" 2> /dev/null || return 2
			;;

		osascript)
			$(osascript &> /dev/null << EOF
display notification "$*" with title "$title"
EOF) || return 2
			;;

		# no dialog command, because it doesn't make sense in console

		*)
			# print in console mode
			lb_display "[$lb_default_info_label]  $*" || return 2
			;;
	esac
}


######################
#  USER INTERACTION  #
######################

# Prompt user to confirm an action
# Usage: lbg_yesno [OPTIONS] TEXT
# SOME OPTIONS ARE NOT AVAILABLE ON WINDOWS
lbg_yesno() {

	# default options
	local yes_label no_label yes_default=false title=$lb_current_script_name

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-y|--yes)
				yes_default=true
				;;
			--yes-label)
				[ -z "$2" ] && return 1
				yes_label=$2
				shift
				;;
			--no-label)
				[ -z "$2" ] && return 1
				no_label=$2
				shift
				;;
			-t|--title)
				[ -z "$2" ] && return 1
				title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if no text to display
	[ -z "$1" ] && return 1

	local cmd result=0

	# prepare command
	case $lbg_gui in
		kdialog)
			cmd=(kdialog --title "$title")
			if [ -n "$yes_label" ] ; then
				cmd+=(--yes-label "$yes_label")
			fi
			if [ -n "$no_label" ] ; then
				cmd+=(--no-label "$no_label")
			fi
			cmd+=(--yesno "$*")
			;;

		zenity)
			cmd=(zenity --question --title "$title" --text "$*")
			;;

		osascript)
			# set button labels
			if [ -z "$yes_label" ] ; then
				yes_label=$lb_default_yes_label
			fi
			if [ -z "$no_label" ] ; then
				no_label=$lb_default_no_label
			fi

			# set options
			local opts="default button "
			if $yes_default ; then
				opts+="1"
			else
				opts+="2"
			fi

			# run command
			result=$(osascript << EOF
set question to (display dialog "$*" with title "$title" buttons {"$yes_label", "$no_label"} $opts)
set answer to button returned of question
if answer is equal to "$yes_label" then
	return 0
else
	return 2
end if
EOF)
			# return choice
			return $result
			;;

		cscript)
			cmd=("${lbg_cscript[@]}")
			cmd+=(lbg_yesno "$(echo -e "$*")" "$title")
			if $yes_default ; then
				cmd+=(true)
			fi

			# run VBscript into a context (cscript does not work with absolute paths)
			$(cd "$lbg_vbscript_directory" && "${cmd[@]}") || return 2
			return 0
			;;

		dialog)
			cmd=(dialog --title "$title")
			if ! $yes_default ; then
				cmd+=(--defaultno)
			fi
			if [ -n "$yes_label" ] ; then
				cmd+=(--yes-label "$yes_label")
			fi
			if [ -n "$no_label" ] ; then
				cmd+=(--no-label "$no_label")
			fi
			cmd+=(--clear --yesno "$*" $(lbg_dialog_size 100 10))

			# run command
			"${cmd[@]}" || result=$?

			# clear console
			clear

			# return result
			case $result in
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
			cmd=(lb_yesno)
			if $yes_default ; then
				cmd+=(-y)
			fi
			if [ -n "$yes_label" ] ; then
				cmd+=(--yes-label "$yes_label")
			fi
			if [ -n "$no_label" ] ; then
				cmd+=(--no-label "$no_label")
			fi
			cmd+=("$*")
			;;
	esac

	# run command
	"${cmd[@]}" 2> /dev/null || return 2
}


# Ask user to choose an option
# Usage: lbg_choose_option [OPTIONS] CHOICE [CHOICE...]
lbg_choose_option=""
lbg_choose_option() {

	# reset result
	lbg_choose_option=""

	# default options
	local default=() multiple_choices=false
	local title=$lb_current_script_name label=$lb_default_chopt_label

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-d|--default)
				[ -z "$2" ] && return 1
				# transform option1,option2,... to array
				lb_split , $2
				default=(${lb_split[@]})
				shift
				;;
			-l|--label)
				[ -z "$2" ] && return 1
				label=$2
				shift
				;;
			-t|--title)
				[ -z "$2" ] && return 1
				title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if missing at least 1 choice option
	[ -z "$1" ] && return 1

	# options: initialize with an empty first value (option ID starts to 1, not 0)
	local options=("" "$@")

	# verify if default options are valid
	if [ ${#default[@]} -gt 0 ] ; then
		local d
		for d in ${default[@]} ; do
			if ! lb_is_integer $d ; then
				return 1
			fi
			if [ $d -lt 1 ] || [ $d -ge ${#options[@]} ] ; then
				return 1
			fi
		done
	else
		# initialize first choice as default
		default=(0)
	fi

	# prepare command
	local i cmd
	case $lbg_gui in
		kdialog)
			cmd=(kdialog --title "$title" --radiolist "$label")

			# add options
			for ((i=1 ; i <= ${#options[@]}-1 ; i++)) ; do
				cmd+=($i "${options[i]}")
				if lb_in_array "$i" "${default[@]}" ; then
					cmd+=(on)
				else
					cmd+=(off)
				fi
			done

			# run command
			lbg_choose_option=$("${cmd[@]}" 2> /dev/null)
			;;

		zenity)
			cmd=(zenity --list --title "$title" --text "$label" --radiolist --column "" --column "" --column "")

			# add options
			for ((i=1 ; i <= ${#options[@]}-1 ; i++)) ; do
				if lb_in_array "$i" "${default[@]}" ; then
					cmd+=(TRUE)
				else
					cmd+=(FALSE)
				fi

				cmd+=($i "${options[i]}")
			done

			# run command
			lbg_choose_option=$("${cmd[@]}" 2> /dev/null)
			;;

		osascript)
			# prepare options
			local default_option opts="{"

			for ((i=1 ; i <= ${#options[@]}-1 ; i++)) ; do
				opts+="\"${options[i]}\","

				# set default option
				if [ ${#default[@]} -gt 0 ] ; then
					if lb_in_array "$i" "${default[@]}" ; then
						default_option=${options[i]}
					fi
				fi
			done

			# delete last comma
			opts="${opts%?}}"

			# execute command
			local choice=$(osascript 2> /dev/null <<EOF
set answer to (choose from list $opts with prompt "$label" default items "$default_option" with title "$title")
EOF)
			# if empty, error
			[ -z "$choice" ] && return 2

			# macOS case: find result
			for ((i=1 ; i <= ${#options[@]}-1 ; i++)) ; do
				if [ "$choice" == "${options[i]}" ] ; then
					lbg_choose_option=$i
				fi
			done
			;;

		cscript)
			# avoid \n in label
			label=$(echo -e "$label")

			# add options to the label, with a line return between each option
			for ((i=1 ; i <= ${#options[@]}-1 ; i++)) ; do
				label+=$(echo -e "\n   $i. ${options[i]}")
			done

			# prepare command (inputbox)
			cmd=("${lbg_cscript[@]}")
			cmd+=(lbg_input_text "$label" "$title")
			for d in ${default[@]} ; do
				cmd+=($d)
			done

			# run VBscript into a context (cscript does not work with absolute paths)
			# error => cancelled
			lbg_choose_option=$(cd "$lbg_vbscript_directory" && "${cmd[@]}") || return 2

			# remove \r ending character
			lbg_choose_option=${lbg_choose_option:0:${#lbg_choose_option}-1}
			;;

		dialog)
			cmd=(dialog --title "$title" --clear --radiolist "$label" $(lbg_dialog_size 100 30) 1000)

			# add options
			for ((i=1 ; i <= ${#options[@]}-1 ; i++)) ; do
				cmd+=($i "${options[i]}")
				if lb_in_array "$i" "${default[@]}" ; then
					cmd+=(on)
				else
					cmd+=(off)
				fi
			done

			# run command (complex case)
			exec 3>&1
			lbg_choose_option=$("${cmd[@]}" 2>&1 1>&3)
			exec 3>&-

			# clear console
			clear
			;;

		*)
			# console mode
			cmd=(lb_choose_option)

			# add default without the first 0
			if [ "$default" != 0 ] ; then
				cmd+=(-d $(lb_join , ${default[@]}))
			fi
			cmd+=(-l "$label")

			# add options
			for ((i=1 ; i <= ${#options[@]}-1 ; i++)) ; do
				cmd+=("${options[i]}")
			done

			# execute console function
			if "${cmd[@]}" ; then
				# forward result
				lbg_choose_option=$lb_choose_option
			fi
			;;
	esac

	# if empty, cancelled
	[ -z "$lbg_choose_option" ] && return 2

	# check if user choice is an integer
	if ! lb_is_integer $lbg_choose_option ; then
		# reset result and return error
		lbg_choose_option=""
		return 3
	fi

	# check if user choice is valid
	if [ "$lbg_choose_option" -lt 1 ] || [ "$lbg_choose_option" -ge ${#options[@]} ] ; then
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
	local default title=$lb_current_script_name

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-d|--default)
				[ -z "$2" ] && return 1
				default=$2
				shift
				;;
			-t|--title)
				[ -z "$2" ] && return 1
				title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if no text to display
	[ -z "$1" ] && return 1

	# run command
	local cmd
	case $lbg_gui in
		kdialog)
			lbg_input_text=$(kdialog --title "$title" --inputbox "$*" "$default" 2> /dev/null)
			;;

		zenity)
			lbg_input_text=$(zenity --entry --title "$title" --entry-text "$default" --text "$*" 2> /dev/null)
			;;

		osascript)
			lbg_input_text=$(osascript 2> /dev/null << EOF
set answer to the text returned of (display dialog "$*" with title "$title" default answer "$default")
EOF)
			;;

		cscript)
			# prepare command
			cmd=("${lbg_cscript[@]}")
			cmd+=(lbg_input_text "$(echo -e "$*")" "$title")
			if [ -n "$default" ] ; then
				cmd+=("$default")
			fi

			# run VBscript into a context (cscript does not work with absolute paths)
			# error => cancelled
			lbg_input_text=$(cd "$lbg_vbscript_directory" && "${cmd[@]}") || return 2

			# remove \r ending character
			lbg_input_text=${lbg_input_text:0:${#lbg_input_text}-1}
			;;

		dialog)
			# run command (complex case)
			exec 3>&1
			lbg_input_text=$(dialog --title "$title" --clear --inputbox "$*" $(lbg_dialog_size 100 10) "$default" 2>&1 1>&3)
			exec 3>&-

			# clear console
			clear
			;;

		*)
			# console mode
			cmd=(lb_input_text)
			if [ -n "$default" ] ; then
				cmd+=(-d "$default")
			fi
			cmd+=("$*")

			# execute console function
			if "${cmd[@]}" ; then
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
	local label=$lb_default_pwd_label confirm_label=$lb_default_pwd_confirm_label
	local title=$lb_current_script_name confirm=false min_size=0

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-l|--label) # old option kept for compatibility
				[ -z "$2" ] && return 1
				label=$2
				shift
				;;
			-c|--confirm)
				confirm=true
				;;
			--confirm-label)
				[ -z "$2" ] && return 1
				confirm_label=$2
				shift
				;;
			-m|--min-size)
				lb_is_integer $2 || return 1
				[ $2 -lt 1 ] && return 1
				min_size=$2
				shift
				;;
			-t|--title)
				[ -z "$2" ] && return 1
				title=$2
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
		label=$*
	fi

	# display dialog
	local i result=0
	for i in 1 2 ; do

		# run command
		case $lbg_gui in
			kdialog)
				lbg_input_password=$(kdialog --title "$title" --password "$label" 2> /dev/null)
				;;

			zenity)
				# zenity does not support labels, so we put it in the dialog title
				lbg_input_password=$(zenity --title "$label" --password 2> /dev/null)
				;;

			osascript)
				lbg_input_password=$(osascript 2> /dev/null << EOF
set answer to the text returned of (display dialog "$label" with title "$title" default answer "" hidden answer true)
EOF)
				;;

			dialog)
				# run command (complex case)
				exec 3>&1
				lbg_input_password=$(dialog --title "$title" --clear --passwordbox "$label" $(lbg_dialog_size 50 10) 2>&1 1>&3)
				exec 3>&-

				# clear console
				clear
				;;

			*)
				# console mode
				# execute console function
				cmd=(lb_input_password --label "$label")
				if [ $min_size -gt 0 ] ; then
					cmd+=(--min-size $min_size)
				fi

				result=0
				"${cmd[@]}" || result=$?
				if [ $result == 0 ] ; then
					# forward result
					lbg_input_password=$lb_input_password
				else
					return $result
				fi
				;;
		esac

		# if empty, return cancelled
		if [ -z "$lbg_input_password" ] ; then
			return 2
		fi

		# check password size (if --min-size option is set)
		if [ $min_size -gt 0 ] ; then
			if [ $(echo -n "$lbg_input_password" | wc -m) -lt $min_size ] ; then
				lbg_input_password=""
				return 4
			fi
		fi

		# if no confirm, quit
		if ! $confirm ; then
			return 0
		fi

		# if first iteration,
		if [ $i == 1 ] ; then
			# save password
			local password_confirm=$lbg_input_password

			# set new confirm label and continue
			label=$confirm_label
		else
			# if 2nd iteration (confirmation)
			# comparison with confirm password
			if [ "$lbg_input_password" != "$password_confirm" ] ; then
				lbg_input_password=""
				return 3
			fi

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
	local path absolute_path=false title=$lb_current_script_name

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-a|--absolute-path)
				absolute_path=true
				;;
			-t|--title)
				[ -z "$2" ] && return 1
				title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# if no path specified, use current
	if [ -z "$1" ] ; then
		path=$lb_current_path
	else
		path=$*
	fi

	# path is not a directory
	[ -d "$path" ] || return 1

	# run command
	local cmd choice
	case $lbg_gui in
		kdialog)
			choice=$(kdialog --title "$title" --getexistingdirectory "$path" 2> /dev/null)
			;;

		zenity)
			choice=$(zenity --title "$title" --file-selection --directory --filename "$path" 2> /dev/null)
			;;

		osascript)
			choice=$(osascript 2> /dev/null <<EOF
set answer to POSIX path of (choose folder with prompt "$title" default location "$path")
EOF)
			;;

		cscript)
			# prepare command
			cmd=("${lbg_cscript[@]}")
			cmd+=(lbg_choose_directory)

			# if title is not defined,
			if [ "$title" == "$lb_current_script_name" ] ; then
				# print default label
				cmd+=("$lb_default_chdir_label")
			else
				# print title as label
				cmd+=("$title")
			fi

			# run VBscript into a context (cscript does not work with absolute paths)
			# error => cancelled
			choice=$(cd "$lbg_vbscript_directory" && "${cmd[@]}") || return 2

			# remove \r ending character
			choice=${choice:0:${#choice}-1}
			;;

		dialog)
			# run command (complex case)
			exec 3>&1
			choice=$(dialog --title "$title" --clear --dselect "$path" $(lbg_dialog_size 100 30) 2>&1 1>&3)
			exec 3>&-

			# clear console
			clear
			;;

		*)
			# console mode
			cmd=(lb_input_text -d "$path")

			# set dialog title as label
			if [ "$title" == "$lb_current_script_name" ] ; then
				cmd+=("$lb_default_chdir_label")
			else
				cmd+=("$title")
			fi

			# execute console function
			if "${cmd[@]}" ; then
				# forward result
				choice=$lb_input_text
			fi
			;;
	esac

	# if empty, cancelled
	[ -z "$choice" ] && return 2

	# return windows paths
	if [ "$lb_current_os" == Windows ] ; then
		choice=$(lb_realpath "$choice") || return 3
	fi

	# if not a directory, return error
	[ -d "$choice" ] || return 3

	# save path
	lbg_choose_directory=$choice

	# return absolute path if option set
	if $absolute_path ; then
		# in case of error, user can get returned path
		lbg_choose_directory=$(lb_abspath "$lbg_choose_directory") || return 4
	fi
}


# Ask user to choose a file
# Usage: lbg_choose_file [OPTIONS] [PATH]
lbg_choose_file=""
lbg_choose_file() {

	# reset result
	lbg_choose_file=""

	# default options
	local path filters=() absolute_path=false save_mode=false
	local title=$lb_current_script_name filename=$lb_default_newfile_name

	# catch options
	while [ $# -gt 0 ] ; do
		case $1 in
			-s|--save)
				save_mode=true
				;;
			-f|--filter)
				[ -z "$2" ] && return 1
				filters+=("$2")
				shift
				;;
			-a|--absolute-path)
				absolute_path=true
				;;
			-t|--title)
				[ -z "$2" ] && return 1
				title=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# if no path specified, use current directory
	if [ -z "$1" ] ; then
		path=$lb_current_path
	else
		path=$*
	fi

	if $save_mode ; then
		# if directory does not exists (save mode), error
		[ -d "$(dirname "$path")" ] || return 1
	else
		# if path does not exists (open mode), error
		[ -e "$path" ] || return 1
	fi

	# display dialog
	local cmd choice mode
	case $lbg_gui in
		kdialog)
			# kdialog has a strange behaviour: it takes a path but only as a file name and needs to be run from start directory.
			if [ -d "$path" ] ; then
				# open mode: do not set default file name
				if ! $save_mode ; then
					filename=.
				fi
			else
				filename=$(basename "$path")
				path=$(dirname "$path")
			fi

			# set mode (open or save)
			if $save_mode ; then
				mode="--getsavefilename"
			else
				mode="--getopenfilename"
			fi

			# go into the directory then open kdialog
			choice=$(cd "$path" &> /dev/null && kdialog --title "$title" $mode "$filename" "${filters[@]}" 2> /dev/null)
			;;

		zenity)
			# if save mode and no filename specified, set it
			if [ -d "$path" ] ; then
				if $save_mode ; then
					path+="/$filename"
				fi
			fi

			cmd=(zenity --title "$title" --file-selection --filename "$path")

			# set save mode
			if $save_mode ; then
				cmd+=(--save)
			fi

			# set filters
			if [ ${#filters[@]} -gt 0 ] ; then
				cmd+=("--file-filter=${filters[@]}")
			fi

			choice=$("${cmd[@]}" 2> /dev/null)
			;;

		osascript)
			local opts=""

			# set save mode
			if $save_mode ; then
				mode="name"

				if ! [ -d "$path" ] ; then
					filename=$(basename "$path")
					path=$(dirname "$path")
				fi

				opts="default name \"$filename\""
			fi

			choice=$(osascript 2> /dev/null <<EOF
set answer to POSIX path of (choose file $mode with prompt "$title" $opts default location "$path")
EOF)
			;;

		dialog)
			# execute dialog (complex case)
			exec 3>&1
			choice=$(dialog --title "$title" --clear --fselect "$path" $(lbg_dialog_size 100 30) 2>&1 1>&3)
			exec 3>&-

			# clear console
			clear
			;;

		*)
			# console mode
			cmd=(lb_input_text -d "$path")

			# set dialog title as label
			if [ "$title" == "$lb_current_script_name" ] ; then
				cmd+=("$lb_default_chfile_label")
			else
				cmd+=("$title")
			fi

			# execute console function
			if "${cmd[@]}" ; then
				# forward result
				choice=$lb_input_text
			fi
			;;
	esac

	# if empty, cancelled
	[ -z "$choice" ] && return 2

	# return windows paths
	if [ "$lb_current_os" == Windows ] ; then

		# beware the save mode where file does not exists!
		if $save_mode ; then
			choice="$(lb_realpath "$(dirname "$choice")")/$(basename "$choice")" || return 3
		else
			choice=$(lb_realpath "$choice") || return 3
		fi
	fi

	# if save mode,
	if $save_mode ; then
		# if parent directory does not exists, return error
		[ -d "$(dirname "$choice")" ] || return 3

		# if exists but is not a file, return error
		if [ -e "$choice" ] ; then
			[ -f "$choice" ] || return 3
		fi
	else
		# open mode
		# if file does not exists, reset variable and return error
		[ -f "$choice" ] || return 3
	fi

	# return absolute path if option set
	if $absolute_path ; then
		# in case of error, user can get returned path
		lbg_choose_file=$(lb_abspath "$choice") || return 4
	else
		# return choice
		lbg_choose_file=$choice
	fi
}


# Open a directory in the folder explorer
# Usage: lbg_open_directory [OPTIONS] [PATH...]
lbg_open_directory() {

	# default options
	local explorer result=0 paths=()

	# catch options
	while [ $# -gt 0 ] ; do
		case $1 in
			-e|--explorer)
				[ -z "$2" ] && return 1
				explorer="$2"
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
		paths=("$lb_current_path")
	fi

	# get specified path(s)
	while [ -n "$1" ] ; do
		# if not a directory, ignore it
		if [ -d "$1" ] ; then
			paths+=("$1")
		else
			result=4
		fi
		shift
	done

	# if no existing directory, usage error
	[ ${#paths[@]} == 0 ] && return 1

	# set OS explorer if not specified
	if [ -z "$explorer" ] ; then
		case $lb_current_os in
			Linux)
				explorer=xdg-open
				;;
			macOS)
				explorer=open
				;;
			Windows)
				explorer=explorer
				;;
		esac
	fi

	# test explorer command
	lb_command_exists "$explorer" || return 2

	# open directories one by one
	local i path
	for ((i=0; i < ${#paths[@]}; i++)) ; do
		path=${paths[i]}

		if [ "lb_current_os" == Windows ] ; then
			# particular case where explorer will not work if path finishes with '/'
			if [ "${path:${#path}-1}" == "/" ] ; then
				path=${path:0:${#path}-1}
			fi

			# convert to Windows paths
			path=$(cygpath -w "$path")
		fi

		# open file explorer
		"$explorer" "$path" 2> /dev/null || result=3
	done

	return $result
}


###############################
#  ALIASES AND COMPATIBILITY  #
###############################

# Display a critical dialog
# See lbg_display_error for usage
lbg_display_critical() {
	lbg_display_error "$@"
}

lbg_critical() {
	lbg_display_error "$@"
}

# Display a debug dialog
# See lbg_display_info for usage
lbg_display_debug() {
	lbg_display_info "$@"
}

lbg_debug() {
	lbg_display_info "$@"
}

# Aliases for dialogs
lbg_info() {
	lbg_display_info "$@"
}

lbg_warning() {
	lbg_display_warning "$@"
}

lbg_error() {
	lbg_display_error "$@"
}


####################
#  INITIALIZATION  #
####################

# set the default GUI tool
if ! lbg_set_gui ; then
	return 2
fi
