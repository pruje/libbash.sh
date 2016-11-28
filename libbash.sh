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


# Prompt user to confirm an action
# Usage: lb_yesno [options] TEXT
# Options:
#    -y, --yes  return yes by default
#    --yes-str STR  string to use as "YES"
#    --no-str  STR  string to use as "NO"
# Return: exit code (0: yes, 1: no)
lb_yesno() {

	# default options
	local lb_yn_defaultyes=false
	local lb_yn_yesstr="y"
	local lb_yn_nostr="n"

	# catch options
	while true ; do
		case "$1" in
			--yes|-y)
				lb_yn_defaultyes=true
				shift
				;;
			--yes-str)
				lb_yn_yesstr="$2"
				shift 2
				;;
			--no-str)
				lb_yn_nostr="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# defines choice question
	if $lb_yn_defaultyes ; then
		lb_yn_choice="($(echo $lb_yn_yesstr | tr '[:lower:]' '[:upper:]')/$lb_yn_nostr)"
	else
		lb_yn_choice="($lb_yn_yesstr/$(echo $lb_yn_nostr | tr '[:lower:]' '[:upper:]'))"
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
		if [ "$(echo $lb_yn_confirm | tr '[:upper:]' '[:lower:]')" != "$lb_yn_yesstr" ] ; then
			return 1
		fi
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
