#!/bin/bash

########################################################
#                                                      #
#  libbash.sh GUI                                      #
#  Functions to extend bash scripts to GUI tools       #
#                                                      #
#  MIT License                                         #
#  Copyright (c) 2017 Jean Prunneaux                   #
#  Website: https://github.com/pruje/libbash.sh        #
#                                                      #
#  Version 0.3.2 (2017-03-21)                          #
#                                                      #
########################################################


####################
#  INITIALIZATION  #
####################

# test dependency
if [ -z "$lb_version" ] ; then
	echo >&2 "Error: libbash core not loaded!"
	echo >&2 "Please load it in your script before loading this library with command:"
	echo >&2 "   source \"/path/to/libbash.sh\""
	exit 1
fi

# set supported GUIs
lbg_supported_gui=(kdialog zenity osascript dialog console)

# GUI tool
lbg_gui=""

# console size
lbg_console_width=""
lbg_console_height=""


###############
#  GUI TOOLS  #
###############

# Get current GUI tool
# Usage: lbg_get_gui
# Return: GUI tool
# Exit codes:
#  0: OK
#  1: no GUI tool available
lbg_get_gui() {

	# if no GUI tool defined
	if [ -z "$lbg_gui" ] ; then
		return 1
	fi

	# return current GUI tool
	echo $lbg_gui
}


# Set default GUI display
# Usage: lbg_set_gui GUI_TOOL
# Exit codes:
#   0: GUI tool set
#   1: usage error
#   2: GUI tool not supported
#   3: GUI tool not available on this system
#   4: GUI tool available, but currently no X server is running
lbg_set_gui() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	local lbg_setgui_gui="$*"

	# set console mode is always OK
	if [ "$lbg_setgui_gui" == "console" ] ; then
		lbg_gui="console"
		return 0
	fi

	# test if GUI is supported
	if ! lb_array_contains "$lbg_setgui_gui" "${lbg_supported_gui[@]}" ; then
		return 2
	fi

	# test if command exists
	if ! lb_command_exists "$lbg_setgui_gui" ; then
		return 3
	fi

	# dialog command
	if [ "$lbg_setgui_gui" == "dialog" ] ; then
		# get console size
		if ! lbg_get_console_size ; then
			return 4
		fi
	else
		# test if X server started (not for macOS)
		if [ "$(lb_detect_os)" != "macOS" ] ; then
			if [ -z "$DISPLAY" ] ; then
				return 4
			fi
		fi
	fi

	# set gui tool
	lbg_gui="$lbg_setgui_gui"
	return 0
}


# Get console size and update lbg_console_width and lbg_console_height variables
# FOR LIBBASH INTERNAL USES; DO NOT PUBLISH DOCUMENTATION
# Usage: lbg_get_console_size()
# Exit codes:
#   0: OK
#   1: no terminal available
lbg_get_console_size() {

	# get console width and height
	lbg_console_width="$(tput cols 2> /dev/null)"
	lbg_console_height="$(tput lines 2> /dev/null)"

	# if error (script not running in a terminal)
	if [ -z "$lbg_console_width" ] || [ -z "$lbg_console_height" ] ; then
		return 1
	fi

	return 0
}


# Set dialog size to fit console
# FOR LIBBASH INTERNAL USES; DO NOT PUBLISH DOCUMENTATION
# Usage: lbg_dialog_size MAX_WIDTH MAX_HEIGHT
# Return: "HEIGHT WIDTH"
# e.g. dialog --msgbox "Hello world" $(lbg_dialog_size 50 10)
lbg_dialog_size() {

	# given size
	local lbg_dialog_width="$1"
	local lbg_dialog_height="$2"

	# if max width > console width, fit to console width
	if [ "$lbg_dialog_width" -gt "$lbg_console_width" ] ; then
		lbg_dialog_width=$lbg_console_width
	fi

	# if max height > console height, fit to console height
	if [ "$lbg_dialog_height" -gt "$lbg_console_height" ] ; then
		lbg_dialog_height=$lbg_console_height
	fi

	# return "height width"
	echo "$lbg_dialog_height $lbg_dialog_width"
}


################################
#  MESSAGES AND NOTIFICATIONS  #
################################

# Display an info dialog
# Usage: lbg_display_info [OPTIONS] TEXT
# Options:
#   -t, --title TEXT  set dialog title
# Exit codes:
#   0: OK
#   1: usage error
#   2: dialog command error
lbg_display_info() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lbg_dinf_title="$lb_current_script_name"

	# get options
	while true ; do
		case "$1" in
			-t|--title)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_dinf_title="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# usage error if no text to display
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# prepare command
	case "$lbg_gui" in
		kdialog)
			lbg_dinf_cmd=(kdialog --title "$lbg_dinf_title" --msgbox "$*")
			;;

		zenity)
			lbg_dinf_cmd=(zenity --title "$lbg_dinf_title" --info --text "$*")
			;;

		osascript)
			# run command
			osascript 2> /dev/null << EOF
