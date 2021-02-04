########################################################
#                                                      #
#  libbash.sh GUI                                      #
#  Functions to extend bash scripts to GUI tools       #
#                                                      #
#  MIT License                                         #
#  Copyright (c) 2017-2021 Jean Prunneaux              #
#  Website: https://github.com/pruje/libbash.sh        #
#                                                      #
#  Version 1.19.0 (2021-02-04)                         #
#                                                      #
########################################################

# Index
#
#   * Internal functions
#       lbg__get_console_size
#       lbg__dialog_size
#       lbg__display_msgbox
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


##################################
#  INTERNAL FUNCTIONS            #
#  DO NOT PUBLISH DOCUMENTATION  #
##################################

# Get console size and update lbg__console_width and lbg__console_height variables
# Usage: lbg__get_console_size
# Exit codes:
#   0: OK
#   1: No terminal available
lbg__get_console_size() {
	# get console width and height
	lbg__console_width=$(tput cols 2> /dev/null)
	lbg__console_height=$(tput lines 2> /dev/null)

	# if error (script not running in a terminal)
	if [ -z "$lbg__console_width" ] || [ -z "$lbg__console_height" ] ; then
		return 1
	fi
}


# Set dialog size to fit console
# Usage: lbg__dialog_size MAX_WIDTH MAX_HEIGHT
# Return: HEIGHT WIDTH
# e.g. dialog --msgbox "Hello world" $(lbg__dialog_size 50 10)
lbg__dialog_size() {
	# given size
	local dialog_width=$1 dialog_height=$2

	# if max width > console width, fit to console width
	if [ "$dialog_width" -gt "$lbg__console_width" ] ; then
		dialog_width=$lbg__console_width
	fi

	# if max height > console height, fit to console height
	if [ "$dialog_height" -gt "$lbg__console_height" ] ; then
		dialog_height=$lbg__console_height
	fi

	# return height width
	echo $dialog_height $dialog_width
}


# Display message box
# Usage: lbg__display_msgbox TYPE [OPTIONS] TEXT
lbg__display_msgbox() {
	# default options
	local type=$1 title=$lb_current_script_name
	shift

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

	local text=$*

	# get text from stdin
	if [ ${#text} = 0 ] ; then
		if ! [ -t 0 ] ; then
			local t
			while read -r t ; do
				text+="
$t"
			done
			# delete first line jump
			text=${text:1}
		fi
	fi

	# usage error if no text
	[ ${#text} = 0 ] && return 1

	# prepare command
	local cmd
	case $lbg__gui in
		kdialog)
			cmd=(kdialog --title "$title")

			case $type in
				error)
					cmd+=(--error)
					;;
				warning)
					cmd+=(--sorry)
					;;
				*)
					# default: info
					cmd+=(--msgbox)
					;;
			esac

			cmd+=("$text")
			;;

		zenity)
			cmd=(zenity --title "$title")

			case $type in
				error)
					cmd+=(--error)
					;;
				warning)
					cmd+=(--warning)
					;;
				*)
					# default: info
					cmd+=(--info)
					;;
			esac

			cmd+=(--text "$text")
			;;

		osascript)
			local icon
			case $type in
				error)
					icon=stop
					;;
				warning)
					icon=caution
					;;
				*)
					# default: info
					icon=note
					;;
			esac

			# run command
			$(osascript &> /dev/null << EOF
display dialog "$text" with title "$title" with icon $icon buttons {"$lb__ok_label"} default button 1
EOF) || return 2

			return 0
			;;

		cscript)
			cmd=("${lbg__cscript[@]}")
			cmd+=(lbg_display_$type "$(echo -e "$text")" "$title")

			# run VBscript into a context (cscript does not work with absolute paths)
			(cd "$lbg__vbscript_dir" && "${cmd[@]}") || return 2
			return 0
			;;

		dialog)
			local result=0 prefix

			case $type in
				error)
					prefix="$lb__error_label: "
					;;
				warning)
					prefix="$lb__warning_label: "
					;;
			esac

			dialog --title "$title" --clear --msgbox "$prefix$text" $(lbg__dialog_size 50 10) 2> /dev/null || result=$?

			# clear console
			clear

			# command error
			[ $result != 0 ] && return 2
			return 0
			;;

		*)
			# console mode
			cmd=(lb_display_$type "$text")
			;;
	esac

	# run command
	"${cmd[@]}" 2> /dev/null || return 2
}


