#!/bin/bash

########################################################
#                                                      #
#  libbash.sh GUI                                      #
#                                                      #
#  Author: Jean Prunneaux (http://jean.prunneaux.com)  #
#                                                      #
########################################################

################################
#                              #
#  Version 0.1.0 (2016-11-24)  #
#                              #
################################


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
lbg_supported_gui=(kdialog zenity osascript dialog)

lbg_gui=""


###############
#  FUNCTIONS  #
###############

# Get GUI tool
# Usage: lbg_get_gui
# Return: GUI name; exit code to 1 if no GUI supported
lbg_get_gui() {
	if [ -z "$lbg_gui" ] ; then
		return 1
	fi
	echo $lbg_gui
}


# Test GUI tool
# Usage: lbg_test_gui GUI_TOOL
# Return: 0 if OK, 1 is usage error, 2 if GUI is not supported
lbg_test_gui() {
	if [ $# == 0 ] ; then
		return 1
	fi

	# test if GUI is supported
	if lb_array_contains "$1" "${lbg_supported_gui[@]}" ; then
		# test if command exists
		if ! lb_command_exists "$1" ; then
			return 2
		fi
	else
		return 2
	fi
}


# Set default GUI display
# Usage: lbg_set_gui GUI_TOOL
# Return: 0 if OK, 1 is usage error, 2 if GUI is not supported
lbg_set_gui() {
	if [ $# == 0 ] ; then
		return 1
	fi

	# console mode is always OK
	if [ "$1" == "console" ] ; then
		lbg_gui="console"
		return 0
	fi

	# test if GUI is supported
	if lbg_test_gui "$1" ; then
		if [ "$(lb_detect_os)" != "macOS" ] ; then
			# if no X server started, stay in console mode
			if [ -n "$DISPLAY" ] ; then
				lbg_gui="$1"
			else
				lbg_gui="console"
			fi
		fi
	else
		return 2
	fi
}


################################
#  MESSAGES AND NOTIFICATIONS  #
################################

# Display a message
# Usage: lbg_display_info [options] TEXT
# Options:
#   -t, --title TEXT  set dialog title
lbg_display_info() {

	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lbg_dinf_title="$(basename "$0")"

	# catch options
	while true ; do
		case "$1" in
			--title|-t)
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

	# display dialog
	case "$lbg_gui" in
		kdialog)
			lbg_dinf_cmd=(kdialog --title "$lbg_dinf_title" --msgbox "$*")
			;;

		zenity)
			lbg_dinf_cmd=(zenity --title "$lbg_dinf_title" --info --text "$*")
			;;

		osascript)
			# TODO
			;;

		dialog)
			lbg_dinf_cmd=(dialog --title "$lbg_dinf_title" --clear --msgbox "$*" 10 50)

			"${lbg_dinf_cmd[@]}" 2> /dev/null
			lbg_dinf_res=$?

			# clear console
			clear
			return $lbg_dinf_res
			;;

		*)
			# console mode
			lbg_dinf_cmd=(lb_display_info $*)
			;;
	esac

	"${lbg_dinf_cmd[@]}" 2> /dev/null
}


# Display a warning message
# Usage: lbg_display_warning [options] TEXT
# Options:
#   -t, --title TEXT  set dialog title
lbg_display_warning() {

	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lbg_dwn_title="$(basename "$0")"

	# catch options
	while true ; do
		case "$1" in
			--title|-t)
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

	# display dialog
	case "$lbg_gui" in
		kdialog)
			lbg_dwn_cmd=(kdialog --title "$lbg_dwn_title" --sorry "$*")
			;;

		zenity)
			lbg_dwn_cmd=(zenity --title "$lbg_dwn_title" --warning --text "$*")
			;;

		osascript)
			# TODO
			;;

		dialog)
			lbg_dwn_cmd=(lbg_display_info "$lb_default_warning_label: $*")
			;;

		*)
			# console mode
			lbg_dwn_cmd=(lb_display_warning $*)
			;;
	esac

	"${lbg_dwn_cmd[@]}" 2> /dev/null
}