display dialog "$*" with title "$lbg_dinf_title" with icon note buttons {"$lb_default_ok_label"} default button 1
EOF
			# if command error
			if [ $? != 0 ] ; then
				return 2
			fi

			# quit
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

	return 0
}


# Display a warning message
# Usage: lbg_display_warning [OPTIONS] TEXT
# Options:
#   -t, --title TEXT  set dialog title
# Exit codes:
#   0: OK
#   1: usage error
#   2: dialog command error
lbg_display_warning() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lbg_dwn_title="$lb_current_script_name"

	# get options
	while true ; do
		case "$1" in
			-t|--title)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_dwn_title="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# usage error if no text to display
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# prepare command
	case "$lbg_gui" in
		kdialog)
			lbg_dwn_cmd=(kdialog --title "$lbg_dwn_title" --sorry "$*")
			;;

		zenity)
			lbg_dwn_cmd=(zenity --title "$lbg_dwn_title" --warning --text "$*")
			;;

		osascript)
			# run command
			osascript 2> /dev/null << EOF
display dialog "$*" with title "$lbg_dwn_title" with icon caution buttons {"$lb_default_ok_label"} default button 1
EOF
			# command error
			if [ $? != 0 ] ; then
				return 2
			fi

			# quit
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

	return 0
}


# Display an error message
# Usage: lbg_display_error [OPTIONS] TEXT
# Options:
#   -t, --title TEXT  set dialog title
# Exit codes:
#   0: OK
#   1: usage error
#   2: dialog command error
lbg_display_error() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lbg_derr_title="$lb_current_script_name"

	# get options
	while true ; do
		case "$1" in
			-t|--title)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_derr_title="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# usage error if no text to display
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# prepare command
	case "$lbg_gui" in
		kdialog)
			lbg_derr_cmd=(kdialog --title "$lbg_derr_title" --error "$*")
			;;

		zenity)
			lbg_derr_cmd=(zenity --title "$lbg_derr_title" --error --text "$*")
			;;

		osascript)
			# run command
			osascript 2> /dev/null << EOF
display dialog "$*" with title "$lbg_derr_title" with icon stop buttons {"$lb_default_ok_label"} default button 1
EOF
			# command error
			if [ $? != 0 ] ; then
				return 2
			fi

			# quit
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

	return 0
}


# Display a notification popup
# Usage: lbg_notify [OPTIONS] TEXT
# Options:
#   -t, --title TEXT   notification title
#   --timeout SECONDS  timeout before notification disapears
#                      No available on macOS
#   --no-notify-send   do not use the notify-send command if exists
# Exit codes:
#   0: OK
#   1: usage error
#   2: notification command error
lbg_notify() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lbg_notify_title="$lb_current_script_name"
	local lbg_notify_timeout=""
	local lbg_notify_use_notifysend=true

	# get options
	while true ; do
		case "$1" in
			-t|--title)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_notify_title="$2"
				shift 2
				;;
			--timeout)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				if ! lb_is_integer $2 ; then
					return 1
				fi
				lbg_notify_timeout="$2"
				shift 2
				;;
			--no-notify-send)
				# do not use notify-send command if available
				lbg_notify_use_notifysend=false
				shift
				;;
			*)
				break
				;;
		esac
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
	case "$lbg_gui" in
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
			osascript 2> /dev/null << EOF
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

	return 0
}


######################
#  USER INTERACTION  #
######################

# Prompt user to confirm an action in graphical mode
# Usage: lbg_yesno [OPTIONS] TEXT
# Options:
#   -y, --yes         Set Yes as selected button (not available on kdialog and zenity)
#   --yes-label TEXT  Change Yes label (not available on zenity)
#   --no-label TEXT   Change No label (not available on zenity)
#   -t, --title TEXT  Set a title to the dialog
# Exit codes:
#   0: yes
#   1: usage error
#   2: no
#   3: cancelled
lbg_yesno() {

	# default options
	local lbg_yn_defaultyes=false
	local lbg_yn_yeslbl=""
	local lbg_yn_nolbl=""
	local lbg_yn_title="$lb_current_script_name"
	local lbg_yn_cmd=()

	# get options
	while true ; do
		case "$1" in
			-y|--yes)
				lbg_yn_defaultyes=true
				shift
				;;
			--yes-label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_yn_yeslbl="$2"
				shift 2
				;;
			--no-label)
				lbg_yn_nolbl="$2"
				shift 2
				;;
			-t|--title)
				lbg_yn_title="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# usage error if no text to display
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# prepare command
	case "$lbg_gui" in
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
				lbg_yn_yeslbl="$lb_default_yes_label"
			fi
			if [ -z "$lbg_yn_nolbl" ] ; then
				lbg_yn_nolbl="$lb_default_no_label"
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

	return 0
}