###############
#  GUI TOOLS  #
###############

# Get current GUI tool
# Usage: lbg_get_gui
lbg_get_gui() {
	# no GUI tool defined
	[ -z "$lbg__gui" ] && return 1

	# return current GUI tool
	echo $lbg__gui
}


# Set GUI display to use
# Usage: lbg_set_gui [GUI_TOOL...]
lbg_set_gui() {
	# default options
	local gui_tools=(${lbg__supported_gui[@]}) result=0

	# if args set, test list of commands
	[ $# -gt 0 ] && gui_tools=($*)

	# test GUI tools
	local gui
	for gui in ${gui_tools[@]} ; do

		# set console mode is always OK
		if [ "$gui" = console ] ; then
			result=0
			break
		fi

		# test if GUI is supported
		if ! lb_in_array "$gui" "${lbg__supported_gui[@]}" ; then
			result=1
			continue
		fi

		# test if command exists
		if ! which "$gui" &> /dev/null ; then
			result=3
			continue
		fi

		# dialog command
		case $gui in
			dialog)
				# get console size
				if ! lbg__get_console_size ; then
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
				if ! [ -f "$lbg__vbscript_dir/$lbg__vbscript" ] ; then
					result=4
					continue
				fi
				;;
			*)
				# test if X server started (not for macOS)
				if [ "$lb_current_os" != macOS ] && [ -z "$DISPLAY" ] ; then
					result=4
					continue
				fi
				;;
		esac

		# all tests passed: tool can be set
		result=0
		break
	done

	# set gui tool
	[ $result = 0 ] && lbg__gui=$gui

	return $result
}


################################
#  MESSAGES AND NOTIFICATIONS  #
################################

# Display an info dialog
# Usage: lbg_display_info [OPTIONS] TEXT
lbg_display_info() {
	lbg__display_msgbox info "$@"
}


# Display a warning message
# Usage: lbg_display_warning [OPTIONS] TEXT
lbg_display_warning() {
	lbg__display_msgbox warning "$@"
}


