#!/bin/bash

####################################################
#
#  libbash.sh
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

# set version
libbash_version="0.1.0"

# set echo as default display command
lb_disp_cmd="echo"
# set echo as default error display command
lb_disp_error_cmd="echo >&2 "

lb_error_prefix="[ERROR] "


###############
#  FUNCTIONS  #
###############

lb_setdisplay() {
	lb_disp_cmd=$*
	return $?
}

# display a text
lb_display() {
	${lb_disp_cmd[@]} $*
	return $?
}

# display an error
lb_error() {
	${lb_disp_error_cmd[@]} "$lb_error_prefix"$*
	return $?
}


# Displays command result
# Usage: lb_result $result
# Return: exit code (0: yes, 1: no)
lb_result() {
	if [ $1 == 0 ] ; then
		lb_display "... Done"
		return 0
	else
		lb_display "... Failed!"
		return $1
	fi
}


############################
#  OPERATIONS ON VARIABLES #
############################

# Test if a variable is integer
# Usage: lb_is_integer VALUE
# Return: exit code (0: yes, 1: no)
lb_is_integer() {
	if [ $# == 0 ] ; then
		return 1
	fi

	if ! [[ $1 =~ ^-?[0-9]+$ ]] ; then
		return 1
	fi
}


# Search if array contains a value
# Usage: lb_array_contains VALUE "${array[@]}"
# Warning: put your array between quotes or it will fail if you have spaces in values
lb_array_contains() {
	# get usage errors
	if [ $# -lt 2 ] ; then
		return 1
	fi

	# first arg is the value to search
	lb_ac_search="$1"
	shift

	# get array to search in
	lb_ac_array=("$@")

	# parse array to find value
	for ((lb_ac_i=0 ; lb_ac_i < ${#lb_ac_array[@]} ; lb_ac_i++)) ; do
		# if found, return 0
		if [ "${lb_ac_array[$lb_ac_i]}" == "$lb_ac_search" ] ; then
			return 0
		fi
	done

	# if not found, return 2
	return 2
}


# Check if a bash function exists
# Usage: lb_function_exists FUNCTION_NAME
# Return: exit codes: 0 if exists, 1 if not, 2 if exists but is not a function
lb_function_exists() {
	if [ $# == 0 ] ; then
		return 1
	fi

	lb_fe_res="$(type -t $1)"
	if [ $? != 0 ] ; then
		return 1
	fi

	if [ "$lb_fe_res" != "function" ] ; then
		return 2
	fi
}


########
#  OS  #
########

# Detect OS
# Usage: lb_detect_os
# Return: Linux/macOS
lb_detect_os() {
	if [ "$(uname)" == "Darwin" ] ; then
		echo "macOS"
	else
		echo "Linux"
	fi
}


################
#  FILESYSTEM  #
################

# Get filesystem type
# Usage: lb_get_fstype PATH
# Return: fs type
lb_get_fstype() {
	# test if argument exists
	if [ $# == 0 ] ; then
		return 1
	fi

	# get type from df command
	df --output=fstype $1 2> /dev/null | tail -n 1
	return ${PIPESTATUS[0]}
}


# Get space left on device
# Usage: lb_space_left PATH
# Return: bytes available; exit code to 1 if error
lb_space_left() {
	if [ $# == 0 ] ; then
		return 1
	fi

	lb_sl_size=$(df "$1" | tail -1 | awk '{ print $4 }')
	if [ $? != 0 ] ; then
		return 1
	fi

	echo $lb_sl_size
}


# Test if a directory is empty
# Usage: lb_is_empty PATH
# Return: 0 if empty, 1 if not a directory, 2 access rights issue, 3 is not empty
lb_is_empty() {
	# test if argument exists
	if [ $# == 0 ] ; then
		return 1
	fi

	# test if directory exists
	if ! [ -d "$1" ] ; then
		return 1
	fi

	# test if directory is empty
	lb_is_res="$(ls -A "$1" 2> /dev/null)"
	if [ $? != 0 ] ; then
		return 2
	fi

	if [ "$lb_is_res" ] ; then
		return 3
	fi
}



######################
#  USER INTERACTION  #
######################

# Prompt user to confirm an action
# Usage: lb_yesno [options] TEXT
# Options:
#    -y, --yes        return yes by default
#    --yes-label STR  string to use as "YES"
#    --no-label  STR  string to use as "NO"
# Return: exit code (0: yes, 1: no)
lb_yesno() {

	# default options
	local lb_yn_defaultyes=false
	local lb_yn_yeslbl="y"
	local lb_yn_nolbl="n"

	# catch options
	while true ; do
		case "$1" in
			--yes|-y)
				lb_yn_defaultyes=true
				shift
				;;
			--yes-label)
				lb_yn_yeslbl="$2"
				shift 2
				;;
			--no-label)
				lb_yn_nolbl="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# defines choice question
	if $lb_yn_defaultyes ; then
		lb_yn_choice="($(echo $lb_yn_yeslbl | tr '[:lower:]' '[:upper:]')/$(echo $lb_yn_nolbl | tr '[:upper:]' '[:lower:]'))"
	else
		lb_yn_choice="($(echo $lb_yn_yeslbl | tr '[:upper:]' '[:lower:]')/$(echo $lb_yn_nolbl | tr '[:lower:]' '[:upper:]'))"
	fi

	# print question
	echo -e -n "$* $lb_yn_choice: "

	# read user input
	read lb_yn_confirm

	# defaut behaviour if input is empty
	if [ -z "$lb_yn_confirm" ] ; then
		if ! $lb_yn_defaultyes ; then
			return 1
		fi
	else
		# compare to confirmation string
		if [ "$(echo $lb_yn_confirm | tr '[:upper:]' '[:lower:]')" != "$(echo $lb_yn_yeslbl | tr '[:upper:]' '[:lower:]')" ] ; then
			return 1
		fi
	fi
}


# Prompt user to choose an option
# You can use up to 254 options
# Usage: lb_choose_option [options] TEXT OPTION [OPTION...]
# Options:
#    -d, --default ID  option to use by default (1-254)
# Return: exit code as option number (0: cancelled / 255: bad option)
lb_choose_option() {

	# catch bad usage
	if [ $# -lt 2 ] ; then
		return 255
	fi

	# default options and local variables
	local lb_chop_default=0
	local lb_chop_options=("")
	local lb_chop_i

	# catch options
	while true ; do
		case "$1" in
			--default|-d)
				lb_chop_default="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	lb_chop_text="$1"
	shift

	# prepare options; cannot support more than 254 options
	for ((lb_chop_i=1 ; lb_chop_i <= 254 ; lb_chop_i++)) ; do
		if [ -n "$1" ] ; then
			lb_chop_options+=("$1")
			shift
		else
			break
		fi
	done

	# verify default option
	if [ $lb_chop_default != 0 ] ; then
		if ! lb_is_integer "$lb_chop_default" ; then
			return 255
		else
			if [ $lb_chop_default -lt 0 ] || [ $lb_chop_default -gt ${#lb_chop_options[@]} ] ; then
				return 255
			fi
		fi
	fi

	# print question
	echo -e $lb_chop_text

	# print options
	for ((lb_chop_i=1 ; lb_chop_i < ${#lb_chop_options[@]} ; lb_chop_i++)) ; do
		echo "  $lb_chop_i. ${lb_chop_options[$lb_chop_i]}"
	done

	echo

	if [ $lb_chop_default != 0 ] ; then
		echo -n "[$lb_chop_default]"
	fi

	echo -n ": "

	# read user input
	read lb_chop_choice

	# defaut behaviour if input is empty
	if [ -z "$lb_chop_choice" ] ; then
		if [ $lb_chop_default != 0 ] ; then
			# default option
			return $lb_chop_default
		else
			# cancel code
			return 0
		fi
	else
		# check if user choice is integer
		if ! lb_is_integer "$lb_chop_choice" ; then
			return 255
		fi

		# check if user choice is valid
		if [ $lb_chop_choice -lt 0 ] || [ $lb_chop_choice -gt ${#lb_chop_options[@]} ] ; then
			return 255
		fi

		return $lb_chop_choice
	fi
}
