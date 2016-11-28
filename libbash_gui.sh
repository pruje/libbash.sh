#!/bin/bash

####################################################
#
#  libbash GUI
#
#  Author: Jean Prunneaux (http://jean.prunneaux.com)
#
#######################################################

################################
#                              #
#  Version 0.1.0 (2016-11-24)  #
#                              #
################################


####################
#  INITIALIZATION  #
####################

# test dependency
if [ -z "$libbash_version" ] ; then
	echo >&2 "Error: libbash core not loaded!"
	echo >&2 "Please load it in your script before loading this library with command:"
	echo >&2 "   source \"/path/to/libbash.sh\""
	exit 1
fi

# set supported GUIs
lbg_supported_gui=(kdialog zenity osascript dialog)

# test GUIs
lbg_gui=""
for lbg_sgt in ${lbg_supported_gui[@]} ; do
	# test if command exists
	which $lbg_sgt &> /dev/null
	# if exists, set it as default
	if [ $? == 0 ] ; then
		lbg_gui=$lbg_sgt
		break
	fi
done


###############
#  FUNCTIONS  #
###############

# Get GUI display
# Usage: lbg_get_gui
# Return: GUI name
lbg_get_gui() {
	echo $lbg_gui
}


# Set default GUI display
# Usage: lbg_set_gui COMMAND
# Return: 0 if OK, 1 is usage error, 2 if GUI is not supported
lbg_set_gui() {
	if [ $# == 0 ] ; then
		return 1
	fi

	# test if GUI is supported
	lb_array_contains "$1" "${lbg_supported_gui[@]}"
	if [ $? == 0 ] ; then
		lbg_gui="$1"
	else
		return 2
	fi
}


# Prompt user to confirm an action in graphical mode
# Args: [options] <message>
# Return: continue (0:YES / 1:NO)
lbg_yesno() {
	# default values
	local lbg_yn_defaultyes=false
	local lbg_yn_yeslbl
	local lbg_yn_nolbl=""
	local lbg_yn_title="$(basename "$0")"
	local lbg_yn_cmd=()

	lbg_yn_yeslbl=""
	lbg_yn_nolbl=""

	# catch options
	while true ; do
		case "$1" in
			--yes|-y)
				lbg_yn_defaultyes=true
				shift
				;;
			--yes-label)
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
				lbg_yn_yeslbl="Yes"
			fi
			if [ -z "$lbg_yn_nolbl" ] ; then
				lbg_yn_nolbl="No"
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

	# execute Command
	"${lbg_yn_cmd[@]}"
}
