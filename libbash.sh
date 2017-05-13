########################################################
#                                                      #
#  libbash.sh                                          #
#  A library of useful functions for bash developers   #
#                                                      #
#  MIT License                                         #
#  Copyright (c) 2017 Jean Prunneaux                   #
#  Website: https://github.com/pruje/libbash.sh        #
#                                                      #
#  Version 1.0.0-beta.1 (2017-05-11)                   #
#                                                      #
########################################################


####################
#  MAIN VARIABLES  #
####################

# libbash main variables
lb_version="1.0.0-beta.1"
lb_path=$BASH_SOURCE
lb_directory=$(dirname "$lb_path")

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

# default log and display levels (CRITICAL ERROR WARNING INFO DEBUG)
lb_log_levels=("$lb_default_critical_label" "$lb_default_error_label" "$lb_default_warning_label" "$lb_default_info_label" "$lb_default_debug_label")

# initialize log file, log level and display level variables
lb_logfile=""
lb_log_level=""
lb_display_level=""

# print format
lb_format_print=true


####################
#  BASH UTILITIES  #
####################

# Check if a command exists
# Usage: lb_command_exists COMMAND
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


# Test number of arguments passed to a script/function
# Usage: lb_test_arguments OPERATOR N [ARG...]
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

	local lb_testarg_operator=$1
	local lb_testarg_value=$2
	shift 2

	# test if operator is ok
	case $lb_testarg_operator in
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

# Get current display level
# Usage: lb_get_display_level [OPTIONS] [LEVEL_NAME]
lb_get_display_level() {

	# default options
	local lb_getdisplevel_level=$lb_display_level
	local lb_getdisplevel_getid=false

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			--id)
				lb_getdisplevel_getid=true
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# if not specified, get actual log level
	if [ -z "$1" ] ; then
		if [ -z "$lb_display_level" ] ; then
			return 1
		else
			# print actual and exit
			if $lb_getdisplevel_getid ; then
				echo "$lb_display_level"
			else
				echo "${lb_log_levels[$lb_display_level]}"
			fi
			return 0
		fi
	else
		# get gived level name
		lb_getdisplevel_level=$1
	fi

	# search log level id for a gived level name
	for ((lb_getdisplevel_i=0 ; lb_getdisplevel_i < ${#lb_log_levels[@]} ; lb_getdisplevel_i++)) ; do
		# if found, return it
		if [ "${lb_log_levels[$lb_getdisplevel_i]}" == "$lb_getdisplevel_level" ] ; then
			if $lb_getdisplevel_getid ; then
				echo "$lb_getdisplevel_i"
			else
				echo "${lb_log_levels[$lb_getdisplevel_i]}"
			fi
			return 0
		fi
	done

	# if not found, return error
	return 2
}


# Set log level
# Usage: lb_set_display_level LEVEL_NAME
lb_set_display_level() {

	# usage error
	if [ -z "$1" ] ; then
		return 1
	fi

	# search if level exists
	for ((lb_setdisplevel_id=0 ; lb_setdisplevel_id < ${#lb_log_levels[@]} ; lb_setdisplevel_id++)) ; do
		# search by name and set level id
		if [ "${lb_log_levels[$lb_setdisplevel_id]}" == "$1" ] ; then
			lb_display_level=$lb_setdisplevel_id
			return 0
		fi
	done

	# if specified level not found, error
	return 2
}


# Print a message to the console, with colors and formatting
# Usage: lb_print [OPTIONS] TEXT
lb_print() {

	local lb_print_format=()
	local lb_print_opts=""
	local lb_print_resetcolor=""

	# get options
	while true ; do
		case $1 in
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
lb_display() {

	# default options
	local lb_display_log=false
	local lb_display_prefix=false
	local lb_display_opts=""
	local lb_display_displevel=""

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			-n)
				lb_display_opts="-n "
				;;
			-l|--level)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_display_displevel=$2
				shift
				;;
			-p|--prefix)
				lb_display_prefix=true
				;;
			--log)
				lb_display_log=true
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# other options
	local lb_display_exitcode=0
	local lb_display_display=true

	# if a display level is set,
	if [ -n "$lb_display_displevel" ] ; then
		# test current display level
		if [ -n "$lb_display_level" ] ; then
			lb_display_idlvl=$(lb_get_display_level --id "$lb_display_displevel")

			# Note: if level is unknown, message will be displayed
			if [ $? == 0 ] ; then
				# if display level is higher than default, do not display
				if [ $lb_display_idlvl -gt $lb_display_level ] ; then
					lb_display_display=false
				fi
			fi
		fi
	fi

	local lb_display_msgprefix=""

	# add level prefix
	if [ -n "$lb_display_displevel" ] ; then
		if $lb_display_prefix ; then
			lb_display_msgprefix="[$lb_display_displevel]  "
		fi
	fi

	# print into logfile
	if $lb_display_log ; then
		lb_display_logcmd=(lb_log $lb_display_opts)

		if [ -n "$lb_display_displevel" ] ; then
			lb_display_logcmd+=(--level "$lb_display_displevel")
		fi

		lb_display_logcmd+=("$lb_display_msgprefix$*")

		# execute lb_log
		"${lb_display_logcmd[@]}"
		if [ $? != 0 ] ; then
			lb_display_exitcode=2
		fi
	fi

	# if no display, return
	if ! $lb_display_display ; then
		return $lb_display_exitcode
	fi

	# enable coloured prefixes
	if $lb_display_prefix ; then
		case $lb_display_displevel in
			$lb_default_critical_label)
				lb_display_msgprefix=$(lb_print --red "$lb_display_displevel")
				;;
			$lb_default_error_label)
				lb_display_msgprefix=$(lb_print --red "$lb_display_displevel")
				;;
			$lb_default_warning_label)
				lb_display_msgprefix=$(lb_print --yellow "$lb_display_displevel")
				;;
			$lb_default_info_label)
				lb_display_msgprefix=$(lb_print --green "$lb_display_displevel")
				;;
			$lb_default_debug_label)
				lb_display_msgprefix=$(lb_print --cyan "$lb_display_displevel")
				;;
			*)
				lb_display_msgprefix=$lb_display_displevel
				;;
		esac

		lb_display_msgprefix="[$lb_display_msgprefix]  "
	fi

	# print text
	lb_print $lb_display_opts"$lb_display_msgprefix$*"
	if [ $? != 0 ] ; then
		return 3
	fi

	return $lb_display_exitcode
}


