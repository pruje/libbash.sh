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
# Args: exitcode (mostly $?)
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
# Args: [options] <message>
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



# Test if a variable is integer
# Arg: value
# Return: exit code (0: yes, 1: no)
lb_is_integer() {
	if [ "$1" == "" ] ; then
		return 1
	fi

	if ! [[ $1 =~ ^-?[0-9]+$ ]] ; then
		return 1
	fi
}
