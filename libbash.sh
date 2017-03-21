#!/bin/bash

########################################################
#                                                      #
#  libbash.sh                                          #
#  A library of useful functions for bash developers   #
#                                                      #
#  MIT License                                         #
#  Copyright (c) 2017 Jean Prunneaux                   #
#  Website: https://github.com/pruje/libbash.sh        #
#                                                      #
#  Version 0.3.2 (2017-03-21)                          #
#                                                      #
########################################################

lb_version="0.3.2"


####################
#  DEFAULT VALUES  #
####################

# default labels
lb_default_result_ok_label="... Done!"
lb_default_result_failed_label="... Failed!"
lb_default_ok_label="OK"
lb_default_cancel_label="Cancel"
lb_default_cancel_shortlabel="c"
lb_default_failed_label="Failed"
lb_default_yes_label="Yes"
lb_default_no_label="No"
lb_default_yes_shortlabel="y"
lb_default_no_shortlabel="n"
lb_default_pwd_label="Password:"
lb_default_pwd_confirm_label="Confirm password:"
lb_default_chopt_label="Choose an option:"
lb_default_chdir_label="Choose a directory:"
lb_default_chfile_label="Choose a file:"
lb_default_debug_label="DEBUG"
lb_default_info_label="INFO"
lb_default_warning_label="WARNING"
lb_default_error_label="ERROR"
lb_default_critical_label="CRITICAL"
lb_default_newfile_name="New file"

# set log file and default log levels
lb_logfile=""
lb_loglevel=""

# log levels, by default: ERROR WARNING INFO DEBUG
lb_loglevels=("$lb_default_critical_label" "$lb_default_error_label" "$lb_default_warning_label" "$lb_default_info_label" "$lb_default_debug_label")

# print format
lb_format_print=true


####################
#  BASH UTILITIES  #
####################

# Check if a command exists
# Usage: lb_command_exists COMMAND
# Exit codes:
#   0: command exists
#   1: usage error
#   2: command does not exists
lb_command_exists() {

	# usage error
	if [ $# == 0 ] ; then
		return 1
	fi

	# test command
	which "$1" &> /dev/null
	if [ $? != 0 ] ; then
		return 2
	fi

	return 0
}


# Check if a function exists
# Usage: lb_function_exists FUNCTION
# Exit codes:
#   0: function exists
#   1: usage error
#   2: function does not exists
#   3: command exists, but is not a function
lb_function_exists() {

	# usage error
	if [ $# == 0 ] ; then
		return 1
	fi

	# get type of argument
	lb_function_exists_res=$(type -t "$1")
	if [ $? != 0 ] ; then
		# if failed to get type, it does not exists
		return 2
	fi

	# test if is not a function
	if [ "$lb_function_exists_res" != "function" ] ; then
		return 3
	fi

	return 0
}


# Test arguments of a function
# Usage: lb_test_arguments OPERATOR N [ARG...]
# Note: A common usage of this function would be lb_test_arguments -ge 1 $*
#       to test if user has passed at least one argument to your script.
# Arguments:
#    OPERATOR  common bash comparison pattern: -eq|-ne|-lt|-le|-gt|-ge
#    N         expected number to compare to
#    ARG       your arguments; (e.g. $* without quotes)
# Exit code:
#   0: arguments OK
#   1: usage error
#   2: arguments not OK
lb_test_arguments() {

	# NOTE: be careful with improving this function to not use
	# third-party functions which are using this function to avoid infinite loops

	# we wait for at least an operator and a number
	if [ $# -lt 2 ] ; then
		return 1
	fi

	# arg 2 should be an integer
	if ! lb_is_integer $2 ; then
		return 1
	fi

	local lb_testarg_operator="$1"
	local lb_testarg_value=$2
	shift 2

	# test if operator is ok
	case "$lb_testarg_operator" in
		-eq|-ne|-lt|-le|-gt|-ge)
			# execute test on arguments number
			[ $# $lb_testarg_operator $lb_testarg_value ]
			;;
		*)
			# syntax error
			return 1
			;;
	esac

	# if test not OK
	if [ $? != 0 ] ; then
		return 2
	fi

	return 0
}


# Exit script with defined exit code
# Usage: lb_exit [EXIT_CODE]
# Options:
#   EXIT_CODE  Specify an exit code (if not set, $lb_exitcode will be used)
lb_exit() {

	# if exit code is set,
	if [ -n "$1" ] ; then
		# if it is an integer, exit with it
		if lb_is_integer $1 ; then
			exit $1
		else
			# if not an integer, exit with 1
			exit 1
		fi
	fi

	# exit with exitcode variable
	exit $lb_exitcode
}


#############
#  DISPLAY  #
#############

# Print a message to the console, with colors and formatting
# Usage: lb_print [OPTIONS] TEXT
# Options:
#   -n      no line return
#   --bold  print in bold format
#   --cyan, --green, --yellow, --red  print in selected color
# Exit code: exit code of the `echo` command
lb_print() {

	local lb_print_format=()
	local lb_print_opts=""
	local lb_print_resetcolor=""

	# get options
	while true ; do
		case "$1" in
			-n)
				lb_print_opts+="-n "
				shift
				;;
			--bold)
				lb_print_format+=(1)
				shift
				;;
			--cyan)
				lb_print_format+=(36)
				shift
				;;
			--green)
				lb_print_format+=(32)
				shift
				;;
			--yellow)
				lb_print_format+=(33)
				shift
				;;
			--red)
				lb_print_format+=(31)
				shift
				;;
			*)
				break
				;;
		esac
	done

	# append formatting options
	if $lb_format_print ; then
		if [ ${#lb_print_format[@]} -gt 0 ] ; then
			lb_print_opts+="\e["
			for lb_print_f in ${lb_print_format[@]} ; do
				lb_print_opts+=";$lb_print_f"
			done
			lb_print_opts+="m"

			lb_print_resetcolor="\e[0m"
		fi
	fi

	# print to the console
	echo -e $lb_print_opts"$*"$lb_print_resetcolor
}


# Print a message to the console, can set a verbose level and can append to logs
# Usage: lb_display [OPTIONS] TEXT
# Options:
#   -n                 no line return
#   -l, --level LEVEL  choose a display level (will be the same for logs)
#   -p, --prefix       print [LEVEL] prefix before text
#   --log              append text to log file if defined
# Exit codes:
#   0: OK
#   1: usage error
#   2: logs could not be written
#   3: unknown error while printing
lb_display() {

	# default options
	local lb_display_log=false
	local lb_display_prefix=false
	local lb_display_opts=""
	local lb_display_level=""
	local lb_display_exit=0

	# get options
	while true ; do
		case "$1" in
			-n)
				lb_display_opts="-n "
				shift
				;;
			-l|--level)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_display_level="$2"
				shift 2
				;;
			-p|--prefix)
				lb_display_prefix=true
				shift
				;;
			--log)
				lb_display_log=true
				shift
				;;
			*)
				break
				;;
		esac
	done

	# if a default log level is set,
	if [ -n "$lb_display_level" ] ; then
		# test current log level
		if [ -n "$lb_loglevel" ] ; then
			lb_display_idlvl=$(lb_get_loglevel --id "$lb_display_level")

			# (if failed, we will continue logging)
			if [ $? == 0 ] ; then
				# if log level is higher than default, do not log
				if [ $lb_display_idlvl -gt $lb_loglevel ] ; then
					return 0
				fi
			fi
		fi
	fi

	local lb_display_msgprefix=""

	# add prefix
	if $lb_display_prefix ; then
		lb_display_msgprefix="[$lb_display_level]  "
	fi

	# print into logfile
	if $lb_display_log ; then
		lb_display_logcmd=(lb_log $lb_display_opts)

		if [ -n "$lb_display_level" ] ; then
			lb_display_logcmd+=(--level "$lb_display_level")
		fi

		lb_display_logcmd+=("$lb_display_msgprefix$*")

		"${lb_display_logcmd[@]}"
		if [ $? != 0 ] ; then
			lb_display_exit=2
		fi
	fi

	# enable coloured prefixes
	if $lb_display_prefix ; then
		case "$lb_display_level" in
			"$lb_default_critical_label")
				lb_display_msgprefix="$(lb_print --red $lb_display_level)"
				;;
			"$lb_default_error_label")
				lb_display_msgprefix="$(lb_print --red $lb_display_level)"
				;;
			"$lb_default_warning_label")
				lb_display_msgprefix="$(lb_print --yellow $lb_display_level)"
				;;
			"$lb_default_info_label")
				lb_display_msgprefix="$(lb_print --green $lb_display_level)"
				;;
			"$lb_default_debug_label")
				lb_display_msgprefix="$(lb_print --cyan $lb_display_level)"
				;;
			*)
				lb_display_msgprefix="$lb_display_level"
				;;
		esac

		lb_display_msgprefix="[$lb_display_msgprefix]  "
	fi

	# print text
	lb_print $lb_display_opts"$lb_display_msgprefix$*"
	if [ $? != 0 ] ; then
		return 3
	fi

	return $lb_display_exit
}