# Manage command result and display label
# Usage: lb_result [OPTIONS] [EXIT_CODE]
lb_result() {

	# get last command result
	local lb_result_res=$?

	# default values and options
	local lb_result_ok=$lb_default_result_ok_label
	local lb_result_failed=$lb_default_result_failed_label
	local lb_result_opts=""
	local lb_result_quiet=false
	local lb_result_save_exitcode=false
	local lb_result_error_exitcode=""
	local lb_result_exit_on_error=false

	# get options
	while true ; do
		case $1 in
			--ok-label)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_result_ok=$2
				shift 2
				;;
			--failed-label)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_result_failed=$2
				shift 2
				;;
			-l|--log-level)
				if [ -z "$2" ] ; then
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
		case $1 in
			-l|--log-level)
				if [ -z "$2" ] ; then
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
			lb_display $lb_shres_opts"[ $(echo "$lb_default_ok_label" | tr '[:lower:]' '[:upper:]') ]"
		fi
	else
		# if error (code 1-255)
		if ! $lb_shres_quiet ; then
			lb_display $lb_shres_opts"[ $(echo "$lb_default_failed_label" | tr '[:lower:]' '[:upper:]') ]"
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

# Return path of the defined log file
# Usage: lb_get_logfile
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
	echo "$lb_logfile"
}


