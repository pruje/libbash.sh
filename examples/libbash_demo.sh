#!/bin/bash
#
#  libbash.sh complete demo
#
#  MIT License
#  Copyright (c) 2017-2019 Jean Prunneaux
#  Website: https://github.com/pruje/libbash.sh
#


#
#  Initialization
#

# get real path of the script
if [ "$(uname)" == Darwin ] ; then
	# macOS which does not support readlink -f option
	current_script=$(perl -e 'use Cwd "abs_path";print abs_path(shift)' "$0")
else
	current_script=$(readlink -f "$0")
fi

# get directory of the current script
script_directory=$(dirname "$current_script")

# load libbash
source "$script_directory/../libbash.sh" --gui > /dev/null
if [ $? != 0 ] ; then
	echo >&2 "Error: cannot load libbash."
	exit 1
fi


# change current script name
lb_current_script_name="libbash.sh DEMO"


#
#  Functions
#

# print usage
usage() {
	lb_print "Usage: $0 [OPTIONS]"
	lb_print "Options:"
	lb_print "  -c, --console          execute demo in console mode (no dialog windows)"
	lb_print "  -l, --log-level LEVEL  set a verbose and log level (ERROR|WARNING|INFO|DEBUG)"
	lb_print "  -D, --debug            run in debug mode (all messages printed and logged)"
	lb_print "  -h, --help             print this help"
}


# ask before exit
ask_exit() {
	if lbg_yesno -y "Do you want to quit libbash.sh DEMO?" ; then
		quit_demo
	fi
}


# exit
quit_demo() {
	lb_display_debug "Exited with code: $lb_exitcode"
	lb_exit
}


#
#  Main program
#

log_level=INFO
consolemode=false

# get arguments
lb_getargs "$@" && set -- "${lb_getargs[@]}"

# get global options
while [ $# -gt 0 ] ; do
	case $1 in
		-c|--console)
			consolemode=true
			;;
		-l|--log-level)
			log_level=$(lb_getopt "$@")
			if [ $? != 0 ] ; then
				usage
				exit 1
			fi
			shift
			;;
		-d|--debug)
			debugmode=true
			;;
		-h|--help)
			usage
			exit
			;;
		-*)
			usage
			exit 1
			;;
		*)
			break
			;;
	esac
	shift
done

# disable dialogs if console mode
if $consolemode ; then
	lbg_set_gui console
fi

# set log level
if ! $debugmode ; then
	if ! lb_set_loglevel "$log_level" ; then
		lb_display_error "Cannot set log level!"
	fi
fi

lb_display_debug "libbash.sh DEMO running in DEBUG mode...\n"

# welcome dialog
if ! lbg_yesno "Welcome to libbash.sh DEMO. Do you want to continue?"; then
	quit_demo
fi

# choose your current OS
if ! lbg_choose_option -l "Do you think you are running libbash.sh on:" Linux macOS Windows ; then
	ask_exit
fi

# get results
case $lbg_choose_option in
	1)
		chosen_os=Linux
		;;
	2)
		chosen_os=macOS
		;;
	3)
		chosen_os=Windows
		;;
esac

# compare
if [ "$(lb_detect_os)" == "$chosen_os" ] ; then
	lbg_display_info "Correct! You are on $(lb_detect_os)!"
else
	lbg_display_error "Incorrect! You are on $(lb_detect_os)!"
fi

# send notification
lbg_notify "Hey! libbash.sh can send notifications!"

# choose a file
if lbg_choose_file -t "Choose the file you want" ; then
	lbg_display_info "You have chosen the file: $lbg_choose_file"
else
	ask_exit
fi

# enter a number
if lbg_input_text "Type a number between 1 and 10:" ; then

	# if it is a number
	if lb_is_integer $lbg_input_text ; then

		# compare
		if [ $lbg_input_text -ge 1 ] && [ $lbg_input_text -le 10 ] ; then
			lbg_display_info "Great! $lbg_input_text is between 1 and 10!"
		else
			lbg_display_warning "Your number is not between 1 and 10!"
		fi

	else
		# if it is not a number
		lbg_display_error "'$lbg_display_error' is not a number!"
	fi
else
	ask_exit
fi

# bye
lbg_display_info "DEMO is finished. Bye!"

# exit
quit_demo