# Manage command result and display label
# Usage: lb_result [OPTIONS] [EXIT_CODE]
# Options:
#   --ok-label TEXT            set a ok label
#   --failed-label TEXT        set a failed label
#   -l, --log-level LEVEL      set a log level
#   --log                      print result into log file
#   -s, --save-exitcode        save result to exit code
#   -e, --error-exitcode CODE  set an exitcode if error
#   -x, --exit-on-error        exit if result is not ok
#   -q, --quiet                quiet mode (do not print anything)
# Note: a very simple usage is to execute lb_result just after a command
#       and get result with $? just after that
# Exit code: 1 if usage error; forward exit code of the command
lb_result() {

	# get last command result
	local lb_result_res=$?

	# default values and options
	local lb_result_ok="$lb_default_result_ok_label"
	local lb_result_failed="$lb_default_result_failed_label"
	local lb_result_opts=""
	local lb_result_quiet=false
	local lb_result_save_exitcode=false
	local lb_result_error_exitcode=""
	local lb_result_exit_on_error=false

	# get options
	while true ; do
		case "$1" in
			--ok-label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_result_ok="$2"
				shift 2
				;;
			--failed-label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_result_failed="$2"
				shift 2
				;;
			-l|--log-level)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_result_opts="-l $2 "
				shift 2
				;;
			--log)
				lb_result_opts="--log "
				shift
				;;
			-s|--save-exitcode)
				lb_result_save_exitcode=true
				shift
				;;
			-e|--error-exitcode)
				# check type and validity
				if ! lb_is_integer $2 ; then
					return 1
				fi
				lb_result_error_exitcode=$2
				shift 2
				;;
			-x|--exit-on-error)
				lb_result_exit_on_error=true
				shift
				;;
			-q|--quiet)
				lb_result_quiet=true
				shift
				;;
			*)
				break
				;;
		esac
	done

	# specified exit code
	if [ -n "$1" ] ; then
		lb_result_res=$1
	fi

	# bad usage
	if ! lb_is_integer $lb_result_res ; then
		return 1
	fi

	# save result to exit code
	if $lb_result_save_exitcode ; then
		lb_exitcode=$lb_result_res
	fi

	# if result OK (code 0)
	if [ $lb_result_res == 0 ] ; then
		if ! $lb_result_quiet ; then
			lb_display $lb_result_opts"$lb_result_ok"
		fi
	else
		# if error (code 1-255)
		if ! $lb_result_quiet ; then
			lb_display $lb_result_opts"$lb_result_failed"
		fi

		# if save exit code is not set,
		if ! $lb_result_save_exitcode ; then
			# and error exitcode is specified, save it
			if [ -n "$lb_result_error_exitcode" ] ; then
				lb_exitcode=$lb_result_error_exitcode
			fi
		fi

		# if exit on error, exit
		if $lb_result_exit_on_error ; then
			lb_exit
		fi
	fi

	# return result code
	return $lb_result_res
}