# Set path of the log file
# Usage: lb_set_logfile [OPTIONS] PATH
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
		case $1 in
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
	local lb_setlogfile_path=$*

	# cancel if path exists but is not a regular file
	if [ -e "$lb_setlogfile_path" ] ; then
		if ! [ -f "$lb_setlogfile_path" ] ; then
			return 4
		fi
	fi

	# cancel if file is not writable
	if ! lb_is_writable "$lb_setlogfile_path" ; then
		return 2
	fi

	# if file exists
	if [ -f "$lb_setlogfile_path" ] ; then
		# overwrite file
		if $lb_setlogfile_erase ; then
			# empty file
			> "$lb_setlogfile_path"
		else
			# cancel if can not be append
			if ! $lb_setlogfile_append ; then
				return 3
			fi
		fi
	fi

	# set log file path
	lb_logfile=$lb_setlogfile_path

	# if not set, set higher log level
	if [ -z "$lb_log_level" ] ; then
		if [ ${#lb_log_levels[@]} -gt 0 ] ; then
			lb_log_level=$((${#lb_log_levels[@]} - 1))
		fi
	fi

	return 0
}


# Get current log level
# Usage: lb_get_log_level [OPTIONS] [LEVEL_NAME]
lb_get_log_level() {

	# default options
	local lb_getloglevel_level=$lb_log_level
	local lb_getloglevel_getid=false

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			--id)
				lb_getloglevel_getid=true
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# if not specified, get actual log level
	if [ -z "$1" ] ; then
		if [ -z "$lb_log_level" ] ; then
			return 1
		else
			# print actual and exit
			if $lb_getloglevel_getid ; then
				echo "$lb_log_level"
			else
				echo "${lb_log_levels[$lb_log_level]}"
			fi
			return 0
		fi
	else
		# get gived level name
		lb_getloglevel_level=$1
	fi

	# search log level id for a gived level name
	for ((lb_getloglevel_i=0 ; lb_getloglevel_i < ${#lb_log_levels[@]} ; lb_getloglevel_i++)) ; do
		# if found, return it
		if [ "${lb_log_levels[$lb_getloglevel_i]}" == "$lb_getloglevel_level" ] ; then
			if $lb_getloglevel_getid ; then
				echo "$lb_getloglevel_i"
			else
				echo "${lb_log_levels[$lb_getloglevel_i]}"
			fi
			return 0
		fi
	done

	# if not found, return error
	return 2
}


# Set log level
# Usage: lb_set_log_level LEVEL_NAME
lb_set_log_level() {

	# usage error
	if [ -z "$1" ] ; then
		return 1
	fi

	# search if level exists
	for ((lb_setloglevel_id=0 ; lb_setloglevel_id < ${#lb_log_levels[@]} ; lb_setloglevel_id++)) ; do
		# search by name and set level id
		if [ "${lb_log_levels[$lb_setloglevel_id]}" == "$1" ] ; then
			lb_log_level=$lb_setloglevel_id
			return 0
		fi
	done

	# if specified level not found, error
	return 2
}


# Print text into log file
# Usage: lb_log [OPTIONS] TEXT
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
	local lb_log_loglevel=""

	# get options
	while [ -n "$1" ] ; do
		case $1 in
			-n)
				lb_log_opts="-n "
				;;
			-l|--level)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_log_loglevel=$2
				shift
				;;
			-p|--prefix)
				lb_log_prefix=true
				;;
			-d|--date-prefix)
				lb_log_date=true
				;;
			-a|--all-prefixes)
				lb_log_prefix=true
				lb_log_date=true
				;;
			-x|--overwrite)
				lb_log_erase=true
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# if a default log level is set,
	if [ -n "$lb_log_loglevel" ] ; then
		# test current log level
		if [ -n "$lb_log_level" ] ; then
			lb_log_idlvl=$(lb_get_log_level --id "$lb_log_loglevel")

			# Note: if level unknown, message will be logged
			if [ $? == 0 ] ; then
				# if log level is higher than default, do not log
				if [ $lb_log_idlvl -gt $lb_log_level ] ; then
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
	if [ -n "$lb_log_loglevel" ] ; then
		if $lb_log_prefix ; then
			lb_log_text+="[$lb_log_loglevel] "
		fi
	fi

	# prepare text
	lb_log_text+=$*

	# tee options
	lb_log_teeopts=""

	# if not erase, append to file with tee -a
	if ! $lb_log_erase ; then
		lb_log_teeopts="-a "
	fi

	# print into log file; do not output text or errors
	echo -e $lb_log_opts"$lb_log_text" | tee $lb_log_teeopts"$lb_logfile" &> /dev/null

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


# Test if a value is a boolean
# Usage: lb_is_boolean VALUE
lb_is_boolean() {

	case $1 in
		true|false)
			return 0
			;;
		*)
			return 1
			;;
	esac
}


# Deletes spaces before and after a text
# Usage: lb_trim TEXT
lb_trim() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	local lb_trim_text=$*

	# remove spaces before text
	lb_trim_text=${lb_trim_text#${lb_trim_text%%[![:space:]]*}}

	# remove spaces after text
	lb_trim_text=${lb_trim_text%${lb_trim_text##*[![:space:]]}}

	echo "$lb_trim_text"
}


# Check if an array contains a value
# Usage: lb_array_contains VALUE "${ARRAY[@]}"
lb_array_contains() {

	# get usage errors
	if [ $# -lt 2 ] ; then
		return 1
	fi

	# first arg is the value to search
	local lb_arraycontains_search=$1
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


# Compare software versions using semantic versionning
# Usage: lb_compare_versions VERSION_1 OPERATOR VERSION_2
lb_compare_versions() {

	# we wait for at least an operator and 2 versions
	if [ $# -lt 3 ] ; then
		return 1
	fi

	# get operator
	local lb_cpver_operator=$2

	# check operator validity
	case $lb_cpver_operator in
		-eq|-ne|-lt|-le|-gt|-ge)
			# do nothing, continue
			;;
		*)
			# bad operator
			return 1
			;;
	esac

	# get versions, ignore builds (e.g. 1.0.0-rc.1+20170320 => 1.0.0-rc.1)
	local lb_cpver_v1=$(echo $1 | cut -d+ -f1)
	local lb_cpver_v2=$(echo $3 | cut -d+ -f1)

	# global comparison
	if [ "$lb_cpver_v1" == "$lb_cpver_v2" ] ; then
		# versions are equal
		case $lb_cpver_operator in
			-eq|-le|-ge)
				return 0
				;;
			-ne)
				return 2
				;;
		esac
	fi

	# get main version numbers
	local lb_cpver_v1_main=$(echo $lb_cpver_v1 | cut -d- -f1)
	local lb_cpver_v2_main=$(echo $lb_cpver_v2 | cut -d- -f1)

	# compare main version numbers
	if [ "$lb_cpver_v1_main" != "$lb_cpver_v2_main" ] ; then

		declare -i lb_cpver_i=1

		while true ; do

			if [[ "$lb_cpver_v1_main" == *"."* ]] ; then
				lb_cpver_v1_num=$(echo "$lb_cpver_v1_main" | cut -d. -f$lb_cpver_i)
			else
				if [ $lb_cpver_i == 1 ] ; then
					lb_cpver_v1_num=$lb_cpver_v1_main
				else
					# v3 => v3.0
					# v2.1 => v2.1.0
					lb_cpver_v1_num=0
				fi
			fi

			if [[ "$lb_cpver_v2_main" == *"."* ]] ; then
				lb_cpver_v2_num=$(echo "$lb_cpver_v2_main" | cut -d. -f$lb_cpver_i)
			else
				if [ $lb_cpver_i == 1 ] ; then
					lb_cpver_v2_num=$lb_cpver_v2_main
				else
					# v3 => v3.0
					# v2.1 => v2.1.0
					lb_cpver_v2_num=0
				fi
			fi

			if [ "$lb_cpver_v1_num" == "$lb_cpver_v2_num" ] ; then

				# end of comparison
				if [ $lb_cpver_v1_num == 0 ] && [ $lb_cpver_v2_num == 0 ] ; then
					break
				fi

				# compare next numbers
				lb_cpver_i+=1
				continue
			fi

			if lb_is_integer $lb_cpver_v1_num && lb_is_integer $lb_cpver_v2_num ; then
				# compare versions and quit
				[ "$lb_cpver_v1_num" $lb_cpver_operator "$lb_cpver_v2_num" ]
				return $?
			else
				# if not integer, error
				return 1
			fi
		done
	fi

	# get pre-release tags
	local lb_cpver_v1_tag=""
	if [[ "$lb_cpver_v1" == *"-"* ]] ; then
		lb_cpver_v1_tag=$(echo $lb_cpver_v1 | cut -d- -f2)
	fi

	local lb_cpver_v2_tag=""
	if [[ "$lb_cpver_v2" == *"-"* ]] ; then
		lb_cpver_v2_tag=$(echo $lb_cpver_v2 | cut -d- -f2)
	fi

	# tags are equal
	# this can happen if main versions are different
	# e.g. v1.0 == v1.0.0 or v2.1-beta == v2.1.0-beta
	if [ "$lb_cpver_v1_tag" == "$lb_cpver_v2_tag" ] ; then
		case $lb_cpver_operator in
			-eq|-le|-ge)
				return 0
				;;
			-ne|-lt|-gt)
				return 2
				;;
		esac
	else
		# tags are different
		case $lb_cpver_operator in
			-eq)
				return 2
				;;
			-ne)
				return 0
				;;
		esac
	fi

	# 1st tag is empty: final version is always superior to pre-release tags
	# e.g. v1.0.0 > v1.0.0-rc
	if [ -z "$lb_cpver_v1_tag" ] ; then
		case $lb_cpver_operator in
			-gt|-ge)
				return 0
				;;
			-lt|-le)
				return 2
				;;
		esac
	fi

	# 2nd tag is empty: final version is always superior to pre-release tags
	# e.g. v1.0.0-rc < v1.0.0
	if [ -z "$lb_cpver_v2_tag" ] ; then
		case $lb_cpver_operator in
			-gt|-ge)
				return 2
				;;
			-lt|-le)
				return 0
				;;
		esac
	fi

	# compare tags
	lb_cpver_tags=("$lb_cpver_v1_tag" "$lb_cpver_v2_tag")

	# save current field separator
	lb_cpver_IFS=$IFS
	# set new one
	IFS=$'\n'

	# sort tags in alphanumerical order
	lb_cpver_tags_2=($(sort <<<"${lb_cpver_tags[*]}"))

	# restore field separator
	IFS=$lb_cpver_IFS

	# tags order has changed => v1 > v2
	# e.g. ("1.0.0-beta" "1.0.0-alpha") => ("1.0.0-alpha" "1.0.0-beta")
	if [ "${lb_cpver_tags[0]}" != "${lb_cpver_tags_2[0]}" ] ; then
		case $lb_cpver_operator in
			-gt|-ge)
				return 0
				;;
		esac
	else
		# tags order has NOT changed => v1 < v2
		case $lb_cpver_operator in
			-lt|-le)
				return 0
				;;
		esac
	fi

	# other cases are errors
	return 2
}