# Display an error message
# Usage: lbg_display_error [options] TEXT
# Options:
#   -t, --title TEXT  set dialog title
lbg_display_error() {

	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lbg_derr_title="$(basename "$0")"

	# catch options
	while true ; do
		case "$1" in
			--title|-t)
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

	# display dialog
	case "$lbg_gui" in
		kdialog)
			lbg_derr_cmd=(kdialog --title "$lbg_derr_title" --error "$*")
			;;

		zenity)
			lbg_derr_cmd=(zenity --title "$lbg_derr_title" --error --text "$*")
			;;

		osascript)
			# TODO
			;;

		dialog)
			lbg_derr_cmd=(lbg_display_info "$lb_default_error_label: $*")
			;;

		*)
			# console mode
			lbg_derr_cmd=(lb_display_error $*)
			;;
	esac

	"${lbg_derr_cmd[@]}" 2> /dev/null
}


######################
#  USER INTERACTION  #
######################

# Prompt user to enter a text
# Usage: lbg_input_text [options] TEXT
# Options:
#    -d, --default TEXT  default text
#    -t, --title TEXT    dialog title
# Return: exit code, value is set into $lbg_input_text variable
lbg_input_text=""
lbg_input_text() {

	# reset result
	lbg_input_text=""

	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lbg_inp_default=""
	local lbg_inp_title="$(basename "$0")"

	# catch options
	while true ; do
		case "$1" in
			--default|-d)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_inp_default="$2"
				shift 2
				;;
			--title|-t)
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

	# display dialog
	case "$lbg_gui" in
		kdialog)
			lbg_inp_cmd=(kdialog --title "$lbg_inp_title" --inputbox "$*" "$lbg_inp_default")
			;;

		zenity)
			lbg_inp_cmd=(zenity --entry --title "$lbg_inp_title" --entry-text "$lbg_inp_default" --text "$*")
			;;

		osascript)
			lbg_input_text=$(osascript 2> /dev/null << EOF
set answer to the text returned of (display dialog "$*" with title "$lbg_inp_title" default answer "$lbg_inp_default")
EOF)
			return $?
			;;

		dialog)
			lbg_inp_cmd=(dialog --title "$lbg_inp_title" --clear --inputbox "$*" 10 100 "$lbg_inp_default")

			# execute dialog (complex case)
			exec 3>&1
			lbg_input_text=$("${lbg_inp_cmd[@]}" 2>&1 1>&3)
			lbg_inp_res=$?
			exec 3>&-

			# clear console
			clear
			return $lbg_inp_res
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
			lbg_inp_res=$?
			if [ $lbg_inp_res == 0 ] ; then
				# forward result
				lbg_input_text="$lb_input_text"
			fi

			return $lbg_inp_res
			;;
	esac

	lbg_input_text=$("${lbg_inp_cmd[@]}" 2> /dev/null)
}


# Prompt user to confirm an action in graphical mode
# Args: [options] TEXT
# Return: continue (0:YES / 1:NO)
lbg_yesno() {
	# default values
	local lbg_yn_defaultyes=false
	local lbg_yn_yeslbl=""
	local lbg_yn_nolbl=""
	local lbg_yn_title="$(basename "$0")"
	local lbg_yn_cmd=()

	# catch options
	while true ; do
		case "$1" in
			--yes|-y)
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
			--title|-t)
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
		return 2
	fi

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
			if [ -z "$lbg_yn_yeslbl" ] ; then
				lbg_yn_yeslbl="$lb_default_yes_label"
			fi
			if [ -z "$lbg_yn_nolbl" ] ; then
				lbg_yn_nolbl="$lb_default_no_label"
			fi

			#
			lbg_yn_opts="default button "
			if $lbg_yn_defaultyes ; then
				lbg_yn_opts+="1"
			else
				lbg_yn_opts+="2"
			fi

			lbg_yn_res=$(osascript << EOF
set question to (display dialog "$*" with title "$lbg_yn_title" buttons {"$lbg_yn_yeslbl", "$lbg_yn_nolbl"} $lbg_yn_opts)
set answer to button returned of question
if answer is equal to "$lbg_yn_yeslbl" then
	return 0
else
	return 1
end if
EOF)
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
			lbg_yn_cmd+=(--clear --yesno "$*" 10 100)

			# execute dialog
			"${lbg_yn_cmd[@]}"
			lbg_yn_res=$?

			# clear console
			clear
			return $lbg_yn_res
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

	# execute command
	"${lbg_yn_cmd[@]}" 2> /dev/null
}