# Manage command result and display label in short mode
# Usage: lb_short_result [OPTIONS] [EXIT_CODE]
# Options:
#   -l, --log-level LEVEL      set a log level
#   --log                      print result into log file
#   -s, --save-exitcode        save result to exit code
#   -e, --error-exitcode CODE  set an exitcode if error
#   -x, --exit-on-error        exit if result is not ok
#   -q, --quiet                quiet mode (do not print anything)
# See lb_result for options usage.
# Exit code: same than lb_result
lb_short_result() {

	# get last command result
	local lb_shres_res=$?

	# default values and options
	local lb_shres_opts=""
	local lb_shres_quiet=false
	local lb_shres_save_exitcode=false
	local lb_shres_error_exitcode=""
	local lb_shres_exit_on_error=false

	# get options
	while true ; do
		case "$1" in
			-l|--log-level)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_shres_opts="-l $2 "
				shift 2
				;;
			--log)
				lb_shres_opts="--log "
				shift
				;;
			-s|--save-exitcode)
				lb_shres_save_exitcode=true
				shift
				;;
			-e|--error-exitcode)
				# check type and validity
				if ! lb_is_integer $2 ; then
					return 1
				fi
				lb_shres_error_exitcode=$2
				shift 2
				;;
			-x|--exit-on-error)
				lb_shres_exit_on_error=true
				shift
				;;
			-q|--quiet)
				lb_shres_quiet=true
				shift
				;;
			*)
				break
				;;
		esac
	done

	# specified exit code
	if [ -n "$1" ] ; then
		lb_shres_res=$1
	fi

	# bad usage
	if ! lb_is_integer $lb_shres_res ; then
		return 1
	fi

	# save result to exit code
	if $lb_shres_save_exitcode ; then
		lb_exitcode=$lb_shres_res
	fi

	# if result OK (code 0)
	if [ $lb_shres_res == 0 ] ; then
		if ! $lb_shres_quiet ; then
			lb_display $lb_shres_opts"[ $(echo $lb_default_ok_label | tr '[:lower:]' '[:upper:]') ]"
		fi
	else
		# if error (code 1-255)
		if ! $lb_shres_quiet ; then
			lb_display $lb_shres_opts"[ $(echo $lb_default_failed_label | tr '[:lower:]' '[:upper:]') ]"
		fi

		# if save exit code is not set,
		if ! $lb_shres_save_exitcode ; then
			# and error exitcode is specified, save it
			if [ -n "$lb_shres_error_exitcode" ] ; then
				lb_exitcode=$lb_shres_error_exitcode
			fi
		fi

		# if exit on error, exit
		if $lb_shres_exit_on_error ; then
			lb_exit
		fi
	fi

	# return exit code
	return $lb_shres_res
}


##########
#  LOGS  #
##########

# Get log file path
# Usage: lb_get_logfile
# Return: path of the log file
# Exit codes:
#   0: file ok
#   1: log file not defined
#   2: log file is not writable
lb_get_logfile() {

	# if no log file defined
	if [ -z "$lb_logfile" ] ; then
		return 1
	fi

	# test if log file is writable
	if ! lb_is_writable "$lb_logfile" ; then
		return 2
	fi

	# return log file path
	echo $lb_logfile
}