# Test if a text is a comment
# Usage: lb_is_comment [OPTIONS] TEXT
lb_is_comment() {

	# default options
	local lb_iscom_symbols=()
	local lb_iscom_empty=true

	# get options
	while true ; do
		case $1 in
			-s|--symbol)
				if [ -z "$2" ] ; then
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
			lb_iscom_symbol=${lb_iscom_symbols[$lb_iscom_i]}

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
lb_df_fstype() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# get path
	local lb_dffstype_path=$*

	# if path does not exists, error
	if ! [ -e "$lb_dffstype_path" ] ; then
		return 2
	fi

	# get filesystem type
	if [ "$lb_current_os" == "macOS" ] ; then
		# get mountpoint
		lb_dffstype_mountpoint=$(lb_df_mountpoint "$lb_dffstype_path")
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
lb_df_space_left() {

	# if path does not exists, error
	if [ $# == 0 ] ; then
		return 1
	fi

	# get path
	local lb_dfspaceleft_path=$*

	# if path does not exists, error
	if ! [ -e "$lb_dfspaceleft_path" ] ; then
		return 2
	fi

	# get space available
	if [ "$lb_current_os" == "macOS" ] ; then
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


# Get mount point path of a partition
# Usage: lb_df_mountpoint PATH
lb_df_mountpoint() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# get path
	local lb_dfmountpoint_path=$*

	# if path does not exists, error
	if ! [ -e "$lb_dfmountpoint_path" ] ; then
		return 2
	fi

	# get mountpoint
	if [ "$lb_current_os" == "macOS" ] ; then
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
lb_df_uuid() {

	# if path does not exists, error
	if [ $# == 0 ] ; then
		return 1
	fi

	# get path
	local lb_dfuuid_path=$*

	# if path does not exists, error
	if ! [ -e "$lb_dfuuid_path" ] ; then
		return 2
	fi

	# macOS systems
	if [ "$lb_current_os" == "macOS" ] ; then
		# get mountpoint
		lb_dfuuid_mountpoint=$(lb_df_mountpoint "$lb_dfuuid_path")
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
				echo "$(basename "$lb_dfuuid_link")"
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
lb_dir_is_empty() {

	# usage error
	if [ $# == 0 ] ; then
		return 1
	fi

	# get directory path
	local lb_dir_is_empty_path=$*

	# test if directory exists
	if ! [ -d "$lb_dir_is_empty_path" ] ; then
		return 1
	fi

	# test if directory is empty
	lb_dir_is_empty_res=$(ls -A "$lb_dir_is_empty_path" 2> /dev/null)
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
lb_abspath() {

	# usage error
	if [ $# == 0 ] ; then
		return 1
	fi

	# get directory and file names
	local lb_abspath_dir=$(dirname "$*")
	local lb_abspath_file=$(basename "$*")
	local lb_abspath_path=""

	# root directory is always ok
	if [ "$lb_abspath_dir" == "/" ] ; then
		lb_abspath_path="/"
	else
		# get absolute path of the parent directory
		lb_abspath_path=$(cd "$lb_abspath_dir" &> /dev/null && pwd)

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
lb_realpath() {

	# usage error
	if [ $# == 0 ] ; then
		return 1
	fi

	# test if path exists
	if ! [ -e "$1" ] ; then
		return 1
	fi

	if [ "$lb_current_os" == "macOS" ] ; then
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
lb_is_writable() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	local lb_is_writable_path=$*

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

# Detect current OS family
# Usage: lb_current_os
lb_current_os() {

	# get uname result
	if [ "$(uname)" == "Darwin" ] ; then
		echo "macOS"
	else
		echo "Linux"
	fi
}


# Generate a random password
# Usage: lb_generate_password [SIZE]
lb_generate_password() {

	# default options
	local lb_genpwd_size=16

	# get size option
	if [ -n "$1" ] ; then
		# check if is integer
		if lb_is_integer $1 ; then
			# test size
			if [ $lb_genpwd_size -ge 1 ] && [ $lb_genpwd_size -le 32 ] ; then
				lb_genpwd_size=$1
			else
				return 1
			fi
		else
			return 1
		fi
	fi

	# generate password
	if lb_command_exists openssl ; then
		# with openssl random command
		lb_genpwd_pwd=$(openssl rand -base64 32 2> /dev/null)
	else
		# print date timestamp + nanoseconds then generate md5 checksum
		# then encode in base64
		if [ "$lb_current_os" == "macOS" ] ; then
			lb_genpwd_pwd=$(date +%s%N | shasum -a 256 | base64)
		else
			lb_genpwd_pwd=$(date +%s%N | sha256sum | base64)
		fi
	fi

	# return error if command failed
	if [ $? != 0 ] ; then
		return 2
	fi

	# return password at the right size
	echo "${lb_genpwd_pwd:0:$lb_genpwd_size}"
}


# Send an email
# Usage: lb_email [OPTIONS] RECIPIENT[,RECIPIENT,...] MESSAGE
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
		case $1 in
			-s|--subject)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_email_subject=$2
				shift 2
				;;
			--sender)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_email_sender=$2
				shift 2
				;;
			-r|--reply-to)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_email_replyto=$2
				shift 2
				;;
			-c|--cc)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_email_cc=$2
				shift 2
				;;
			-b|--bcc)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_email_bcc=$2
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

	local lb_email_recepients=$1
	shift

	# usage error if missing message
	# could be not detected by test above if recipents field has some spaces
	if lb_test_arguments -eq 0 $* ; then
		return 1
	fi

	# set email body
	local lb_email_message=$*

	# search compatible command to send email
	for lb_email_c in ${lb_email_commands[@]} ; do
		if lb_command_exists "$lb_email_c" ; then
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
	case $lb_email_command in
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

# Ask a question to user to answer by yes or no
# Usage: lb_yesno [OPTIONS] TEXT
lb_yesno() {

	# usage errors
	if [ $# == 0 ] ; then
		return 1
	fi

	# default options
	local lb_yn_defaultyes=false
	local lb_yn_cancel=false
	local lb_yn_yeslbl=$lb_default_yes_shortlabel
	local lb_yn_nolbl=$lb_default_no_shortlabel
	local lb_yn_cancellbl=$lb_default_cancel_shortlabel

	# get options
	while true ; do
		case $1 in
			-y|--yes)
				lb_yn_defaultyes=true
				shift
				;;
			-c|--cancel)
				lb_yn_cancel=true
				shift
				;;
			--yes-label)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_yn_yeslbl=$2
				shift 2
				;;
			--no-label)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_yn_nolbl=$2
				shift 2
				;;
			--cancel-label)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_yn_cancellbl=$2
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
		lb_yn_choice="($(echo "$lb_yn_yeslbl" | tr '[:lower:]' '[:upper:]')/$(echo "$lb_yn_nolbl" | tr '[:upper:]' '[:lower:]')"
	else
		lb_yn_choice="($(echo "$lb_yn_yeslbl" | tr '[:upper:]' '[:lower:]')/$(echo "$lb_yn_nolbl" | tr '[:lower:]' '[:upper:]')"
	fi

	# add cancel choice
	if $lb_yn_cancel ; then
		lb_yn_choice+="/$(echo "$lb_yn_cancellbl" | tr '[:upper:]' '[:lower:]')"
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
		if [ "$(echo "$lb_yn_confirm" | tr '[:upper:]' '[:lower:]')" != "$(echo "$lb_yn_yeslbl" | tr '[:upper:]' '[:lower:]')" ] ; then

			# cancel case
			if $lb_yn_cancel ; then
				if [ "$(echo "$lb_yn_confirm" | tr '[:upper:]' '[:lower:]')" == "$(echo "$lb_yn_cancellbl" | tr '[:upper:]' '[:lower:]')" ] ; then
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
	# options: initialize with an empty first value (option ID starts to 1, not 0)
	local lb_chop_options=("")
	local lb_chop_label=$lb_default_chopt_label
	local lb_chop_cancel_label=$lb_default_cancel_shortlabel

	# get command options
	while true ; do
		case $1 in
			-d|--default)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_chop_default=$2
				shift 2
				;;
			-l|--label)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_chop_label=$2
				shift 2
				;;
			-c|--cancel-label)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_chop_cancel_label=$2
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
	echo -e "$lb_chop_label"

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
		case $1 in
			-d|--default)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_inp_default=$2
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
			lb_input_text=$lb_inp_default
		else
			return 2
		fi
	fi

	return 0
}