# Display an error message
# Usage: lbg_display_error [OPTIONS] TEXT
lbg_display_error() {
	lbg__display_msgbox error "$@"
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
				[[ $2 =~ ^-?[0-9]+$ ]] || return 1
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

	local text=$*

	# get text from stdin
	if [ ${#text} = 0 ] ; then
		if ! [ -t 0 ] ; then
			local t
			while read -r t ; do
				text+="
$t"
			done
			# delete first line jump
			text=${text:1}
		fi
	fi

	# usage error if no text
	[ ${#text} = 0 ] && return 1

	local opts

	# if notify-send is installed, use it by default,
	# as it is better than zenity or other system
	if $use_notifysend && which notify-send &> /dev/null ; then
		# do not override kdialog because it has the best integration to KDE desktop
		# do not use it on macOS nor in console mode
		if ! lb_in_array "$lbg__gui" kdialog osascript console ; then
			# execute command with timeout in milliseconds
			[ -n "$timeout" ] && opts="-t $(($timeout * 1000)) "

			# push notification and return
			notify-send $opts"$title" "$text" || return 2
			return 0
		fi
	fi

	# run command
	case $lbg__gui in
		kdialog)
			kdialog --title "$title" --passivepopup "$text" $timeout 2> /dev/null || return 2
			;;

		zenity)
			opts=""

			# set a timeout
			[ -n "$timeout" ] && opts="--timeout=$timeout"

			# run command
			zenity --notification $opts --text "$text" 2> /dev/null || return 2
			;;

		osascript)
			$(osascript &> /dev/null << EOF
display notification "$text" with title "$title"
EOF) || return 2
			;;

		# no dialog command, because it doesn't make sense in console

		*)
			# print in console mode
			lb_display "[$lb__info_label]  $text" || return 2
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
	case $lbg__gui in
		kdialog)
			cmd=(kdialog --title "$title")
			[ -n "$yes_label" ] && cmd+=(--yes-label "$yes_label")
			[ -n "$no_label" ] && cmd+=(--no-label "$no_label")
			cmd+=(--yesno "$*")
			;;

		zenity)
			cmd=(zenity --question --title "$title" --text "$*")
			;;

		osascript)
			# set button labels
			[ -z "$yes_label" ] && yes_label=$lb__yes_label
			[ -z "$no_label" ] && no_label=$lb__no_label

			# set options
			local default_button=2
			$yes_default && default_button=1

			# run command
			result=$(osascript << EOF
set question to (display dialog "$*" with title "$title" buttons {"$yes_label", "$no_label"} default button $default_button)
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
			cmd=("${lbg__cscript[@]}")
			cmd+=(lbg_yesno "$(echo -e "$*")" "$title")
			$yes_default && cmd+=(true)

			# run VBscript into a context (cscript does not work with absolute paths)
			(cd "$lbg__vbscript_dir" && "${cmd[@]}") || return 2
			return 0
			;;

		dialog)
			cmd=(dialog --title "$title")
			$yes_default || cmd+=(--defaultno)
			[ -n "$yes_label" ] && cmd+=(--yes-label "$yes_label")
			[ -n "$no_label" ] && cmd+=(--no-label "$no_label")
			cmd+=(--clear --yesno "$*" $(lbg__dialog_size 100 10))

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
			$yes_default && cmd+=(-y)
			[ -n "$yes_label" ] && cmd+=(--yes-label "$yes_label")
			[ -n "$no_label" ] && cmd+=(--no-label "$no_label")
			cmd+=("$*")
			;;
	esac

	# run command
	"${cmd[@]}" 2> /dev/null || return 2
}