# Set log file
# Usage: lb_set_logfile [OPTIONS] FILE
# Options:
#   -a, --append     if file already exists, append to it
#   -x, --overwrite  if file already exists, overwrite it
# Exit codes:
#   0: ok
#   1: usage error
#   2: file cannot be created or is not writable
#   3: file already exists, but append option is not set
#   4: path exists but is not a regular file
lb_set_logfile() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lb_setlogfile_erase=false
	local lb_setlogfile_append=false

	# get options
	while true ; do
		case "$1" in
			-a|--append)
				lb_setlogfile_append=true
				shift
				;;
			-x|--overwrite)
				lb_setlogfile_erase=true
				shift
				;;
			*)
				break
				;;
		esac
	done

	# test arguments
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# get file path
	local lb_setlogfile_file="$*"

	# cancel if path exists but is not a regular file
	if [ -e "$lb_setlogfile_file" ] ; then
		if ! [ -f "$lb_setlogfile_file" ] ; then
			return 4
		fi
	fi

	# cancel if file is not writable
	if ! lb_is_writable "$lb_setlogfile_file" ; then
		return 2
	fi

	# if file exists
	if [ -f "$lb_setlogfile_file" ] ; then
		# overwrite file
		if $lb_setlogfile_erase ; then
			# empty file
			> "$lb_setlogfile_file"
		else
			# cancel if can not be append
			if ! $lb_setlogfile_append ; then
				return 3
			fi
		fi
	fi

	# set log file path
	lb_logfile="$lb_setlogfile_file"

	# if not set, set higher log level
	if [ -z "$lb_loglevel" ] ; then
		if [ ${#lb_loglevels[@]} -gt 0 ] ; then
			lb_loglevel=$((${#lb_loglevels[@]} - 1))
		fi
	fi

	return 0
}


# Get current log level
# Usage: lb_get_loglevel [OPTIONS] [LEVEL]
# Options:
#   --id  get log level id instead of name
# Return: level (name or id)
# Exit codes:
#   0: OK
#   1: no log level is set
#   2: specified level not found
lb_get_loglevel() {

	# default options
	local lb_getloglevel_level=$lb_loglevel
	local lb_getloglevel_getid=false

	# get options
	while true ; do
		case "$1" in
			--id)
				lb_getloglevel_getid=true
				shift
				;;
			*)
				break
				;;
		esac
	done

	# if not specified, get actual log level
	if [ -z "$1" ] ; then
		if [ -z "$lb_loglevel" ] ; then
			return 1
		else
			# print actual and exit
			if $lb_getloglevel_getid ; then
				echo $lb_loglevel
			else
				echo ${lb_loglevels[$lb_loglevel]}
			fi
			return 0
		fi
	else
		# get gived level name
		lb_getloglevel_level=$1
	fi

	# search log level id for a gived level name
	for ((lb_getloglevel_i=0 ; lb_getloglevel_i < ${#lb_loglevels[@]} ; lb_getloglevel_i++)) ; do
		# if found, return it
		if [ "${lb_loglevels[$lb_getloglevel_i]}" == "$lb_getloglevel_level" ] ; then
			if $lb_getloglevel_getid ; then
				echo $lb_getloglevel_i
			else
				echo ${lb_loglevels[$lb_getloglevel_i]}
			fi
			return 0
		fi
	done

	# if not found, return error
	return 2
}


# Set log level
# Usage: lb_set_loglevel LEVEL
# Exit codes:
#   0: OK
#   1: usage error
#   2: level not found
lb_set_loglevel() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# search if level exists
	for ((lb_setloglevel_i=0 ; lb_setloglevel_i < ${#lb_loglevels[@]} ; lb_setloglevel_i++)) ; do
		# search by name and set level id
		if [ "${lb_loglevels[$lb_setloglevel_i]}" == "$1" ] ; then
			lb_loglevel=$lb_setloglevel_i
			return 0
		fi
	done

	# if specified level not found, error
	return 2
}


# Print text into log file
# Usage: lb_log [options] TEXT
# Options:
#   -n                  no line return
#   -l, --level LEVEL   set log level
#   -p, --level-prefix  print [LEVEL] prefix
#   -d, --date-prefix   print [date] prefix
#   -a, --all-prefix    print level and date prefixes
#   -x, --overwrite     clean before print in log file
# Exit codes:
#   0: OK
#   1: log file is not set
#   2: error while writing into file
lb_log() {

	# exit if log file is not set
	if [ -z "$lb_logfile" ] ; then
		return 1
	fi

	# default options
	local lb_log_date=false
	local lb_log_prefix=false
	local lb_log_erase=false
	local lb_log_opts=""
	local lb_log_level=""

	# get options
	while true ; do
		case "$1" in
			-n)
				lb_log_opts="-n "
				shift
				;;
			-l|--level)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_log_level="$2"
				shift 2
				;;
			-p|--prefix)
				lb_log_prefix=true
				shift
				;;
			-d|--date-prefix)
				lb_log_date=true
				shift
				;;
			-a|--all-prefixes)
				lb_log_prefix=true
				lb_log_date=true
				shift
				;;
			-x|--overwrite)
				lb_log_erase=true
				shift
				;;
			*)
				break
				;;
		esac
	done

	# if a default log level is set,
	if [ -n "$lb_log_level" ] ; then
		# test current log level
		if [ -n "$lb_loglevel" ] ; then
			lb_log_idlvl=$(lb_get_loglevel --id "$lb_log_level")

			# (if failed, we will continue logging)
			if [ $? == 0 ] ; then
				# if log level is higher than default, do not log
				if [ $lb_log_idlvl -gt $lb_loglevel ] ; then
					return 0
				fi
			fi
		fi
	fi

	# initialize log text
	local lb_log_text=""

	# add date prefix
	if $lb_log_date ; then
		lb_log_text+="[$(date +"%d %b %Y %H:%M:%S %z")] "
	fi

	# add level prefix
	if [ -n "$lb_log_level" ] ; then
		if $lb_log_prefix ; then
			lb_log_text+="[$lb_log_level] "
		fi
	fi

	# prepare text
	lb_log_text+="$*"

	# print into log file
	if $lb_log_erase ; then
		# overwrite mode
		echo -e $lb_log_opts$lb_log_text > "$lb_logfile"
	else
		# append to file
		echo -e $lb_log_opts$lb_log_text >> "$lb_logfile"
	fi

	# unknown write error
	if [ $? != 0 ] ; then
		return 2
	fi

	return 0
}


############################
#  OPERATIONS ON VARIABLES #
############################