# Ask user to enter a password
# Usage: lb_input_password [OPTIONS]
lb_input_password=""
lb_input_password() {

	# reset result
	lb_input_password=""

	# default options
	local lb_inpw_label=$lb_default_pwd_label
	local lb_inpw_confirm=false
	local lb_inpw_confirm_label=$lb_default_pwd_confirm_label
	local lb_inpw_minsize=0

	# get options
	while true ; do
		case $1 in
			-l|--label)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_inpw_label=$2
				shift 2
				;;
			-c|--confirm)
				lb_inpw_confirm=true
				shift
				;;
			--confirm-label)
				if [ -z "$2" ] ; then
					return 1
				fi
				lb_inpw_confirm_label=$2
				shift 2
				;;
			-m|--min-size)
				if ! lb_is_integer $2 ; then
					return 1
				fi
				if [ $2 -lt 1 ] ; then
					return 1
				fi
				lb_inpw_minsize=$2
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

	# check password size (if --min-size option is set)
	if [ $lb_inpw_minsize -gt 0 ] ; then
		if [ $(echo -n "$lb_input_password" | wc -m) -lt $lb_inpw_minsize ] ; then
			lb_input_password=""
			return 4
		fi
	fi

	# if no confirmation, return OK
	if ! $lb_inpw_confirm ; then
		return 0
	fi

	# if confirmation, save current password
	lb_inpw_password_confirm=$lb_input_password

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
	# basic command
	lb_cmd=(lb_print)

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}