# Ask user to choose an option
# Usage: lbg_choose_option [OPTIONS] CHOICE [CHOICE...]
# Options:
#   -d, --default ID  option to use by default
#   -l, --label TEXT  set a question text (default: "Choose an option:")
#   -t, --title TEXT  Set a title to the dialog
# Return: choice is stored into $lbg_choose_option variable
# Exit codes:
#   0: OK
#   1: usage error
#   2: cancelled
#   3: bad choice
lbg_choose_option=""
lbg_choose_option() {

	# reset result
	lbg_choose_option=""

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# default options and local variables
	local lbg_chop_default=0
	local lbg_chop_options=("")
	local lbg_chop_i
	local lbg_chop_title="$lb_current_script_name"
	local lbg_chop_label="$lb_default_chopt_label"

	# get options
	while true ; do
		case "$1" in
			-d|--default)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_chop_default="$2"
				shift 2
				;;
			-l|--label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_chop_label="$2"
				shift 2
				;;
			-t|--title)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_chop_title="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# usage error if missing at least 1 choice option
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# prepare options; cannot support more than 254 options
	while true ; do
		if [ -n "$1" ] ; then
			lbg_chop_options+=("$1")
			shift
		else
			break
		fi
	done

	# verify default option
	if [ $lbg_chop_default != 0 ] ; then
		if ! lb_is_integer "$lbg_chop_default" ; then
			echo >&2 "Error: default option $lbg_chop_default is not a number."
			return 1
		else
			if [ $lbg_chop_default -lt 1 ] || [ $lbg_chop_default -ge ${#lbg_chop_options[@]} ] ; then
				echo >&2 "Error: default option $lbg_chop_default does not exists."
				return 1
			fi
		fi
	fi

	# prepare command
	case "$lbg_gui" in
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
						lbg_chop_default_option="${lbg_chop_options[$lbg_chop_i]}"
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
			if [ $lbg_chop_default != 0 ] ; then
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
				lbg_choose_option="$lb_choose_option"
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

	return 0
}


# Ask user to enter a text
# Usage: lbg_input_text [OPTIONS] TEXT
# Options:
#    -d, --default TEXT  default text
#    -t, --title TEXT    dialog title
# Return: user input is stored into $lbg_input_text variable
# Exit codes:
#   0: OK
#   1: usage error
#   2: cancelled
lbg_input_text=""
lbg_input_text() {

	# reset result
	lbg_input_text=""

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lbg_inp_default=""
	local lbg_inp_title="$lb_current_script_name"

	# get options
	while true ; do
		case "$1" in
			-d|--default)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_inp_default="$2"
				shift 2
				;;
			-t|--title)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_inp_title="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# usage error if no text to display
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# run command
	case "$lbg_gui" in
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
				lbg_input_text="$lb_input_text"
			fi
			;;
	esac

	# if empty, reset variable and set cancelled
	if [ -z "$lbg_input_text" ] ; then
		lbg_input_text=""
		return 2
	fi

	return 0
}


