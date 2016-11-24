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

# set echo as default display command
lb_disp_cmd="echo"
# set echo as default error display command
lb_disp_error_cmd=">&2 echo"

lb_error_prefix="[ERROR] "

lb_gui=""

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
# Return: success code
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
# Args: [option -y: yes by default] <message>
# Return: continue (0:YES / 1:NO)
lb_yesno() {

	yesstr="y"
	nostr="n"

	if [ "$1" == "-y" ] ; then
		yesbydefault=true
		shift
	else
		yesbydefault=false
	fi

	if $yesbydefault ; then
		echo -e -n "$* (${yesstr^^}/$nostr) : "
	else
		echo -e -n "$* ($yesstr/${nostr^^}) : "
	fi

	read confirm

	# defaut behaviour if input is empty
	if [ -z $confirm ] ; then
		if $yesbydefault ; then
			continue=0
		else
			continue=1
		fi
	else
		# compare to confirmation string
		if [ ${confirm,,} == $yesstr ] ; then
			continue=0
		else
			continue=1
		fi
	fi

	return $continue
}


# Prompt user to confirm an action in graphical mode
# Args: [option -y: yes by default] <message>
# Return: continue (0:YES / 1:NO)
lb_yesno_gui() {

	if [ "$1" == "-y" ] ; then
		yesbydefault=true
		shift
	else
		yesbydefault=false
	fi



	return $continue
}