# Print a message to stderr
# See lb_print for usage
lb_error() {
	# basic command
	lb_cmd=(lb_print)

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	>&2 "${lb_cmd[@]}"
}


# Get log level
# See lb_get_log_level for usage
lb_get_loglevel() {
	# basic command
	lb_cmd=(lb_get_log_level)

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}


# Set log level
# See lb_set_log_level for usage
lb_set_loglevel() {
	# basic command
	lb_cmd=(lb_set_log_level)

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}


# Common display levels functions
# See lb_display for usage
lb_display_critical() {
	# basic command
	lb_cmd=(lb_display -p -l "$lb_default_critical_label")

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}

lb_display_error() {
	# basic command
	lb_cmd=(lb_display -p -l "$lb_default_error_label")

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}

lb_display_warning() {
	# basic command
	lb_cmd=(lb_display -p -l "$lb_default_warning_label")

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}

lb_display_info() {
	# basic command
	lb_cmd=(lb_display -p -l "$lb_default_info_label")

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}

lb_display_debug() {
	# basic command
	lb_cmd=(lb_display -p -l "$lb_default_debug_label")

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}


# Common log functions
# Usage: lb_log_* [OPTIONS] TEXT
# See lb_log for options usage
lb_log_critical() {
	# basic command
	lb_cmd=(lb_log -p -l "$lb_default_critical_label")

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}

