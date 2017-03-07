#!/bin/bash -x

########################################################
#                                                      #
#  libbash.sh complete demo                            #
#                                                      #
#  MIT License                                         #
#  Copyright (c) 2017 Jean Prunneaux                   #
#  Website: https://github.com/pruje/libbash.sh        #
#                                                      #
########################################################


####################
#  INITIALIZATION  #
####################

# get real path of the script
if [ "$(uname)" == "Darwin" ] ; then
	# macOS which does not support readlink -f option
	current_script="$(perl -e 'use Cwd "abs_path";print abs_path(shift)' "$0")"
else
	current_script="$(readlink -f "$0")"
fi

# get directory of the current script
script_directory="$(dirname "$current_script")"

# load libbash
source "$script_directory/../libbash.sh" > /dev/null
if [ $? != 0 ] ; then
	echo >&2 "Error: cannot load libbash. Please add it to the '$script_directory/../libbash.sh' directory."
	exit 1
fi

# load libbash GUI
source "$script_directory/../libbash_gui.sh" > /dev/null
if [ $? != 0 ] ; then
	echo >&2 "Error: cannot load libbash GUI. Please add it to the '$script_directory/../libbash.sh' directory."
	exit 1
fi

# load translations

# get user language
lang="${LANG:0:2}"
# load translations (do not print errors if failed)
case "$lang" in
	fr)
		source "$script_directory/../locales/$lang.sh" &> /dev/null
		;;
esac

# change current script name
lb_current_script_name="libbash.sh DEMO"


###############
#  FUNCTIONS  #
###############

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
	if lbg_yesno -y "Do you really want to quit libbash.sh DEMO?" ; then
		quit_demo
	fi
}


# exit
quit_demo() {
	lb_display_debug "Exited with code: $lb_exitcode"
	lb_exit
}


##################
#  MAIN PROGRAM  #
##################

log_level="INFO"
consolemode=false

# get global options
while true ; do
	case "$1" in
		-c|--console)
			consolemode=true
			shift
			;;
		-l|--log-level)
			if lb_test_arguments -eq 0 $2 ; then
				usage
				exit 1
			fi
			log_level="$2"
			shift 2
			;;
		-d|--debug)
			debugmode=true
			shift
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

# choose option
if ! lbg_choose_option -l "Do you think you are running libbash.sh on:" "Linux" "macOS" ; then
	ask_exit
fi

case "$lbg_choose_option" in
	1)
		chosen_os="Linux"
		;;
	2)
		chosen_os="macOS"
		;;
esac

if [ "$(lb_detect_os)" == "$chosen_os" ] ; then
	lbg_display_info "Correct! You are on $(lb_detect_os)!"
else
	lbg_display_error "Incorrect! You are on $(lb_detect_os)!"
fi

lbg_display_info "DEMO is finished. See you later!"

# exit
quit_demo