# Prompt user to enter a password
# Usage: lbg_input_password [options]
# Options:
#    -l, --label TEXT        label for dialog
#    -t, --title TEXT        dialog title
#    -c, --confirm           display a confirmation dialog
#    --confirm-label TEXT    display a confirmation dialog
# Return: exit code, value is set into $lbg_input_text variable
lbg_input_password=""
lbg_input_password() {

	# reset result
	lbg_input_password=""

	# default options
	local lbg_inpw_label="Enter your password:"
	local lbg_inpw_confirm=false
	local lbg_inpw_confirm_label="Confirm password:"
	local lbg_inpw_title="$(basename "$0")"

	# catch options
	while true ; do
		case "$1" in
			-l|--label)
				if lb_test_arguments -eq 0 $2 ; then
					return 2
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
					return 2
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

	# display dialog(s)
	for lbg_inpw_i in $(seq 1 2) ; do

		# if second iteration, it's a confirm dialog
		if [ $lbg_inpw_i -gt 1 ] ; then
			lbg_inpw_label="$lbg_inpw_confirm_label"
		fi

		case "$lbg_gui" in
			kdialog)
				lbg_inpw_password=$(kdialog --title "$lbg_inpw_title" --password "$lbg_inpw_label" 2> /dev/null)
				lbg_inpw_res=$?
				;;

			zenity)
				lbg_inpw_password=$(zenity --title "$lbg_inpw_title" --password "$lbg_inpw_label" 2> /dev/null)
				lbg_inpw_res=$?
				;;

			osascript)
				# TODO
				;;

			dialog)
				# execute dialog (complex case)
				exec 3>&1
				lbg_inpw_password=$(dialog --title "$lbg_inpw_title" --clear --passwordbox "$lbg_inpw_label" 10 50 2>&1 1>&3)
				lbg_inpw_res=$?
				exec 3>&-

				# clear console
				clear
				;;

			*)
				# console mode
				# execute console function
				# TODO: improve with options forwarding
				lb_input_password --label "$lbg_inpw_label"
				if [ $? == 0 ] ; then
					if [ -n "$lb_input_password" ] ; then
						# forward result
						lbg_inpw_password="$lb_input_password"
						lbg_inpw_res=0
					else
						lbg_inpw_res=1
					fi
				else
					lbg_inpw_res=1
				fi
				;;
		esac

		if [ $lbg_inpw_res != 0 ] ; then
			return $lbg_inpw_res
		fi

		# if no confirm, exit
		if $lbg_inpw_confirm ; then
			# if first iteration, continue
			if [ $lbg_inpw_i == 1 ] ; then
				lbg_inpw_password_confirm="$lbg_inpw_password"
				continue
			fi

			# comparison with confirm password
			if [ "$lbg_inpw_password" != "$lbg_inpw_password_confirm" ] ; then
				return 1
			fi
		fi

		lbg_input_password="$lbg_inpw_password"
		return $lbg_inpw_res
	done
}