lb_log_error() {
	# basic command
	lb_cmd=(lb_log -p -l "$lb_default_error_label")

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}

lb_log_warning() {
	# basic command
	lb_cmd=(lb_log -p -l "$lb_default_warning_label")

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}

lb_log_info() {
	# basic command
	lb_cmd=(lb_log -p -l "$lb_default_info_label")

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}

lb_log_debug() {
	# basic command
	lb_cmd=(lb_log -p -l "$lb_default_debug_label")

	# parse arguments
	while [ -n "$1" ] ; do
		lb_cmd+=("$1")
		shift
	done

	# run command
	"${lb_cmd[@]}"
}


# Aliases for old functions compatibility
lb_detect_os() {
	lb_current_os
}


####################
#  INITIALIZATION  #
####################

# context variables
lb_current_script=$0
lb_current_script_name=$(basename "$0")
lb_current_script_directory=$(dirname "$0")
lb_current_path=$(pwd)
lb_current_os=$(lb_current_os)
lb_current_user=$(whoami)
lb_exitcode=0

# if macOS, do not print with colours
if [ "$lb_current_os" == "macOS" ] ; then
	lb_format_print=false
fi

# do not load libbash GUI by default
lb_load_gui=false

# get current user language (e.g. fr, en, ...)
lb_lang=${LANG:0:2}

# simple catch of options; no errors if bad options
while [ -n "$1" ] ; do
	case $1 in
		-g|--gui)
			lb_load_gui=true
			;;
		-l|--lang)
			if [ -n "$2" ] ; then
				lb_lang=$2
				shift
			fi
			;;
   esac

	# get next option
   shift
done

# load libbash GUI
if $lb_load_gui ; then
	source "$lb_directory/libbash_gui.sh"
	# in case of bad load, return error
	if [ $? != 0 ] ; then
		echo >&2 "Error: cannot load libbash GUI. Please verify the path $lb_directory."
		return 2
	fi
fi

# load translations (do not exit if errors)
case $lb_lang in
	fr)
		source "$lb_directory/locales/$lb_lang.sh" &> /dev/null
		if [ $? != 0 ] ; then
			echo >&2 "Error: cannot load the following libbash translation: $lb_lang"
		fi
		;;
esac