# Ask user to enter a password
# Usage: lbg_input_password [OPTIONS]
# Options:
#    -l, --label TEXT        set label (not available on zenity)
#    -t, --title TEXT        dialog title
#    -c, --confirm           display a confirmation dialog
#    --confirm-label TEXT    set confirm label (not available on zenity)
# Return: password is stored into $lbg_input_password variable
# Exit codes:
#   0: OK
#   1: usage error
#   2: cancelled
#   3: passwords mismatch
lbg_input_password=""
lbg_input_password() {

	# reset result
	lbg_input_password=""

	# default options
	local lbg_inpw_label="$lb_default_pwd_label"
	local lbg_inpw_confirm=false
	local lbg_inpw_confirm_label="$lb_default_pwd_confirm_label"
	local lbg_inpw_title="$lb_current_script_name"

	# get options
	while true ; do
		case "$1" in
			-l|--label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_inpw_label="$2"
				shift 2
				;;
			-c|--confirm)
				lbg_inpw_confirm=true
				shift
				;;
			--confirm-label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_inpw_confirm_label="$2"
				shift 2
				;;
			-t|--title)
				lbg_inpw_title="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# display dialog
	for lbg_inpw_i in 1 2 ; do

		# run command
		case "$lbg_gui" in
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
					lbg_input_password="$lb_input_password"
				else
					return $lbg_inpw_res
				fi
				;;
		esac

		# if empty, cancelled
		if [ -z "$lbg_input_password" ] ; then
			lbg_input_password=""
			return 2
		fi

		# if no confirm, quit
		if ! $lbg_inpw_confirm ; then
			return 0
		fi

		# if first iteration,
		if [ $lbg_inpw_i == 1 ] ; then
			# save password
			lbg_inpw_password_confirm="$lbg_input_password"

			# set new confirm label and continue
			lbg_inpw_label="$lbg_inpw_confirm_label"
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
# Options:
#   -a, --absolute-path  Return absolute path of the directory
#   -t, --title TITLE    Set dialog title
#   PATH                 Starting path (current by default)
# Return: choosed directory path is stored into $lbg_choose_directory variable
# Exit codes:
#   0: OK
#   1: usage error
#   2: cancelled
#   3: choosed path is not a directory
lbg_choose_directory=""
lbg_choose_directory() {

	# reset result
	lbg_choose_directory=""

	# default options
	local lbg_chdir_title="$lb_current_script_name"
	local lbg_chdir_path=""
	local lbg_chdir_absolute=false

	# get options
	while true ; do
		case "$1" in
			-a|--absolute-path)
				lbg_chdir_absolute=true
				shift
				;;
			-t|--title)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_chdir_title="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# if no path specified, use current
	if lb_test_arguments -eq 0 $* ; then
		lbg_chdir_path="$lb_current_path"
	else
		lbg_chdir_path="$*"
	fi

	# if path is not a directory, usage error
	if ! [ -d "$lbg_chdir_path" ] ; then
		return 1
	fi

	# run command
	case "$lbg_gui" in
		kdialog)
			lbg_choose_directory=$(kdialog --title "$lbg_chdir_title" --getexistingdirectory "$lbg_chdir_path" 2> /dev/null)
			;;

		zenity)
			lbg_choose_directory=$(zenity --title "$lbg_chdir_title" --file-selection --directory --filename "$lbg_chdir_path" 2> /dev/null)
			;;

		osascript)
			lbg_choose_directory=$(osascript 2> /dev/null <<EOF
set answer to POSIX path of (choose folder with prompt "$lbg_chdir_title" default location "$lbg_chdir_path")
EOF)
			;;

		dialog)
			# run command (complex case)
			exec 3>&1
			lbg_choose_directory=$(dialog --title "$lbg_chdir_title" --clear --dselect "$lbg_chdir_path" $(lbg_dialog_size 100 30) 2>&1 1>&3)
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
				lbg_choose_directory="$lb_input_text"
			fi
			;;
	esac

	# if empty, cancelled
	if [ -z "$lbg_choose_directory" ] ; then
		return 2
	fi

	# if not a directory, reset variable and return error
	if ! [ -d "$lbg_choose_directory" ] ; then
		lbg_choose_directory=""
		return 3
	fi

	# return absolute path if option set
	if $lbg_chdir_absolute ; then
		lbg_chdir_abspath="$(lb_abspath "$lbg_choose_directory")"
		if [ $? == 0 ] ; then
			lbg_choose_directory="$lbg_chdir_abspath"
		else
			# in case of error, user can get returned path
			return 4
		fi
	fi

	return 0
}