# Prompt user to choose an option in graphical mode
# Usage: lbg_choose_option [options] TEXT OPTION [OPTION...]
# Options:
#    -d, --default ID  option to use by default
# Return: value is set into $lb_choose_option variable
# Exit codes: 0: OK, 1: usage error, 2: cancelled, 3: bad choice
lbg_choose_option=""
lbg_choose_option() {

	# reset result
	lbg_choose_option=""

	# catch usage errors
	if [ $# -lt 2 ] ; then
		return 1
	fi

	# default options and local variables
	local lbg_chop_default=0
	local lbg_chop_options=("")
	local lbg_chop_i
	local lbg_chop_title="$(basename "$0")"

	# catch options
	while true ; do
		case "$1" in
			--default|-d)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lbg_chop_default="$2"
				shift 2
				;;
			--title|-t)
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

	# usage error if no text and at least 1 option
	if lb_test_arguments -lt 2 $* ; then
		return 1
	fi

	lbg_chop_text="$1"
	shift

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

	# display dialog
	case "$lbg_gui" in
		kdialog)
			lbg_chop_cmd=(kdialog --title "$lbg_chop_title" --radiolist "$lbg_chop_text")

			# add options
			for ((lbg_chop_i=1 ; lbg_chop_i < ${#lbg_chop_options[@]} ; lbg_chop_i++)) ; do
				lbg_chop_cmd+=($lbg_chop_i "${lbg_chop_options[$lbg_chop_i]}")
				if [ $lbg_chop_i == $lbg_chop_default ] ; then
					lbg_chop_cmd+=(on)
				else
					lbg_chop_cmd+=(off)
				fi
			done

			# execute command
			lbg_choose_option=$("${lbg_chop_cmd[@]}" 2> /dev/null)
			lbg_chop_res=$?
			;;

		zenity)
			lbg_chop_cmd=(zenity --list --title "$lbg_chop_title" --text "$lbg_chop_text" --radiolist --column "" --column "" --column "")

			# add options
			for ((lbg_chop_i=1 ; lbg_chop_i < ${#lbg_chop_options[@]} ; lbg_chop_i++)) ; do
				if [ $lbg_chop_i == $lbg_chop_default ] ; then
					lbg_chop_cmd+=(TRUE)
				else
					lbg_chop_cmd+=(FALSE)
				fi

				lbg_chop_cmd+=($lbg_chop_i "${lbg_chop_options[$lbg_chop_i]}")
			done

			# execute command
			lbg_choose_option=$("${lbg_chop_cmd[@]}" 2> /dev/null)
			lbg_chop_res=$?
			;;

		osascript)
			# TODO
			;;

		dialog)
			lbg_chop_cmd=(dialog --title "$lbg_chop_title" --clear --radiolist "$lbg_chop_text" 30 100 100)

			# add options
			for ((lbg_chop_i=1 ; lbg_chop_i < ${#lbg_chop_options[@]} ; lbg_chop_i++)) ; do
				lbg_chop_cmd+=($lbg_chop_i "${lbg_chop_options[$lbg_chop_i]}")
				if [ $lbg_chop_i == $lbg_chop_default ] ; then
					lbg_chop_cmd+=(on)
				else
					lbg_chop_cmd+=(off)
				fi
			done

			# execute dialog (complex case)
			exec 3>&1
			lbg_choose_option=$("${lbg_chop_cmd[@]}" 2>&1 1>&3)
			lbg_chop_res=$?
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
			lbg_chop_cmd+=("$lbg_chop_text" "${lbg_chop_options[@]}")

			# execute console function
			"${lbg_chop_cmd[@]}"
			lbg_chop_res=$?
			if [ $lbg_chop_res == 0 ] ; then
				# forward result
				lbg_choose_option="$lb_choose_option"
			fi
			;;
	esac

	if [ $lbg_chop_res != 0 ] ; then
		return $lbg_chop_res
	fi

	# check if user choice is valid
	if [ "$lbg_choose_option" -lt 1 ] || [ "$lbg_choose_option" -ge ${#lbg_chop_options[@]} ] ; then
		return 3
	fi
}


###########################
#  FILES AND DIRECTORIES  #
###########################

# Dialog to choose a directory
# Usage: lbg_choose_directory PATH
lbg_choose_directory=""
lbg_choose_directory() {

	# reset result
	lbg_choose_directory=""

	# catch usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	local lbg_chdir_title="$(basename "$0")"

	# catch options
	while true ; do
		case "$1" in
			--title|-t)
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

	# usage error if no path
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	local lbg_chdir_path="$1"

	if ! [ -d "$lbg_chdir_path" ] ; then
		echo >&2 "Error: path $lbg_chdir_path does not exists!"
		return 1
	fi

	# display dialog
	case "$lbg_gui" in
		kdialog)
			lbg_chdir_cmd=(kdialog --title "$lbg_chdir_title" --getexistingdirectory "$lbg_chdir_path")
			;;

		zenity)
			lbg_chdir_cmd=(zenity --title "$lbg_chdir_title" --file-selection --directory --filename "$lbg_chdir_path")
			;;

		osascript)
			# TODO
			;;

		dialog)
			lbg_chdir_cmd=(dialog --title "$lbg_chdir_title" --clear --dselect "$lbg_chdir_path" 30 100)

			# execute dialog (complex case)
			exec 3>&1
			lbg_choose_directory=$("${lbg_chdir_cmd[@]}" 2>&1 1>&3)
			lbg_chdir_res=$?
			exec 3>&-

			# clear console
			clear

			return $lbg_chdir_res
			;;

		*)
			# console mode
			lbg_chdir_cmd=(lb_input_text -d "$lbg_chdir_path")

			if [ "$lbg_chdir_title" == "$(basename "$0")" ] ; then
				lbg_chdir_cmd+=("Choose a directory")
			else
				lbg_chdir_cmd+=("$lbg_chdir_title")
			fi

			# execute console function
			"${lbg_chdir_cmd[@]}"
			lbg_chdir_res=$?
			if [ $lbg_chdir_res == 0 ] ; then
				# if input is not a directory, error
				if ! [ -d "$lb_input_text" ] ; then
					return 1
				fi

				# forward result
				lbg_choose_directory="$lb_input_text"
			fi
			return $lbg_chdir_res
			;;
	esac

	# execute command
	lbg_choose_directory=$("${lbg_chdir_cmd[@]}" 2> /dev/null)
}


###################
#  NOTIFICATIONS  #
###################

# Print a notification dialog
# Usage: lbg_notify [OPTIONS] TEXT
# Options:
#   -t, --title TEXT   notification title
#   --timeout SECONDS  timeout before notification disapears
# Exit codes: notification command result
lbg_notify() {

	# catch usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	local lbg_notify_title="$(basename "$0")"
	local lbg_notify_timeout=""
	local lbg_notify_use_notifysend=true

	# catch options
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
	# as it is better than any other system
	if lb_command_exists notify-send ; then
		if $lbg_notify_use_notifysend ; then
			if [ "$(lb_detect_os)" != "macOS" ] ; then
				# if X server started,
				if [ -n "$DISPLAY" ] ; then
					# execute command with timeout in milliseconds
					if [ -n "$lbg_notify_timeout" ] ; then
						lbg_notify_opts="-t $(($lbg_notify_timeout * 1000)) "
					fi

					# push notification and return
					notify-send $lbg_notify_opts"$lbg_notify_title" "$*"
					return $?
				fi
			fi
		fi
	fi

	# display dialog
	case "$lbg_gui" in
		kdialog)
			lbg_notify_cmd=(kdialog --title "$lbg_notify_title" --passivepopup "$*" $lbg_notify_timeout)
			;;

		zenity)
			# TODO: improve with listen option: https://help.gnome.org/users/zenity/stable/notification.html
			zenity --notification --text="$*"
  			return $?
			;;

		osascript)
			# TODO
			;;

		# no dialog system,  because it doesn't make sense in console
		*)
			# console mode
			lb_display_info $*
			return $?
			;;
	esac

	# execute command
	"${lbg_notify_cmd[@]}" 2> /dev/null
}


###############################
#  ALIASES AND COMPATIBILITY  #
###############################

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
	# set first available as default
	if lbg_set_gui "$lbg_sgt" ; then
		break
	fi
done