# Ask user to choose one or multiple options
# Usage: lbg_choose_option [OPTIONS] CHOICE [CHOICE...]
lbg_choose_option=()
lbg_choose_option() {
	# reset result
	lbg_choose_option=()

	# default options
	local default=() multiple_choices=false
	local title=$lb_current_script_name label=$lb__chopt_label

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
			-m|--multiple)
				multiple_choices=true
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

	# verify if default options are valid
	if [ ${#default[@]} -gt 0 ] ; then
		local d
		for d in "${default[@]}" ; do
			[[ $d =~ ^-?[0-9]+$ ]] || return 1

			if [ $d -lt 1 ] || [ $d -gt $# ] ; then
				return 1
			fi
		done
	else
		# one choice: initialize first choice as default (except for console mode)
		if ! $multiple_choices && [ "$lbg__gui" != console ] ; then
			default=(1)
		fi
	fi

	# change default label if multiple options
	if $multiple_choices ; then
		[ "$label" = "$lb__chopt_label" ] && label=$lb__chopts_label
	fi

	local o choices cmd
	local -i i=1

	case $lbg__gui in
		kdialog)
			cmd=(kdialog --title "$title")

			if $multiple_choices ; then
				cmd+=(--checklist)
			else
				cmd+=(--radiolist)
			fi

			cmd+=("$label")

			# add options
			for o in "$@" ; do
				cmd+=($i "$o")
				if lb_in_array $i "${default[@]}" ; then
					cmd+=(on)
				else
					cmd+=(off)
				fi
				i+=1
			done

			# run command
			choices=$("${cmd[@]}" 2> /dev/null)

			# multiple choices: transform '"1" "3"' to '1 3'
			choices=$(echo $choices | sed 's/"//g')
			;;

		zenity)
			cmd=(zenity --list --title "$title" --text "$label" --column "" --column "" --column "")

			if $multiple_choices ; then
				cmd+=(--checklist)
			else
				cmd+=(--radiolist)
			fi

			# add options
			for o in "$@" ; do
				if lb_in_array $i "${default[@]}" ; then
					cmd+=(TRUE)
				else
					cmd+=(FALSE)
				fi

				cmd+=($i "$o")
				i+=1
			done

			# run command
			choices=$("${cmd[@]}" 2> /dev/null)

			# multiple choices: transform '1|3' to '1 3'
			choices=$(echo $choices | sed 's/|/ /g')
			;;

		osascript)
			# prepare options
			local default_options=() multiple_option opts=() options

			# security: remove comas and spaces
			for o in "$@" ; do
				o=$(echo "$o" | sed 's/,//g' | lb_trim)
				opts+=("\"$o\"")

				# set default option
				lb_in_array $i "${default[@]}" && default_options+=("\"$o\"")

				i+=1
			done

			# join values
			options=$(lb_join , "${opts[@]}")
			default_options=$(lb_join , "${default_options[@]}")

			# add multiple choice option
			$multiple_choices && multiple_option="with multiple selections allowed"

			# execute command
			local choice=$(osascript 2> /dev/null <<EOF
set answer to (choose from list {$options} $multiple_option default items {$default_options} with prompt "$label" with title "$title")
EOF)
			# if empty, error
			[ -z "$choice" ] && return 2

			# split choices
			lb_split , "$choice"

			# find choice IDs
			for c in "${lb_split[@]}" ; do
				i=1
				for o in "${opts[@]}" ; do
					if [ "\"$(lb_trim "$c")\"" = "$o" ] ; then
						choices+="$i "
						break
					fi
					i+=1
				done
			done
			;;

		cscript)
			# avoid \n in label
			label=$(echo -e "$label")

			# add options to the label, with a line return between each option
			for o in "$@" ; do
				label+=$(echo -e "\n   $i. $o")
				i+=1
			done

			# prepare command (inputbox)
			cmd=("${lbg__cscript[@]}" lbg_input_text "$label" "$title")

			# avoid empty default values (if multiple choices)
			[ ${#default[@]} = 0 ] && default=(1)

			# run VBscript into a context (cscript does not work with absolute paths)
			# error => cancelled
			choices=$(cd "$lbg__vbscript_dir" && "${cmd[@]}" "${default[*]}") || return 2

			# multiple choices: transform '1,3' to '1 3'
			# and remove \r ending character
			choices=$(echo $choices | sed 's/,/ /g; s/[[:space:]]*$//')
			;;

		dialog)
			cmd=(dialog --title "$title" --clear)

			if $multiple_choices ; then
				cmd+=(--checklist)
			else
				cmd+=(--radiolist)
			fi

			cmd+=("$label" $(lbg__dialog_size 100 30) 1000)

			# add options
			for o in "$@" ; do
				cmd+=($i "$o")
				if lb_in_array $i "${default[@]}" ; then
					cmd+=(on)
				else
					cmd+=(off)
				fi
				i+=1
			done

			# run command (complex case)
			exec 3>&1
			choices=$("${cmd[@]}" 2>&1 1>&3)
			exec 3>&-

			# clear console
			clear
			;;

		*)
			# console mode
			cmd=(lb_choose_option -l "$label")

			$multiple_choices && cmd+=(-m)

			# add default choice(s)
			[ ${#default[@]} -gt 0 ] && cmd+=(-d $(lb_join , "${default[@]}"))

			# execute console function and forward result
			"${cmd[@]}" "$@" && choices=${lb_choose_option[*]}
			;;
	esac

	# if empty, cancelled
	[ -z "$choices" ] && return 2

	# parsing choices
	for o in ${choices[*]} ; do
		# strict check type
		if ! [[ $o =~ ^-?[0-9]+$ ]] ; then
			lb_choose_option=()
			return 3
		fi

		# check if user choice is valid
		if [ $o -lt 1 ] || [ $o -gt $# ] ; then
			lbg_choose_option=()
			return 3
		fi

		# save choice
		lbg_choose_option+=($o)
	done
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
	case $lbg__gui in
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
			cmd=("${lbg__cscript[@]}")
			cmd+=(lbg_input_text "$(echo -e "$*")" "$title")
			[ -n "$default" ] && cmd+=("$default")

			# run VBscript into a context (cscript does not work with absolute paths)
			# error => cancelled
			lbg_input_text=$(cd "$lbg__vbscript_dir" && "${cmd[@]}") || return 2

			# remove \r ending character
			lbg_input_text=${lbg_input_text:0:${#lbg_input_text}-1}
			;;

		dialog)
			# run command (complex case)
			exec 3>&1
			lbg_input_text=$(dialog --title "$title" --clear --inputbox "$*" $(lbg__dialog_size 100 10) "$default" 2>&1 1>&3)
			exec 3>&-

			# clear console
			clear
			;;

		*)
			# console mode
			cmd=(lb_input_text)
			[ -n "$default" ] && cmd+=(-d "$default")
			cmd+=("$*")

			# execute console function and forward result
			"${cmd[@]}" && lbg_input_text=$lb_input_text
			;;
	esac

	# if empty, return cancelled
	[ -n "$lbg_input_text" ] || return 2
}


# Ask user to enter a password
# Usage: lbg_input_password [OPTIONS] [TEXT]
lbg_input_password=""
lbg_input_password() {
	# reset result
	lbg_input_password=""

	# default options
	local label=$lb__pwd_label confirm_label=$lb__pwd_confirm_label
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
				[[ $2 =~ ^-?[0-9]+$ ]] || return 1
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
	[ -n "$*" ] && label=$*

	# display dialog
	local i result=0
	for i in 1 2 ; do

		# run command
		case $lbg__gui in
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
				lbg_input_password=$(dialog --title "$title" --clear --passwordbox "$label" $(lbg__dialog_size 50 10) 2>&1 1>&3)
				exec 3>&-

				# clear console
				clear
				;;

			*)
				# console mode
				# execute console function
				cmd=(lb_input_password --label "$label")
				[ $min_size -gt 0 ] && cmd+=(--min-size $min_size)

				result=0
				"${cmd[@]}" || result=$?
				if [ $result = 0 ] ; then
					# forward result
					lbg_input_password=$lb_input_password
				else
					return $result
				fi
				;;
		esac

		# if empty, return cancelled
		[ -n "$lbg_input_password" ] || return 2

		# check password size (if --min-size option is set)
		if [ $min_size -gt 0 ] && [ $(echo -n "$lbg_input_password" | wc -m) -lt $min_size ] ; then
			lbg_input_password=""
			return 4
		fi

		# if no confirm, quit
		$confirm || return 0

		# if first iteration,
		if [ $i = 1 ] ; then
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
	case $lbg__gui in
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
			cmd=("${lbg__cscript[@]}")
			cmd+=(lbg_choose_directory)

			# if title is not defined,
			if [ "$title" = "$lb_current_script_name" ] ; then
				# print default label
				cmd+=("$lb__chdir_label")
			else
				# print title as label
				cmd+=("$title")
			fi

			# run VBscript into a context (cscript does not work with absolute paths)
			# error => cancelled
			choice=$(cd "$lbg__vbscript_dir" && "${cmd[@]}") || return 2

			# remove \r ending character
			choice=${choice:0:${#choice}-1}
			;;

		dialog)
			# run command (complex case)
			exec 3>&1
			choice=$(dialog --title "$title" --clear --dselect "$path" $(lbg__dialog_size 100 30) 2>&1 1>&3)
			exec 3>&-

			# clear console
			clear
			;;

		*)
			# console mode
			cmd=(lb_input_text -d "$path")

			# set dialog title as label
			if [ "$title" = "$lb_current_script_name" ] ; then
				cmd+=("$lb__chdir_label")
			else
				cmd+=("$title")
			fi

			# execute console function and forward result
			"${cmd[@]}" && choice=$lb_input_text
			;;
	esac

	# if empty, cancelled
	[ -z "$choice" ] && return 2

	# return windows paths
	if [ "$lb_current_os" = Windows ] ; then
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
	local title=$lb_current_script_name filename=$lb__newfile_name

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
	case $lbg__gui in
		kdialog)
			# kdialog has a strange behaviour: it takes a path but only as a file name and needs to be run from start directory.
			if [ -d "$path" ] ; then
				# open mode: do not set default file name
				$save_mode || filename=.
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
			if $save_mode && [ -d "$path" ] ; then
				path+=/$filename
			fi

			cmd=(zenity --title "$title" --file-selection --filename "$path")

			# set save mode
			$save_mode && cmd+=(--save)

			# set filters
			[ ${#filters[@]} -gt 0 ] && cmd+=("--file-filter=${filters[@]}")

			choice=$("${cmd[@]}" 2> /dev/null)
			;;

		osascript)
			local opts

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
			choice=$(dialog --title "$title" --clear --fselect "$path" $(lbg__dialog_size 100 30) 2>&1 1>&3)
			exec 3>&-

			# clear console
			clear
			;;

		cscript)
			# prepare command
			cmd=("${lbg__powershell[@]}" choosefile "$(cygpath -w "$(lb_abspath "$path")")" "$title")

			# save mode
			if $save_mode ; then
				cmd+=(save)
			else
				cmd+=(open)
			fi

			# add filters
			if [ ${#filters[@]} -gt 0 ] ; then
				cmd+=("$(lb_join , "${filters[@]}")")
			fi

			# run powershell
			choice=$("${cmd[@]}") || return 2

			# remove \r ending character
			choice=${choice:0:${#choice}-1}
			;;

		*)
			# console mode
			cmd=(lb_input_text -d "$path")

			# set dialog title as label
			if [ "$title" = "$lb_current_script_name" ] ; then
				cmd+=("$lb__chfile_label")
			else
				cmd+=("$title")
			fi

			# execute console function and forward result
			"${cmd[@]}" && choice=$lb_input_text
			;;
	esac

	# if empty, cancelled
	[ -z "$choice" ] && return 2

	# return windows paths
	if [ "$lb_current_os" = Windows ] ; then
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
	[ -z "$*" ] && paths=("$lb_current_path")

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
	[ ${#paths[@]} = 0 ] && return 1

	# set OS explorer if not specified
	if [ -z "$explorer" ] ; then
		case $lb_current_os in
			macOS)
				explorer=open
				;;
			Windows)
				explorer=explorer
				;;
			*)
				explorer=xdg-open
				;;
		esac
	fi

	# test explorer command
	which "$explorer" &> /dev/null || return 2

	# open directories one by one
	local i path
	for ((i=0 ; i<${#paths[@]} ; i++)) ; do
		path=${paths[i]}

		if [ "$lb_current_os" = Windows ] ; then
			# particular case where explorer will not work if path finishes with '/'
			[ "${path:${#path}-1}" = / ] && path=${path:0:${#path}-1}

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

# check if libbash.sh is loaded
if [ -z "$lb_version" ] ; then
	echo >&2 "Error: libbash core not loaded!"
	echo >&2 "Please load it in your script before loading this library with command:"
	echo >&2 "   source \"/path/to/libbash.sh\""
	return 1
fi

# Set internal variables

# set supported GUIs
lbg__supported_gui=(kdialog zenity osascript cscript dialog console)

# GUI tool
lbg__gui=""

# console size
lbg__console_width=""
lbg__console_height=""

if [ "$lb_current_os" = Windows ] ; then
	# VB script and cscript command
	declare -r lbg__vbscript_dir=$lb_directory/inc
	declare -r lbg__vbscript=libbash_gui.vbs
	lbg__cscript=(cscript /NoLogo "$lbg__vbscript")

	# PowerShell command
	lbg__powershell=(powershell -ExecutionPolicy ByPass -File "$(cygpath -w "$lb_directory"/inc/libbash_gui.ps1)")
fi

# Set the default GUI tool
lbg_set_gui || return 2