# Dialog to choose a file
# Usage: lbg_choose_file [OPTIONS] [PATH]
# Options:
#   -s, --save           save mode (can create file instead of open existing)
#   -f, --filter FILTER  set filters (WARNING: not supported with dialog command)
#                        e.g. -f "*.sh" to filter by bash files
#                        OPTION NOT SUPPORTED YET ON macOS
#   -a, --absolute-path  get absolute path of file
#   -t, --title TITLE    set a dialog title
#   PATH                 starting path or selected file (current by default)
# Return: choosed file path is stored into $lbg_choose_file variable
# Exit codes:
#   0: OK
#   1: usage error
#   2: cancelled
#   3: chosen file is not valid
#   4: cannot get absolute path
lbg_choose_file=""
lbg_choose_file() {

	# reset result
	lbg_choose_file=""

	# default options
	local lbg_choosefile_save=false
	local lbg_choosefile_title="$lb_current_script_name"
	local lbg_choosefile_path=""
	local lbg_choosefile_filters=()
	local lbg_choosefile_absolute=false

	# catch options
	while true ; do
		case "$1" in
			-s|--save)
				lbg_choosefile_save=true
				shift
				;;
			-f|--filter)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_choosefile_filters+=("$2")
				shift 2
				;;
			-a|--absolute-path)
				lbg_choosefile_absolute=true
				shift
				;;
			-t|--title)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_choosefile_title="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# if no path specified, use current directory
	if lb_test_arguments -eq 0 $* ; then
		lbg_choosefile_path="$lb_current_path"
	else
		lbg_choosefile_path="$*"
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
	case "$lbg_gui" in
		kdialog)
			# kdialog has a strange behaviour: it takes a path but only as a file name.
			# it starts on the current directory path. This is a hack to work:
			lbg_choosefile_pathfile="."
			if ! [ -d "$lbg_choosefile_path" ] ; then
				lbg_choosefile_pathfile="$(basename "$lbg_choosefile_path")"
				lbg_choosefile_path="$(dirname "$lbg_choosefile_path")"
			fi

			# set mode (open or save)
			if $lbg_choosefile_save ; then
				lbg_choosefile_mode="--getsavefilename"
			else
				lbg_choosefile_mode="--getopenfilename"
			fi

			# go into the directory then open kdialog
			lbg_choose_file=$(cd "$lbg_choosefile_path" &> /dev/null; kdialog --title "$lbg_choosefile_title" $lbg_choosefile_mode "$lbg_choosefile_pathfile" "${lbg_choosefile_filters[@]}" 2> /dev/null)
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

			lbg_choose_file=$(zenity --title "$lbg_choosefile_title" --file-selection $lbg_choosefile_opts --filename "$lbg_choosefile_path" "$lbg_choosefile_opts" 2> /dev/null)
			;;

		osascript)
			local lbg_choosefile_opts=""
			local lbg_choosefile_file="$lb_default_newfile_name"

			# set save mode
			if $lbg_choosefile_save ; then
				lbg_choosefile_mode="name"

				if ! [ -d "$lbg_choosefile_path" ] ; then
					lbg_choosefile_file="$(basename "$lbg_choosefile_path")"
					lbg_choosefile_path="$(dirname "$lbg_choosefile_path")"
				fi

				lbg_choosefile_opts="default name \"$lbg_choosefile_file\""
			fi

			lbg_choose_file=$(osascript 2> /dev/null <<EOF
set answer to POSIX path of (choose file $lbg_choosefile_mode with prompt "$lbg_choosefile_title" $lbg_choosefile_opts default location "$lbg_choosefile_path")
EOF)
			;;

		dialog)
			# execute dialog (complex case)
			exec 3>&1
			lbg_choose_file=$(dialog --title "$lbg_choosefile_title" --clear --fselect "$lbg_choosefile_path" $(lbg_dialog_size 100 30) 2>&1 1>&3)
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
				lbg_choose_file="$lb_input_text"
			fi
			;;
	esac

	# if empty, cancelled
	if [ -z "$lbg_choose_file" ] ; then
		return 2
	fi

	# if save mode,
	if $lbg_choosefile_save ; then
		# if directory parent does not exists, reset variable and return error
		if ! [ -d "$(dirname "$lbg_choose_file")" ] ; then
			lbg_choose_file=""
			return 3
		fi

		# if exists but is not a file, return error
		if [ -e "$lbg_choose_file" ] ; then
			if ! [ -f "$lbg_choose_file" ] ; then
				lbg_choose_file=""
				return 3
			fi
		fi
	else
		# open mode
		# if file does not exists, reset variable and return error
		if ! [ -f "$lbg_choose_file" ] ; then
			lbg_choose_file=""
			return 3
		fi
	fi

	# return absolute path if option set
	if $lbg_choosefile_absolute ; then
		lbg_choosefile_abspath="$(lb_abspath "$lbg_choose_file")"
		if [ $? == 0 ] ; then
			lbg_choose_file="$lbg_choosefile_abspath"
		else
			# in case of error, user can get returned path
			return 4
		fi
	fi

	return 0
}


###############################
#  ALIASES AND COMPATIBILITY  #
###############################

# Display a critical dialog
# See lbg_display_error for usage
lbg_display_critical() {
	lbg_display_error $*
}

# Display a debug dialog
# See lbg_display_info for usage
lbg_display_debug() {
	lbg_display_info $*
}


###########################
#  DEFAULT GUI SELECTION  #
###########################

# test supported GUI tools
for lbg_sgt in ${lbg_supported_gui[@]} ; do

	# try to set GUI tool
	lbg_set_gui "$lbg_sgt"

	if [ -n "$lbg_gui" ] ; then
		# set first available as default
		break
	fi
done