# Test if a value is a number
# Usage: lb_is_number VALUE
# Exit codes:
#   0: value is a number
#   1: value is not a number
lb_is_number() {

	# if empty, is not a number (not an usage error)
	if [ $# == 0 ] ; then
		return 1
	fi

	# test if is a number (also works for negative numbers)
	if ! [[ $1 =~ ^-?[0-9]+([.][0-9]+)?$ ]] ; then
		return 1
	fi

	return 0
}


# Test if a value is integer
# Usage: lb_is_integer VALUE
# Exit codes:
#   0: value is an integer
#   1: value is not an integer
lb_is_integer() {

	# if empty, is not an integer (not an usage error)
	# DO NOT USE lb_test_arguments here or it will do an infinite loop
	# because lb_test_arguments uses this function
	if [ $# == 0 ] ; then
		return 1
	fi

	# test if is an integer (also works for negative numbers)
	if ! [[ $1 =~ ^-?[0-9]+$ ]] ; then
		return 1
	fi

	return 0
}


# Check if an array contains a value
# Usage: lb_array_contains VALUE "${ARRAY[@]}"
# Warning: put your array between quotes or it will fail if you have spaces in values
# Exit codes:
#   0: value is in array
#   1: usage error
#   2: value is not in array
lb_array_contains() {

	# get usage errors
	if [ $# -lt 2 ] ; then
		return 1
	fi

	# first arg is the value to search
	local lb_arraycontains_search="$1"
	shift

	# get array to search in
	local lb_arraycontains_array=("$@")

	# parse array to find value
	for ((lb_arraycontains_i=0 ; lb_arraycontains_i < ${#lb_arraycontains_array[@]} ; lb_arraycontains_i++)) ; do
		# if found, exit
		if [ "${lb_arraycontains_array[$lb_arraycontains_i]}" == "$lb_arraycontains_search" ] ; then
			return 0
		fi
	done

	# if not found, return 2
	return 2
}


# Test if a text is a comment
# Usage: lb_is_comment [OPTIONS] TEXT
# Options:
#   -s, --symbol STRING  Detect symbol as a comment (can use multiple values, '#' by default)
#   -n, --not-empty      Empty values are not considered as comments
# Exit codes:
#   0: is a comment
#   1: usage error
#   2: is not a comment
#   3: is empty (if --not-empty option is set)
lb_is_comment() {

	# default options
	local lb_iscom_symbols=()
	local lb_iscom_empty=true

	# get options
	while true ; do
		case "$1" in
			-s|--symbol)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_iscom_symbols=("$2")
				shift 2
				;;
			-n|--not-empty)
				lb_iscom_empty=false
				shift
				;;
			*)
				break
				;;
		esac
	done

	# set default comment symbol if none is set
	if [ ${#lb_iscom_symbols[@]} == 0 ] ; then
		lb_iscom_symbols+=("#")
	fi

	# delete spaces to find the first character
	lb_iscom_line=$(echo $* | tr -d '[:space:]')

	# empty line
	if [ -z "$lb_iscom_line" ] ; then
		if $lb_iscom_empty ; then
			return 0
		else
			return 3
		fi
	else
		# test if text starts with comment symbols
		for ((lb_iscom_i=0 ; lb_iscom_i < ${#lb_iscom_symbols[@]} ; lb_iscom_i++)) ; do
			lb_iscom_symbol="${lb_iscom_symbols[$lb_iscom_i]}"

			if [ "${lb_iscom_line:0:${#lb_iscom_symbol}}" == "$lb_iscom_symbol" ] ; then
				# is a comment: exit
				return 0
			fi
		done
	fi

	# symbol not found: not a comment
	return 2
}


################
#  FILESYSTEM  #
################

# Get filesystem type
# Usage: lb_df_fstype PATH
# Return: fs type
# Exit codes:
#   0: OK
#   1: usage error
#   2: path does not exists
#   3: unknown error
lb_df_fstype() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# get path
	local lb_dffstype_path="$*"

	# if path does not exists, error
	if ! [ -e "$lb_dffstype_path" ] ; then
		return 2
	fi

	# get filesystem type
	if [ "$(lb_detect_os)" == "macOS" ] ; then
		# get mountpoint
		lb_dffstype_mountpoint="$(lb_df_mountpoint "$lb_dffstype_path")"
		if [ $? != 0 ] ; then
			return 3
		fi

		# get filesystem type
		diskutil info "$lb_dffstype_mountpoint" | grep "Type (Bundle):" | cut -d: -f2 | awk '{print $1}'
	else
		df --output=fstype "$lb_dffstype_path" 2> /dev/null | tail -n 1
	fi

	# get df errors
	if [ ${PIPESTATUS[0]} != 0 ] ; then
		return 3
	fi

	return 0
}


# Get space left on partition in bytes
# Usage: lb_df_space_left PATH
# Return: bytes available
# Exit codes:
#   0: OK
#   1: usage error
#   2: PATH does not exists
#   3: unknown error
lb_df_space_left() {

	# if path does not exists, error
	if [ $# == 0 ] ; then
		return 1
	fi

	# get path
	local lb_dfspaceleft_path="$*"

	# if path does not exists, error
	if ! [ -e "$lb_dfspaceleft_path" ] ; then
		return 2
	fi

	# get space available
	if [ "$(lb_detect_os)" == "macOS" ] ; then
		df -b "$lb_dfspaceleft_path" 2> /dev/null | tail -n 1 | awk '{print $4}'
	else
		df -B1 --output=avail "$lb_dfspaceleft_path" 2> /dev/null | tail -n 1
	fi

	# get df errors
	if [ ${PIPESTATUS[0]} != 0 ] ; then
		return 3
	fi

	return 0
}


# Get mount point path
# Usage: lb_df_mountpoint PATH
# Return: mount point path
# Exit codes:
#   0: OK
#   1: usage error
#   2: path does not exists
#   3: unknown error
lb_df_mountpoint() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# get path
	local lb_dfmountpoint_path="$*"

	# if path does not exists, error
	if ! [ -e "$lb_dfmountpoint_path" ] ; then
		return 2
	fi

	# get mountpoint
	if [ "$(lb_detect_os)" == "macOS" ] ; then
		df "$lb_dfmountpoint_path" 2> /dev/null | tail -n 1 | awk '{for(i=9;i<=NF;++i) print $i}'
	else
		df --output=target "$lb_dfmountpoint_path" 2> /dev/null | tail -n 1
	fi

	# get df errors
	if [ ${PIPESTATUS[0]} != 0 ] ; then
		return 3
	fi

	return 0
}


# Get disk UUID
# Usage: lb_df_uuid PATH
# Return: disk UUID
# Exit codes:
#   O: OK
#   1: usage error
#   2: path does not exists
#   3: unknown error
#   4: UUID not found
lb_df_uuid() {

	# if path does not exists, error
	if [ $# == 0 ] ; then
		return 1
	fi

	# get path
	local lb_dfuuid_path="$*"

	# if path does not exists, error
	if ! [ -e "$lb_dfuuid_path" ] ; then
		return 2
	fi

	# macOS systems
	if [ "$(lb_detect_os)" == "macOS" ] ; then
		# get mountpoint
		lb_dfuuid_mountpoint="$(lb_df_mountpoint "$lb_dfuuid_path")"
		if [ $? != 0 ] ; then
			return 3
		fi

		# get filesystem type
		diskutil info "$lb_dfuuid_mountpoint" | grep "Volume UUID:" | cut -d: -f2 | awk '{print $1}'

		# get diskutil errors
		if [ ${PIPESTATUS[0]} != 0 ] ; then
			return 3
		fi

		# exit ok
		return 0
	else
		# Linux systems

		# UUID directory
		lb_dfuuid_list="/dev/disk/by-uuid"

		# check UUID directory
		if [ -d "$lb_dfuuid_list" ] ; then
			# check if there are UUIDs
			ls "$lb_dfuuid_list"/* &> /dev/null
			if [ $? != 0 ] ; then
				return 4
			fi
		else
			# if UUID folder not found, cancel
			return 4
		fi

		# get device
		lb_dfuuid_dev=$(df --output=source "$lb_dfuuid_path" 2> /dev/null | tail -n 1)
		if [ -z "$lb_dfuuid_dev" ] ; then
			return 3
		fi

		# search in UUID list
		for lb_dfuuid_link in "$lb_dfuuid_list"/* ; do
			# search if file is linked to the same device
			if [ "$(lb_realpath "$lb_dfuuid_link")" == "$lb_dfuuid_dev" ] ; then
				# if found, return UUID and exit
				echo $(basename "$lb_dfuuid_link")
				return 0
			fi
		done
	fi

	# UUID not found
	return 4
}


###########################
#  FILES AND DIRECTORIES  #
###########################

# Get user's home directory
# Usage: lb_get_home_directory [USER]
# Options: user (if not set, use current user)
# Return: home path
# Exit codes:
#   0: OK
#   1: path not found
lb_homepath() {

	# get ~user value
	eval lb_homedir=~$1

	# if not found, error
	if [ $? != 0 ] ; then
		return 1
	fi

	# if directory does not exists, error
	if ! [ -d "$lb_homedir" ] ; then
		return 1
	fi

	# return path
	echo "$lb_homedir"
}


# Test if a directory is empty
# Usage: lb_dir_is_empty PATH
# Exit codes:
#   0: directory is empty
#   1: path is not a directory
#   2: access rights issue
#   3: directory is not empty
lb_dir_is_empty() {

	# usage error
	if [ $# == 0 ] ; then
		return 1
	fi

	# get directory path
	local lb_dir_is_empty_path="$*"

	# test if directory exists
	if ! [ -d "$lb_dir_is_empty_path" ] ; then
		return 1
	fi

	# test if directory is empty
	lb_dir_is_empty_res="$(ls -A "$lb_dir_is_empty_path" 2> /dev/null)"
	if [ $? != 0 ] ; then
		# ls error means an access rights error
		return 2
	fi

	# directory is not empty
	if [ "$lb_dir_is_empty_res" ] ; then
		return 3
	fi

	return 0
}


# Get absolute path of a file/directory
# Usage: lb_abspath PATH
# Return: absolute path
# Exit codes:
#   0: OK
#   1: usage error
#   2: parent directory not found
lb_abspath() {

	# usage error
	if [ $# == 0 ] ; then
		return 1
	fi

	# get directory and file names
	local lb_abspath_dir="$(dirname "$*")"
	local lb_abspath_file="$(basename "$*")"
	local lb_abspath_path=""

	# root directory is always ok
	if [ "$lb_abspath_dir" == "/" ] ; then
		lb_abspath_path="/"
	else
		# get absolute path of the parent directory
		lb_abspath_path="$(cd "$lb_abspath_dir" &> /dev/null && pwd)"

		# if path does not exists, error
		if [ $? != 0 ] ; then
			return 2
		fi
	fi

	# case of root path (basename=/)
	if [ "$lb_abspath_file" == "/" ] ; then
		echo /
	else
		# return absolute path

		# case of the current directory (do not put /path/to/./)
		if [ "$lb_abspath_file" != "." ] ; then
			lb_abspath_path+="/$lb_abspath_file"
		fi

		echo "$lb_abspath_path"
	fi

	return 0
}


# Get real path of a file/directory
# Usage: lb_realpath PATH
# Return: real path
# Exit codes:
#   0: OK
#   1: usage error
#   2: path not found
lb_realpath() {

	# usage error
	if [ $# == 0 ] ; then
		return 1
	fi

	# test if path exists
	if ! [ -e "$1" ] ; then
		return 1
	fi

	if [ "$(lb_detect_os)" == "macOS" ] ; then
		# macOS which does not support readlink -f option
		perl -e 'use Cwd "abs_path";print abs_path(shift)' "$1"
	else
		readlink -f "$1"
	fi

	# error
	if [ $? != 0 ] ; then
		return 2
	fi
}


# Test if a path is writable
# Usage: lb_is_writable PATH
# Exit codes:
#   0: is writable (exists or can be created)
#   1: usage error
#   2: exists but is not writable
#   3: does not exists; parent directory is not writable
#   4: does not exists; parent directory does not exists
lb_is_writable() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	local lb_is_writable_path="$*"

	# if file/folder exists
	if [ -e "$lb_is_writable_path" ] ; then
		# cancel if not writable
		if ! [ -w "$lb_is_writable_path" ] ; then
			return 2
		fi
	else
		# if file/folder does not exists

		# cancel if parent directory does not exists
		if ! [ -d "$(dirname "$lb_is_writable_path")" ] ; then
			return 4
		fi

		# cancel if parent directory is not writable
		if ! [ -w "$(dirname "$lb_is_writable_path")" ] ; then
			return 3
		fi
	fi

	return 0
}



######################
#  SYSTEM UTILITIES  #
######################

# Detect current operating system family
# Usage: lb_detect_os
# Return: OS family (Linux/macOS)
lb_detect_os() {

	# get uname result
	if [ "$(uname)" == "Darwin" ] ; then
		echo "macOS"
	else
		echo "Linux"
	fi
}


# Send an email
# Usage: lb_email [OPTIONS] RECIPIENT[,RECIPIENT,...] MESSAGE
# Options:
#   -s, --subject TEXT           Email subject
#   --sender EMAIL               Sender email address
#   -r, --reply-to EMAIL         Email address to reply
#   -c, --cc EMAIL[,EMAIL,...]   Add email addresses in CC
#   -b, --bcc EMAIL[,EMAIL,...]  Add email addresses in BCC
# Exit codes:
#   0: email sent
#   1: usage error
#   2: no command to send email
#   3: unknown error from the program sender
lb_email() {

	# usage errors
	if [ $# -lt 2 ] ; then
		return 1
	fi

	# default options and local variables
	local lb_email_subject=""
	local lb_email_sender=""
	local lb_email_replyto=""
	local lb_email_cc=""
	local lb_email_bcc=""
	local lb_email_command=""
	local lb_email_header=""

	# available commands
	local lb_email_commands=(/usr/sbin/sendmail)

	# get options
	while true ; do
		case "$1" in
			-s|--subject)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_email_subject="$2"
				shift 2
				;;
			--sender)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_email_sender="$2"
				shift 2
				;;
			-r|--reply-to)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_email_replyto="$2"
				shift 2
				;;
			-c|--cc)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_email_cc="$2"
				shift 2
				;;
			-b|--bcc)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_email_bcc="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# usage error if missing text and at least one option
	if lb_test_arguments -lt 2 $* ; then
		return 1
	fi

	local lb_email_recepients="$1"
	shift

	# usage error if missing message
	# could be not detected by test above if recipents field has some spaces
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# set email body
	local lb_email_message="$*"

	# search compatible command to send email
	for lb_email_c in ${lb_email_commands[@]} ; do
		if lb_command_exists $lb_email_c ; then
			lb_email_command=$lb_email_c
			break
		fi
	done

	# if no command to send email, error
	if [ -z "$lb_email_command" ] ; then
		return 2
	fi

	# set email header

	if [ -n "$lb_email_sender" ] ; then
		lb_email_header+="From: $lb_email_sender\n"
	fi

	lb_email_header+="To: $lb_email_recepients\n"

	if [ -n "$lb_email_cc" ] ; then
		lb_email_header+="Cc: $lb_email_cc\n"
	fi

	if [ -n "$lb_email_bcc" ] ; then
		lb_email_header+="Bcc: $lb_email_bcc\n"
	fi

	if [ -n "$lb_email_replyto" ] ; then
		lb_email_header+="Reply-To: $lb_email_replyto\n"
	fi

	if [ -n "$lb_email_subject" ] ; then
		lb_email_header+="Subject: $lb_email_subject\n"
	fi

	lb_email_header+="MIME-Version: 1.0\nContent-Type: text/plain; charset=utf-8\n"

	# send email with program
	case "$lb_email_command" in
		/usr/sbin/sendmail)
			echo -e "$lb_email_header\n$lb_email_message" | /usr/sbin/sendmail -t
			# if unknown error
			if [ $? != 0 ] ; then
				return 3
			fi
			;;
		*)
			# no program found to send email
			return 2
			;;
	esac

	return 0
}


######################
#  USER INTERACTION  #
######################


# Prompt user to confirm an action
# Usage: lb_yesno [OPTIONS] TEXT
# Options:
#    -y, --yes            return yes by default
#    -c, --cancel         add a cancel option
#    --yes-label TEXT     label to use as "YES"
#    --no-label TEXT      label to use as "NO"
#    --cancel-label TEXT  label to use for cancel option
# Exit codes:
#   0: yes
#   1: usage error
#   2: no
#   3: cancel
lb_yesno() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lb_yn_defaultyes=false
	local lb_yn_cancel=false
	local lb_yn_yeslbl="$lb_default_yes_shortlabel"
	local lb_yn_nolbl="$lb_default_no_shortlabel"
	local lb_yn_cancellbl="$lb_default_cancel_shortlabel"

	# get options
	while true ; do
		case "$1" in
			-y|--yes)
				lb_yn_defaultyes=true
				shift
				;;
			-c|--cancel)
				lb_yn_cancel=true
				shift
				;;
			--yes-label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_yn_yeslbl="$2"
				shift 2
				;;
			--no-label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_yn_nolbl="$2"
				shift 2
				;;
			--cancel-label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_yn_cancellbl="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# usage error if question is missing
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# defines choice question
	if $lb_yn_defaultyes ; then
		lb_yn_choice="($(echo $lb_yn_yeslbl | tr '[:lower:]' '[:upper:]')/$(echo $lb_yn_nolbl | tr '[:upper:]' '[:lower:]')"
	else
		lb_yn_choice="($(echo $lb_yn_yeslbl | tr '[:upper:]' '[:lower:]')/$(echo $lb_yn_nolbl | tr '[:lower:]' '[:upper:]')"
	fi

	# add cancel choice
	if $lb_yn_cancel ; then
		lb_yn_choice+="/$(echo $lb_yn_cancellbl | tr '[:upper:]' '[:lower:]')"
	fi

	# ends question
	lb_yn_choice+=")"

	# print question
	echo -e -n "$* $lb_yn_choice: "

	# read user input
	read lb_yn_confirm

	# defaut behaviour if input is empty
	if [ -z "$lb_yn_confirm" ] ; then
		# if yes is not by default, answer is no
		if ! $lb_yn_defaultyes ; then
			return 2
		fi
	else
		# compare to confirmation string
		if [ "$(echo $lb_yn_confirm | tr '[:upper:]' '[:lower:]')" != "$(echo $lb_yn_yeslbl | tr '[:upper:]' '[:lower:]')" ] ; then

			# cancel case
			if $lb_yn_cancel ; then
				if [ "$(echo $lb_yn_confirm | tr '[:upper:]' '[:lower:]')" == "$(echo $lb_yn_cancellbl | tr '[:upper:]' '[:lower:]')" ] ; then
					return 3
				fi
			fi

			# answer is no
			return 2
		fi
	fi

	return 0
}


# Prompt user to choose an option
# Usage: lb_choose_option [OPTIONS] CHOICE [CHOICE...]
# Options:
#   -d, --default ID         option to use by default
#   -l, --label TEXT         set a question text (default: Choose an option:)
#   -c, --cancel-label TEXT  set a cancel label (default: c)
# Return: choice ID is stored into $lb_choose_option variable
# Exit codes:
#   0: OK
#   1: usage error
#   2: cancelled
#   3: bad choice
lb_choose_option=""
lb_choose_option() {

	# reset result
	lb_choose_option=""

	# must have at least 1 option
	if [ $# == 0 ] ; then
		return 1
	fi

	# default options and local variables
	local lb_chop_default=0
	local lb_chop_options=("")
	local lb_chop_label="$lb_default_chopt_label"
	local lb_chop_cancel_label="$lb_default_cancel_shortlabel"

	# get command options
	while true ; do
		case "$1" in
			-d|--default)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_chop_default="$2"
				shift 2
				;;
			-l|--label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_chop_label="$2"
				shift 2
				;;
			-c|--cancel-label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_chop_cancel_label="$2"
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

	# prepare choice options
	while true ; do
		if [ -n "$1" ] ; then
			lb_chop_options+=("$1")
			shift
		else
			break
		fi
	done

	# verify if default option is valid
	if [ $lb_chop_default != 0 ] ; then
		if ! lb_is_integer "$lb_chop_default" ; then
			# usage error
			return 1
		else
			# if ID is not in the choice range, return usage error
			if [ $lb_chop_default -lt 1 ] || [ $lb_chop_default -ge ${#lb_chop_options[@]} ] ; then
				return 1
			fi
		fi
	fi

	# print question
	echo -e $lb_chop_label

	# print options
	for ((lb_chop_i=1 ; lb_chop_i < ${#lb_chop_options[@]} ; lb_chop_i++)) ; do
		echo "  $lb_chop_i. ${lb_chop_options[$lb_chop_i]}"
	done

	echo

	# print default option
	if [ $lb_chop_default != 0 ] ; then
		echo -n "[$lb_chop_default]"
	else
		echo -n "[$lb_chop_cancel_label]"
	fi

	echo -n ": "

	# read user input
	read lb_choose_option

	# defaut behaviour if input is empty
	if [ -z "$lb_choose_option" ] ; then
		if [ $lb_chop_default != 0 ] ; then
			# default option
			lb_choose_option=$lb_chop_default
		else
			# cancel code
			return 2
		fi
	else
		# check cancel option
		if [ "$lb_choose_option" == "$lb_chop_cancel_label" ] ; then
			lb_choose_option=""
			return 2
		fi

		# check if user choice is integer
		if ! lb_is_integer "$lb_choose_option" ; then
			lb_choose_option=""
			return 3
		fi

		# check if user choice is valid
		if [ $lb_choose_option -lt 1 ] || [ $lb_choose_option -ge ${#lb_chop_options[@]} ] ; then
			lb_choose_option=""
			return 3
		fi
	fi

	return 0
}


# Ask user to enter a text
# Usage: lb_input_text [OPTIONS] TEXT
# Options:
#    -d, --default TEXT  default text
#    -n                  no line return after question
# Return: user input is stored into $lb_input_text variable
# Exit codes:
#   0: OK
#   1: usage error
#   2: empty text (cancelled)
lb_input_text=""
lb_input_text() {

	# reset result
	lb_input_text=""

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lb_inp_default=""
	local lb_inp_opts=""

	# catch options
	while true ; do
		case "$1" in
			-d|--default)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_inp_default="$2"
				shift 2
				;;
			-n)
				lb_inp_opts="-n "
				shift
				;;
			*)
				break
				;;
		esac
	done

	# usage error if text is not defined
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# print question
	echo -n -e "$*"

	if [ -n "$lb_inp_default" ] ; then
		echo -n -e " [$lb_inp_default]"
	fi

	# add separator
	echo $lb_inp_opts " "

	# read user input
	read lb_input_text

	# if empty
	if [ -z "$lb_input_text" ] ; then
		# default value if set
		if [ -n "$lb_inp_default" ] ; then
			lb_input_text="$lb_inp_default"
		else
			return 2
		fi
	fi

	return 0
}


# Ask user to enter a password (hidden)
# Usage: lb_input_password [OPTIONS]
# Options:
#    -l, --label TEXT      label for question
#    -c, --confirm         confirm password
#    --confirm-label TEXT  confirmation label
# Return: password is stored into $lb_input_password variable
# Exit codes:
#   0: OK
#   1: usage error
#   2: password is empty (cancelled)
#   3: passwords mismatch
lb_input_password=""
lb_input_password() {

	# reset result
	lb_input_password=""

	# default options
	local lb_inpw_label="$lb_default_pwd_label"
	local lb_inpw_confirm=false
	local lb_inpw_confirm_label="$lb_default_pwd_confirm_label"

	# get options
	while true ; do
		case "$1" in
			-l|--label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_inpw_label="$2"
				shift 2
				;;
			-c|--confirm)
				lb_inpw_confirm=true
				shift
				;;
			--confirm-label)
				if lb_test_arguments -eq 0 $2 ; then
					return 1
				fi
				lb_inpw_confirm_label="$2"
				shift 2
				;;
			*)
				break
				;;
		esac
	done

	# prompt user for password
	read -s -p "$lb_inpw_label " lb_input_password
	# line return
	echo

	# if empty, exit with error
	if [ -z "$lb_input_password" ] ; then
		return 2
	fi

	# if no confirmation, return OK
	if ! $lb_inpw_confirm ; then
		return 0
	fi

	# if confirmation, save current password
	lb_inpw_password_confirm="$lb_input_password"

	# prompt password confirmation
	read -s -p "$lb_inpw_confirm_label " lb_inpw_password_confirm
	# line return
	echo

	# if passwords mismatch, return error
	if [ "$lb_input_password" != "$lb_inpw_password_confirm" ] ; then
		lb_input_password=""
		return 3
	fi

	return 0
}


###############################
#  ALIASES AND COMPATIBILITY  #
###############################

# Print a message
# See lb_print for usage
lb_echo() {
	lb_print $*
}

# Print a message to stderr
# See lb_print for usage
lb_error() {
	>&2 lb_print $*
}

# Common display levels functions
# See lb_display for usage
lb_display_critical() {
	lb_display -p -l "$lb_default_critical_label" $*
}
lb_display_error() {
	lb_display -p -l "$lb_default_error_label" $*
}
lb_display_warning() {
	lb_display -p -l "$lb_default_warning_label" $*
}
lb_display_info() {
	lb_display -p -l "$lb_default_info_label" $*
}
lb_display_debug() {
	lb_display -p -l "$lb_default_debug_label" $*
}


# Common log functions
# Usage: lb_log_* [OPTIONS] TEXT
# See lb_log for options usage
lb_log_critical() {
	lb_log -p -l "$lb_default_critical_label" $*
}
lb_log_error() {
	lb_log -p -l "$lb_default_error_label" $*
}
lb_log_warning() {
	lb_log -p -l "$lb_default_warning_label" $*
}
lb_log_info() {
	lb_log -p -l "$lb_default_info_label" $*
}
lb_log_debug() {
	lb_log -p -l "$lb_default_debug_label" $*
}


####################
#  INITIALIZATION  #
####################

# if macOS, do not print with colours
if [ "$(lb_detect_os)" == "macOS" ] ; then
	lb_format_print=false
fi

# context variables
lb_current_script="$0"
lb_current_script_name="$(basename $0)"
lb_current_script_directory="$(dirname $0)"
lb_current_path="$(pwd)"
lb_exitcode=0
