########################################################
#                                                      #
#  libbash.sh                                          #
#  A library of useful functions for bash developers   #
#                                                      #
#  MIT License                                         #
#  Copyright (c) 2017-2019 Jean Prunneaux              #
#  Website: https://github.com/pruje/libbash.sh        #
#                                                      #
#  Version 1.10.0 (2018-01-19)                         #
#                                                      #
########################################################

declare -r lb_version=1.10.0

# Index
#
#   * Main variables
#   * Bash utilities
#       lb_command_exists
#       lb_function_exists
#       lb_test_arguments
#       lb_getargs
#       lb_getopt
#       lb_exit
#   * Display
#       lb_get_display_level
#       lb_set_display_level
#       lb_print
#       lb_display
#       lb_result
#       lb_short_result
#   * Logs
#       lb_get_logfile
#       lb_set_logfile
#       lb_get_log_level
#       lb_set_log_level
#       lb_log
#   * Configuration files
#       lb_read_config
#       lb_import_config
#       lb_get_config
#       lb_set_config
#   * Operations on variables
#       lb_is_number
#       lb_is_integer
#       lb_is_boolean
#       lb_is_email
#       lb_is_comment
#       lb_trim
#       lb_split
#       lb_join
#       lb_in_array
#       lb_date2timestamp
#       lb_timestamp2date
#       lb_compare_versions
#   * Filesystem
#       lb_df_fstype
#       lb_df_space_left
#       lb_df_mountpoint
#       lb_df_uuid
#   * Files and directories
#       lb_homepath
#       lb_is_dir_empty
#       lb_abspath
#       lb_realpath
#       lb_is_writable
#       lb_edit
#   * System utilities
#       lb_current_os
#       lb_user_exists
#       lb_in_group
#       lb_group_members
#       lb_generate_password
#       lb_email
#   * User interacion
#       lb_yesno
#       lb_choose_option
#       lb_input_text
#       lb_input_password
#   * Aliases and compatibility
#       lb_echo
#       lb_error
#       lb_get_loglevel
#       lb_set_loglevel
#       lb_display_critical
#       lb_display_error
#       lb_display_warning
#       lb_warning
#       lb_display_info
#       lb_info
#       lb_display_debug
#       lb_debug
#       lb_log_critical
#       lb_log_error
#       lb_log_warning
#       lb_log_info
#       lb_log_debug
#       lb_detect_os
#       lb_array_contains
#       lb_dir_is_empty
#   * Initialization


####################
#  MAIN VARIABLES  #
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

# default log and display levels (CRITICAL ERROR WARNING INFO DEBUG)
lb_log_levels=("$lb_default_critical_label" "$lb_default_error_label" "$lb_default_warning_label" "$lb_default_info_label" "$lb_default_debug_label")

# initialize global variables
lb_logfile=""
lb_log_level=""
lb_display_level=""

# quiet mode
lb_quietmode=false

# print formatted strings in console
lb_format_print=true

# old sed command
lb_oldsed=false

# exit code
lb_exitcode=0
# command to execute when exit
lb_exit_cmd=()


####################
#  BASH UTILITIES  #
####################

# Check if command(s) exists
# Usage: lb_command_exists COMMAND [COMMAND...]
lb_command_exists() {
	which "$@" &> /dev/null
}


# Check if function(s) exists
# Usage: lb_function_exists FUNCTION [FUNCTION...]
lb_function_exists() {

	# usage error
	[ $# -gt 0 ] || return 1

	local arg type

	for arg in "$@" ; do
		# get type of argument
		# if failed to get type, it does not exists
		type=$(type -t $arg) || return 2

		# test if is not a function
		# Note: do not use && here to avoid returning 1
		if [ "$type" != function ] ; then
			return 3
		fi
	done
}


# Test number of arguments passed to a script/function
# Usage: lb_test_arguments OPERATOR N [ARG...]
lb_test_arguments() {

	# NOTE: be careful with improving this function to not use
	# third-party functions which are using this function to avoid infinite loops

	# we wait for at least an operator and a number
	[ $# -ge 2 ] || return 1

	# arg 2 should be an integer
	lb_is_integer $2 || return 1

	local operator=$1 value=$2
	shift 2

	# test if operator is ok
	case $operator in
		-eq|-ne|-lt|-le|-gt|-ge)
			# execute test on arguments number
			[ $# $operator $value ] || return 2
			;;
		*)
			# syntax error
			return 1
			;;
	esac
}


# Get command arguments and split options in array
# Usage: lb_getargs "$@"
lb_getargs=()
lb_getargs() {
	# reset arguments
	lb_getargs=()

	# no arguments
	[ $# == 0 ] && return 1

	# parse arguments
	local a
	for a in "$@" ; do
		# if multiple options combined, split them
		if [[ $a =~ ^-[a-zA-Z0-9]+$ ]] ; then
			lb_getargs+=($(echo "${a:1}" | grep -o . | sed 's/^/-/'))
		else
			# forward argument
			lb_getargs+=("$a")
		fi
	done
}


# Get value of an option (e.g. --tail 10 will return 10)
# Usage: lb_getopt "$@"
lb_getopt() {
	# if no value, quit
	[ $# -lt 2 ] && return 1

	# if next option, quit
	[ "${2:0:1}" == - ] && return 1

	# return option value
	echo "$2"
}


# Exit script with defined exit code
# Usage: lb_exit [OPTIONS] [EXIT_CODE]
lb_exit() {

	# default options
	local forward_code=false quiet_mode=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-f|--forward-exitcode)
				forward_code=true
				;;
			-q|--quiet)
				quiet_mode=true
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# if exit code is set,
	if [ -n "$1" ] ; then
		# set exitcode
		if lb_is_integer $1 ; then
			lb_exitcode=$1
		else
			# if not an integer, set to 255
			lb_exitcode=255
		fi
	fi

	# if an exit command is defined,
	if [ ${#lb_exit_cmd[@]} -gt 0 ] ; then

		local result=0

		# run command
		if $quiet_mode ; then
			"${lb_exit_cmd[@]}" &> /dev/null || result=$?
		else
			"${lb_exit_cmd[@]}" || result=$?
		fi

		# forward exit code option
		$forward_code && exit $result
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
	local i get_id=false level=$lb_display_level

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			--id)
				get_id=true
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
			if $get_id ; then
				echo $lb_display_level
			else
				echo "${lb_log_levels[lb_display_level]}"
			fi
			return 0
		fi
	else
		# get gived level name
		level=$1
	fi

	# search log level id for a gived level name
	for ((i=0 ; i < ${#lb_log_levels[@]} ; i++)) ; do
		# if found, return it
		if [ "${lb_log_levels[i]}" == "$level" ] ; then
			if $get_id ; then
				echo $i
			else
				echo "${lb_log_levels[i]}"
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

	# usage error: must be non empty
	[ -z "$1" ] && return 1

	# search if level exists
	local id
	for ((id=0 ; id < ${#lb_log_levels[@]} ; id++)) ; do
		# search by name and set level id
		if [ "${lb_log_levels[id]}" == $1 ] ; then
			lb_display_level=$id
			return 0
		fi
	done

	# if specified level not found, error
	return 2
}


# Print a message to the console, with colors and formatting
# Usage: lb_print [OPTIONS] TEXT
lb_print() {

	# quiet mode: do not print anything
	[ "$lb_quietmode" == true ] && return 0

	local opts reset_color format=()

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-e)
				# already done
				;;
			-n)
				opts+="-n "
				;;
			--bold)
				format+=(1)
				;;
			--cyan)
				format+=(36)
				;;
			--green)
				format+=(32)
				;;
			--yellow)
				format+=(33)
				;;
			--red)
				format+=(31)
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# append formatting options
	if $lb_format_print ; then
		if [ ${#format[@]} -gt 0 ] ; then
			opts+="\e["
			local f
			for f in ${format[@]} ; do
				opts+=";$f"
			done
			opts+="m"

			reset_color="\e[0m"
		fi
	fi

	# print to the console
	echo -e $opts"$*"$reset_color
}


# Print a message to the console, can set a verbose level and can append to logs
# Usage: lb_display [OPTIONS] TEXT
lb_display() {

	# default options
	local opts display_level display_prefix=false log_message=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-e)
				opts+="-e "
				;;
			-n)
				opts+="-n "
				;;
			-l|--level)
				[ -z "$2" ] && return 1
				display_level=$2
				shift
				;;
			-p|--prefix)
				display_prefix=true
				;;
			--log)
				log_message=true
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# other options
	local prefix display=true result=0

	# quiet mode: do not print anything
	[ "$lb_quietmode" == true ] && display=false

	# if a display level is set,
	if [ -n "$display_level" ] ; then
		# test current display level
		if [ -n "$lb_display_level" ] ; then
			# get display level ID
			local level_id

			# Note: if level is unknown, message will be displayed
			if level_id=$(lb_get_display_level --id "$display_level") ; then
				# if display level is higher than default, will not display (but can log)
				if [ $level_id -gt $lb_display_level ] ; then
					display=false
				fi
			fi
		fi
	fi

	# add level prefix
	if [ -n "$display_level" ] ; then
		if $display_prefix ; then
			prefix="[$display_level]  "
		fi
	fi

	# print into logfile
	if $log_message ; then
		# prepare command to log
		local log_cmd=(lb_log $opts)

		if [ -n "$display_level" ] ; then
			log_cmd+=(--level "$display_level")
		fi

		log_cmd+=("$prefix$*")

		# execute lb_log
		"${log_cmd[@]}" || result=2
	fi

	# if no need to display, quit
	$display || return $result

	# enable coloured prefixes
	if $display_prefix ; then
		case $display_level in
			$lb_default_critical_label)
				prefix="[$(lb_print --red "$display_level")]  "
				;;
			$lb_default_error_label)
				prefix="[$(lb_print --red "$display_level")]  "
				;;
			$lb_default_warning_label)
				prefix="[$(lb_print --yellow "$display_level")]  "
				;;
			$lb_default_info_label)
				prefix="[$(lb_print --green "$display_level")]  "
				;;
			$lb_default_debug_label)
				prefix="[$(lb_print --cyan "$display_level")]  "
				;;
			*)
				prefix="[$display_level]  "
				;;
		esac
	fi

	# print text
	lb_print $opts"$prefix$*" || return 3

	return $result
}


# Manage command result and display label
# Usage: lb_result [OPTIONS] [EXIT_CODE]
lb_result() {

	# get last command result
	local result=$?

	# default values and options
	local ok_label=$lb_default_result_ok_label failed_label=$lb_default_result_failed_label
	local display_cmd=(lb_display)
	local error_exitcode save_exitcode=false exit_on_error=false quiet_mode=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			--ok-label)
				[ -z "$2" ] && return 1
				ok_label=$2
				shift
				;;
			--failed-label)
				[ -z "$2" ] && return 1
				failed_label=$2
				shift
				;;
			-l|--log-level)
				[ -z "$2" ] && return 1
				display_cmd+=(-l "$2")
				shift
				;;
			--log)
				display_cmd+=(--log)
				;;
			-s|--save-exitcode)
				save_exitcode=true
				;;
			-e|--error-exitcode)
				# check type and validity
				lb_is_integer $2 || return 1
				error_exitcode=$2
				shift
				;;
			-x|--exit-on-error)
				exit_on_error=true
				;;
			-q|--quiet)
				quiet_mode=true
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# specified exit code
	if [ -n "$1" ] ; then
		# test type
		lb_is_integer $1 || return 1
		result=$1
	fi

	# save result to exit code
	if $save_exitcode ; then
		lb_exitcode=$result
	fi

	# if result OK (code 0)
	if [ $result == 0 ] ; then
		if ! $quiet_mode ; then
			# display result
			display_cmd+=("$ok_label")
			"${display_cmd[@]}"
		fi
	else
		# if error (code 1-255)
		if ! $quiet_mode ; then
			# display result
			display_cmd+=("$failed_label")
			"${display_cmd[@]}"
		fi

		# if save exit code is not set,
		if ! $save_exitcode ; then
			# and error exitcode is specified, save it
			if [ -n "$error_exitcode" ] ; then
				lb_exitcode=$error_exitcode
			fi
		fi

		# if exit on error, exit
		if $exit_on_error ; then
			lb_exit
		fi
	fi

	# return result code
	return $result
}


# Manage command result and display label in short mode
# Usage: lb_short_result [OPTIONS] [EXIT_CODE]
lb_short_result() {

	# get last command result
	local result=$?

	# default values and options
	local display_cmd=(lb_display)
	local error_exitcode save_exitcode=false exit_on_error=false quiet_mode=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-l|--log-level)
				[ -z "$2" ] && return 1
				display_cmd+=(-l "$2")
				shift
				;;
			--log)
				display_cmd+=(--log)
				;;
			-s|--save-exitcode)
				save_exitcode=true
				;;
			-e|--error-exitcode)
				# check type and validity
				lb_is_integer $2 || return 1
				error_exitcode=$2
				shift
				;;
			-x|--exit-on-error)
				exit_on_error=true
				;;
			-q|--quiet)
				quiet_mode=true
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# specified exit code
	if [ -n "$1" ] ; then
		# test type
		lb_is_integer $1 || return 1
		result=$1
	fi

	# save result to exit code
	if $save_exitcode ; then
		lb_exitcode=$result
	fi

	# if result OK (code 0)
	if [ $result == 0 ] ; then
		if ! $quiet_mode ; then
			# display result
			display_cmd+=("[ $(echo "$lb_default_ok_label" | tr '[:lower:]' '[:upper:]') ]")
			"${display_cmd[@]}"
		fi
	else
		# if error (code 1-255)
		if ! $quiet_mode ; then
			# display result
			display_cmd+=("[ $(echo "$lb_default_failed_label" | tr '[:lower:]' '[:upper:]') ]")
			"${display_cmd[@]}"
		fi

		# if save exit code is not set,
		if ! $save_exitcode ; then
			# and error exitcode is specified, save it
			if [ -n "$error_exitcode" ] ; then
				lb_exitcode=$error_exitcode
			fi
		fi

		# if exit on error, exit
		if $exit_on_error ; then
			lb_exit
		fi
	fi

	# return result code
	return $result
}


##########
#  LOGS  #
##########

# Return path of the defined log file
# Usage: lb_get_logfile
lb_get_logfile() {

	# if no log file defined, error
	[ -z "$lb_logfile" ] && return 1

	# test if log file is writable
	if ! lb_is_writable "$lb_logfile" ; then
		# do not return error if samba share: cannot determine rights in some cases
		if [ "$(lb_df_fstype "$(dirname "$lb_logfile")")" != smbfs ] ; then
			return 2
		fi
	fi

	# return log file path
	echo "$lb_logfile"
}


# Set path of the log file
# Usage: lb_set_logfile [OPTIONS] PATH
lb_set_logfile() {

	# default options
	local overwrite=false append=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-a|--append)
				append=true
				;;
			-x|--overwrite)
				overwrite=true
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error
	[ -n "$1" ] || return 1

	# cancel if path exists but is not a regular file
	if [ -e "$*" ] ; then
		[ -f "$*" ] || return 4
	fi

	# cancel if file is not writable
	if ! lb_is_writable "$*" ; then
		# do not return error if samba share: cannot determine rights in some cases
		if [ "$(lb_df_fstype "$(dirname "$*")")" != smbfs ] ; then
			return 2
		fi
	fi

	# if file exists
	if [ -f "$*" ] ; then
		# overwrite file
		if $overwrite ; then
			# empty file; if error, file is not writable
			> "$*" || return 2
		else
			# cancel if can not be append
			$append || return 3
		fi
	fi

	# set log file path
	lb_logfile=$*

	# if not set, set higher log level
	if [ -z "$lb_log_level" ] ; then
		if [ ${#lb_log_levels[@]} -gt 0 ] ; then
			lb_log_level=$((${#lb_log_levels[@]} - 1))
		fi
	fi
}


# Get current log level
# Usage: lb_get_log_level [OPTIONS] [LEVEL_NAME]
lb_get_log_level() {

	# default options
	local i get_id=false level=$lb_log_level

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			--id)
				get_id=true
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
			if $get_id ; then
				echo $lb_log_level
			else
				echo "${lb_log_levels[lb_log_level]}"
			fi
			return 0
		fi
	else
		# get gived level name
		level=$1
	fi

	# search log level id for a gived level name
	for ((i=0 ; i < ${#lb_log_levels[@]} ; i++)) ; do
		# if found, return it
		if [ "${lb_log_levels[i]}" == "$level" ] ; then
			if $get_id ; then
				echo $i
			else
				echo "${lb_log_levels[i]}"
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
	[ -z "$1" ] && return 1

	# search if level exists
	local id
	for ((id=0 ; id < ${#lb_log_levels[@]} ; id++)) ; do
		# search by name and set level id
		if [ "${lb_log_levels[id]}" == $1 ] ; then
			lb_log_level=$id
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
	[ -z "$lb_logfile" ] && return 1

	# default options
	local echo_opts level
	local prefix=false date_prefix=false overwrite=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-n)
				echo_opts="-n "
				;;
			-l|--level)
				[ -z "$2" ] && return 1
				level=$2
				shift
				;;
			-p|--prefix)
				prefix=true
				;;
			-d|--date-prefix)
				date_prefix=true
				;;
			-a|--all-prefixes)
				prefix=true
				date_prefix=true
				;;
			-x|--overwrite)
				overwrite=true
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# if a default log level is set,
	if [ -n "$level" ] ; then
		# test current log level
		if [ -n "$lb_log_level" ] ; then
			local id_level

			# Note: if level unknown, message will be logged
			if id_level=$(lb_get_log_level --id "$level") ; then
				# if log level is higher than default, do not log
				[ $id_level -gt $lb_log_level ] && return 0
			fi
		fi
	fi

	# initialize log text + tee options
	local log_message tee_opts

	# add date prefix
	if $date_prefix ; then
		log_message+="[$(date +"%d %b %Y %H:%M:%S %z")] "
	fi

	# add level prefix
	if [ -n "$level" ] ; then
		if $prefix ; then
			log_message+="[$level] "
		fi
	fi

	# prepare text
	log_message+=$*

	# if not erase, append to file with tee -a
	if ! $overwrite ; then
		tee_opts="-a "
	fi

	# print into log file; do not output text or errors
	echo -e $echo_opts"$log_message" | tee $tee_opts"$lb_logfile" &> /dev/null || return 2
}


########################
#  CONFIGURATION FILES #
########################

# Read a config file
# Usage: lb_read_config [OPTIONS] PATH
lb_read_config=()
lb_read_config() {

	# reset variable
	lb_read_config=()

	# default options
	local sections=()

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-s|--section)
				[ -z "$2" ] && return 1
				sections+=("[$2]")
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error
	if ! [ -f "$1" ] ; then
		return 1
	fi

	# test if file is readable
	if ! [ -r "$1" ] ; then
		return 2
	fi

	local line section good_section=false section_found=false

	# read config file line by line; backslashes are not escaped
	while read -r line ; do

		# testing if file has Windows format (\r at the end of line)
		if [ "${line:${#line}-1}" == $'\r' ] ; then
			# delete the last character \r
			line=${line:0:${#line}-1}
		fi

		# filter by sections
		if [ ${#sections[@]} -gt 0 ] ; then

			section=$(echo "$line" | tr -d '[:space:]' | grep -Eo "^\[.*\]")

			# if line is a section definition
			if [ -n "$section" ] ; then
				# if section is valid, mark it
				if lb_in_array "$section" "${sections[@]}" ; then
					good_section=true
					section_found=true
				else
					# if section is not valid, mark it and continue to the next line
					good_section=false
					continue
				fi
			else
				# if normal line,
				# if we are not in a good section, continue to the next line
				if ! $good_section ; then
					continue
				fi
			fi
		fi

		# add line to the lb_read_config variable
		lb_read_config+=("$line")

	done < <(grep -Ev '^\s*((#|;)|$)' "$1")

	# if section was not found, error
	if [ ${#sections[@]} -gt 0 ] ; then
		if ! $section_found ; then
			return 3
		fi
	fi
}


# Import a config file into bash variables
# Usage: lb_import_config [OPTIONS] PATH
lb_import_config() {

	# local variables and default options
	local sections=() return_errors=false secure_mode=true

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-s|--section)
				[ -z "$2" ] && return 1
				sections+=("[$2]")
				shift
				;;
			-e|--all-errors)
				return_errors=true
				;;
			-u|--unsecure)
				secure_mode=false
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# test if file exists
	if ! [ -f "$1" ] ; then
		return 1
	fi

	# test if file is readable
	if ! [ -r "$1" ] ; then
		return 5
	fi

	local result=0 line section value good_section=false section_found=false

	# read file line by line; backslashes are not escaped
	while read -r line ; do

		# testing if file has Windows format (\r at the end of line)
		if [ "${line:${#line}-1}" == $'\r' ] ; then
			# delete the last character \r
			line=${line:0:${#line}-1}
		fi

		# filter by sections
		if [ ${#sections[@]} -gt 0 ] ; then

			section=$(echo "$line" | tr -d '[:space:]' | grep -Eo "^\[.*\]")

			# if line is a section definition
			if [ -n "$section" ] ; then
				# if section is valid, mark it
				if lb_in_array "$section" "${sections[@]}" ; then
					good_section=true
					section_found=true
				else
					good_section=false
				fi
			else
				# if normal line,
				# if we are not in a good section, continue to the next line
				if ! $good_section ; then
					continue
				fi
			fi
		fi

		# check syntax of the line (param = value)
		if ! echo "$line" | grep -Eq "^\s*[a-zA-Z0-9_]+\s*=.*" ; then
			# if section definition, do nothing (not error)
			if ! echo "$line" | grep -Eq "^\[.*\]\s*$" ; then
				if $return_errors ; then
					result=3
				fi
			fi
			continue
		fi

		# get parameter and value
		# Note: use [[:space:]] for macOS compatibility
		value=$(echo "$line" | sed "s/^[[:space:]]*[a-zA-Z0-9_]*[[:space:]]*=[[:space:]]*//")

		# secure config values with prevent bash injection
		if $secure_mode ; then
			if echo "$value" | grep -Eq '\$|`' ; then
				if $return_errors ; then
					result=4
				fi
				continue
			fi
		fi

		# run command to attribute value to variable
		eval "$(echo "$line" | cut -d= -f1 | tr -d '[:space:]')=$value" &> /dev/null || result=2
	done < <(grep -Ev '^\s*((#|;)|$)' "$1")

	# if section was not found, return error
	if [ ${#sections[@]} -gt 0 ] ; then
		if ! $section_found ; then
			return 2
		fi
	fi

	return $result
}


# Get config value
# Usage: lb_get_config [OPTIONS] FILE PARAM
lb_get_config() {

	# default options
	local section

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-s|--section)
				[ -z "$2" ] && return 1
				section=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next option
	done

	# usage error
	[ $# -lt 2 ] && return 1

	# test config file
	if ! [ -f "$1" ] ; then
		return 1
	fi
	if ! [ -r "$1" ] ; then
		return 2
	fi

	# search config line
	local config_line=($(grep -En "^\s*$2\s*=" "$1" | cut -d: -f1))

	# if line not found, return error
	if [ ${#config_line[@]} == 0 ] ; then
		return 3
	fi

	# if no filter by section, print the first found
	if [ -z "$section" ] ; then
		sed "${config_line[0]}q;d" "$1" | sed "s/.*$2[[:space:]]*=[[:space:]]*//"
		return 0
	fi

	# parse every results
	local i j current_section
	for i in ${config_line[@]} ; do
		# if first line, cannot go up
		if [ $i == 1 ] ; then
			continue
		fi

		for ((j=$i-1; j>=1; j--)) ; do
			current_section=$(sed "${j}q;d" "$1" | grep -Eo "^\[.*\]")

			if [ -n "$current_section" ] ; then
				if [ "$current_section" == "[$section]" ] ; then
					# return value (and without any Windows endline)
					sed "${i}q;d" "$1" | sed "s/.*$2[[:space:]]*=[[:space:]]*//; s/\r$//"
					return 0
				fi
				break
			fi
		done
	done

	# if parameter not found in the right section, return error
	return 3
}


# Set config value
# Usage: lb_set_config [OPTIONS] FILE PARAM VALUE
lb_set_config() {

	# local variables
	local section strict_mode=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-s|--section)
				[ -z "$2" ] && return 1
				section=$2
				shift
				;;
			--strict)
				strict_mode=true
				;;
			*)
				break
				;;
		esac
		shift # load next option
	done

	# usage error
	[ $# -lt 2 ] && return 1

	# test config file
	if ! [ -f "$1" ] ; then
		return 1
	fi
	if ! [ -w "$1" ] ; then
		return 2
	fi

	local config_file=$1 param=$2
	shift 2

	# get value
	local value=$*

	# Windows files: add \r at the end of line
	if [ "$lb_current_os" == Windows ] ; then
		value+="\r"
	fi

	# prepare value for sed mode
	local sed_value=$(echo "$value" | sed 's/\//\\\//g')

	# search config line
	local config_line=($(grep -En "^\s*(#|;)*\s*$param\s*=" "$config_file" | cut -d: -f1))

	# get number of results
	local found=${#config_line[@]}

	# if line found, modify line (set the last one if multiple lines)
	if [ $found -gt 0 ] ; then

		# if filter by section,
		if [ -n "$section" ] ; then

			local i j section_found=false section_ready=false

			# parse every results
			for i in ${config_line[@]} ; do
				# if first line, cannot go up
				if [ $i == 1 ] ; then
					continue
				fi

				for ((j=$i-1; j>=1; j--)) ; do
					lb_setcf_current_section=$(sed "${j}q;d" "$config_file" | grep -Eo "^\[.*\]")

					if [ -n "$lb_setcf_current_section" ] ; then
						if [ "$lb_setcf_current_section" == "[$section]" ] ; then
							config_line=($i)
							found=1
							section_found=true
						fi
						break
					fi
				done

				if $section_found ; then
					section_ready=true
					break
				fi
			done
		fi

		# if ready to edit
		if $section_ready ; then
			# modify config file
			# Note: use [[:space:]] for macOS compatibility
			lb_edit "${config_line[found-1]}s/\(#\|;\)*[[:space:]]*$param[[:space:]]*=.*/$param = $sed_value/" "$config_file" || return 4
			return 0
		fi
	fi

	# if parameter not found (or not in the right section)

	# if strict mode, quit
	$strict_mode && return 3

	# if filter by section,
	if [ -n "$section" ] ; then

		# search for the right section
		config_line=($(grep -En "^\[$section\]$" "$config_file" | cut -d: -f1))

		# if section exists,
		if [ -n "$config_line" ] ; then
			# append parameter to section
			lb_edit "$((${config_line[0]}+1))i$param = $sed_value" "$config_file" || return 4
			return 0
		else
			# if section not found, append section to the end of file
			config_line="[$section]"

			# Windows files: add \r at the end of line
			if [ "$lb_current_os" == Windows ] ; then
				config_line+="\r"
			fi

			echo -e "$config_line" >> "$config_file" || return 4
		fi
	fi

	# append line to file
	echo -e "$param = $value" >> "$config_file" || return 4
}


############################
#  OPERATIONS ON VARIABLES #
############################

# Test if a value is a number
# Usage: lb_is_number VALUE
lb_is_number() {
	[[ $* =~ ^-?[0-9]+([.][0-9]+)?$ ]]
}


# Test if a value is integer
# Usage: lb_is_integer VALUE
lb_is_integer() {
	[[ $* =~ ^-?[0-9]+$ ]]
}


# Test if a value is a boolean
# Usage: lb_is_boolean VALUE
lb_is_boolean() {
	[[ $* =~ ^(true|false)$ ]]
}


# Test if a string is a valid email address
# Usage: lb_is_email STRING
lb_is_email() {
	[[ $* =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$ ]]
}


# Test if a text is a comment
# Usage: lb_is_comment [OPTIONS] TEXT
lb_is_comment() {

	# default options
	local symbols=() empty_is_comment=true

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-s|--symbol)
				[ -z "$2" ] && return 1
				symbols+=("$2")
				shift
				;;
			-n|--not-empty)
				empty_is_comment=false
				;;
			*)
				break
				;;
		esac
		shift # load next command
	done

	# delete spaces to find the first character
	# echo "$1" is to avoid * interpretation
	local line=$(echo "$1" | tr -d '[:space:]')

	# empty line
	if [ -z "$line" ] ; then
		if $empty_is_comment ; then
			return 0
		else
			return 3
		fi
	fi

	# set default comment symbol if none is set
	if [ ${#symbols[@]} == 0 ] ; then
		symbols+=("#")
	fi

	# test if text starts with comment symbol
	local s
	for s in ${symbols[@]} ; do
		if [ "${line:0:${#s}}" == "$s" ] ; then
			# is a comment: exit
			return 0
		fi
	done

	# symbol not found: not a comment
	return 2
}


# Deletes spaces before and after a string
# Usage: lb_trim STRING
lb_trim() {

	# empty text: do nothing
	[ $# == 0 ] && return 0

	local string=$*

	# remove spaces before string
	string=${string#${string%%[![:space:]]*}}

	# remove spaces after string
	string=${string%${string##*[![:space:]]}}

	# return string
	echo "$string"
}


# Split a string into array
# Usage: lb_split DELIMITER STRING
lb_split=()
lb_split() {

	# reset result
	lb_split=()

	# usage error
	[ -z "$1" ] && return 1

	# define delimiter
	local i IFS=$1
	shift

	# split string in array
	for i in $* ; do
		lb_split+=("$i")
	done
}


# Join an array into string
# Usage: lb_join DELIMITER "${ARRAY[@]}"
lb_join() {

	# usage error
	[ -z "$1" ] && return 1

	# define delimiter
	local IFS=$1
	shift

	# return string
	echo "$*"
}


# Check if an array contains a value
# Usage: lb_in_array VALUE "${ARRAY[@]}"
lb_in_array() {

	# usage error
	[ -z "$1" ] && return 1

	# get search value
	local value search=$1
	shift

	# if array is empty, return not found
	[ $# == 0 ] && return 2

	# parse array to find value
	for value in "$@" ; do
		[ "$value" == "$search" ] && return 0
	done

	# not found
	return 2
}


# Convert a date to timestamp
# Usage: lb_date2timestamp [OPTIONS] DATE
lb_date2timestamp() {

	# default options
	local cmd=(date)

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-u|--utc)
				cmd+=(-u)
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error
	[ -z "$1" ] && return 1

	# prepare command
	if [ "$lb_current_os" == macOS ] ; then
		cmd+=(-j -f '%Y-%m-%d %H:%M:%S' "$*" +%s)
	else
		cmd+=(-d "$*" +%s)
	fi

	# return timestamp
	"${cmd[@]}" 2> /dev/null || return 2
}


# Convert timestamp to an user readable date
# Usage: lb_timestamp2date [OPTIONS] TIMESTAMP
lb_timestamp2date() {

	# default options
	local format cmd=(date)

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-f|--format)
				[ -z "$2" ] && return 1
				format="+$2"
				shift
				;;
			-u|--utc)
				cmd+=(-u)
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error
	lb_is_integer $1 || return 1

	# prepare command
	if [ "$lb_current_os" == macOS ] ; then
		if [ -z "$format" ] ; then
			cmd+=(-j -f %s $1)
		else
			cmd+=(-j -f %s $1 "$format")
		fi
	else
		if [ -z "$format" ] ; then
			cmd+=(-d @$1)
		else
			cmd+=(-d @$1 "$format")
		fi
	fi

	# return formatted date
	"${cmd[@]}" 2> /dev/null || return 2
}


# Compare software versions using semantic versionning
# Usage: lb_compare_versions VERSION_1 OPERATOR VERSION_2
lb_compare_versions() {

	# we wait for at least an operator and 2 versions
	[ $# -lt 3 ] && return 1

	# get operator
	local operator=$2

	# check operator validity
	case $operator in
		-eq|-ne|-lt|-le|-gt|-ge)
			# do nothing, continue
			;;
		*)
			# bad operator
			return 1
			;;
	esac

	# get versions, ignore builds (e.g. 1.0.0-rc.1+20170320 => 1.0.0-rc.1)
	local version1=$(echo "$1" | tr -d '[:space:]' | cut -d+ -f1)
	local version2=$(echo "$3" | tr -d '[:space:]' | cut -d+ -f1)

	# global comparison
	if [ "$version1" == "$version2" ] ; then
		# versions are equal
		case $operator in
			-eq|-le|-ge)
				return 0
				;;
			-ne)
				return 2
				;;
		esac
	fi

	# get main version numbers
	local version1_main=$(echo "$version1" | tr -d '[:space:]' | cut -d- -f1)
	local version2_main=$(echo "$version2" | tr -d '[:space:]' | cut -d- -f1)

	# compare main version numbers
	if [ "$version1_main" != "$version2_main" ] ; then

		local version1_num version2_num
		local -i i=1

		# compare version numbers separated by dots
		while true ; do

			# get major number
			if [ $i == 1 ] ; then
				version1_num=$(echo "$version1_main" | cut -d. -f$i)
				version2_num=$(echo "$version2_main" | cut -d. -f$i)
			else
				# get minor numbers
				version1_num=$(echo "$version1_main" | cut -d. -s -f$i)
				version2_num=$(echo "$version2_main" | cut -d. -s -f$i)
			fi

			# transform simple numbers to dotted numbers
			# e.g. v3 => v3.0, v2.1 => v2.1.0
			if [ -z "$version1_num" ] ; then
				version1_num=0
			fi
			if [ -z "$version2_num" ] ; then
				version2_num=0
			fi

			if [ "$version1_num" == "$version2_num" ] ; then

				# if minor numbers (x.x.x.0), avoid infinite loop
				if [ $i -gt 3 ] ; then
					# end of comparison
					if [ $version1_num == 0 ] && [ $version2_num == 0 ] ; then
						break
					fi
				fi

				# compare next numbers
				i+=1
				continue
			fi

			if lb_is_integer $version1_num && lb_is_integer $version2_num ; then
				# compare versions and quit
				[ "$version1_num" $operator "$version2_num" ] || return 2
				return 0
			else
				# if not integer, error
				return 1
			fi
		done
	fi

	# get pre-release tags
	local version1_tag version2_tag
	if [[ "$version1" == *"-"* ]] ; then
		version1_tag=$(echo "$version1" | tr -d '[:space:]' | cut -d- -f2)
	fi
	if [[ "$version2" == *"-"* ]] ; then
		version2_tag=$(echo "$version2" | tr -d '[:space:]' | cut -d- -f2)
	fi

	# tags are equal
	# this can happen if main versions are different
	# e.g. v1.0 == v1.0.0 or v2.1-beta == v2.1.0-beta
	if [ "$version1_tag" == "$version2_tag" ] ; then
		case $operator in
			-eq|-le|-ge)
				return 0
				;;
			-ne|-lt|-gt)
				return 2
				;;
		esac
	else
		# tags are different
		case $operator in
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
	if [ -z "$version1_tag" ] ; then
		case $operator in
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
	if [ -z "$version2_tag" ] ; then
		case $operator in
			-gt|-ge)
				return 2
				;;
			-lt|-le)
				return 0
				;;
		esac
	fi

	# compare tags
	local tags1=("$version1_tag" "$version2_tag")

	# save current field separator and set a new with line return
	local old_IFS=$IFS IFS=$'\n'

	# sort tags in alphanumerical order
	local tags2=($(sort <<<"${tags1[*]}"))

	# restore field separator
	IFS=$old_IFS

	# tags order has changed => v1 > v2
	# e.g. ("1.0.0-beta" "1.0.0-alpha") => ("1.0.0-alpha" "1.0.0-beta")
	if [ "${tags1[0]}" != "${tags2[0]}" ] ; then
		case $operator in
			-gt|-ge)
				return 0
				;;
		esac
	else
		# tags order has NOT changed => v1 < v2
		case $operator in
			-lt|-le)
				return 0
				;;
		esac
	fi

	# other cases are errors
	return 2
}


################
#  FILESYSTEM  #
################

# Get filesystem type
# Usage: lb_df_fstype PATH
lb_df_fstype() {

	# usage error
	[ $# == 0 ] && return 1

	# if path does not exists, error
	if ! [ -e "$*" ] ; then
		return 2
	fi

	case $lb_current_os in
		Linux)
			if lb_command_exists lsblk ; then
				# get device
				local device=$(df --output=source "$*" 2> /dev/null | tail -n 1)
				[ -z "$device" ] && return 3

				# get "real" fs type
				lsblk --output=FSTYPE "$device" 2> /dev/null | tail -n 1
			else
				# no lsblk command: use df command
				df --output=fstype "$*" 2> /dev/null | tail -n 1
			fi
			;;

		macOS)
			# get mountpoint
			local mount_point
			mount_point=$(lb_df_mountpoint "$*") || return 3

			# get filesystem type
			diskutil info "$mount_point" | grep "Type (Bundle):" | cut -d: -f2 | awk '{print $1}'
			;;

		*) # Windows and other
			df --output=fstype "$*" 2> /dev/null | tail -n 1
			;;
	esac

	# get other errors
	if [ ${PIPESTATUS[0]} != 0 ] ; then
		return 3
	fi
}


# Get space left on partition in bytes
# Usage: lb_df_space_left PATH
lb_df_space_left() {

	# usage error
	[ $# == 0 ] && return 1

	# if path does not exists, error
	if ! [ -e "$*" ] ; then
		return 2
	fi

	# get space available
	if [ "$lb_current_os" == macOS ] ; then
		df -k "$*" 2> /dev/null | tail -n 1 | awk '{print $4}'
	else
		df -k --output=avail "$*" 2> /dev/null | tail -n 1
	fi

	# get df errors
	if [ ${PIPESTATUS[0]} != 0 ] ; then
		return 3
	fi
}


# Get mount point path of a partition
# Usage: lb_df_mountpoint PATH
lb_df_mountpoint() {

	# usage error
	[ $# == 0 ] && return 1

	# if path does not exists, error
	if ! [ -e "$*" ] ; then
		return 2
	fi

	# get mountpoint
	if [ "$lb_current_os" == macOS ] ; then
		df "$*" 2> /dev/null | tail -n 1 | awk '{for(i=9;i<=NF;++i) print $i}'
	else
		df --output=target "$*" 2> /dev/null | tail -n 1
	fi

	# get df errors
	if [ ${PIPESTATUS[0]} != 0 ] ; then
		return 3
	fi
}


# Get disk UUID
# Usage: lb_df_uuid PATH
# NOT SUPPORTED ON WINDOWS
lb_df_uuid() {

	# usage error
	[ $# == 0 ] && return 1

	# if path does not exists, error
	if ! [ -e "$*" ] ; then
		return 2
	fi

	case $lb_current_os in
		macOS)
			# get mountpoint
			local mount_point
			mount_point=$(lb_df_mountpoint "$*") || return 3

			# get filesystem type
			diskutil info "$mount_point" | grep "Volume UUID:" | cut -d: -f2 | awk '{print $1}'
			;;

		Linux)
			# get device
			local device=$(df --output=source "$*" 2> /dev/null | tail -n 1)
			[ -z "$device" ] && return 3

			# get disk UUID
			lsblk --output=UUID "$device" 2> /dev/null | tail -n 1
			;;

		*) # other OS not supported
			return 4
			;;
	esac

	# get unknown errors
	if [ ${PIPESTATUS[0]} != 0 ] ; then
		return 3
	fi
}


###########################
#  FILES AND DIRECTORIES  #
###########################

# Get user's home directory
# Usage: lb_get_home_directory [USER]
lb_homepath() {

	local path

	# get ~user value
	eval path=~$1

	# if directory does not exists, error
	if ! [ -d "$path" ] ; then
		return 1
	fi

	# return path
	echo "$path"
}


# Test if a directory is empty
# Usage: lb_is_dir_empty PATH
lb_is_dir_empty() {

	# test if directory exists
	[ -d "$*" ] || return 1

	# test if directory is empty
	local content
	# ls error means an access rights error
	content=$(ls -A "$*" 2> /dev/null) || return 2

	# directory is not empty
	if [ "$content" ] ; then
		return 3
	fi
}


# Get absolute path of a file/directory
# Usage: lb_abspath PATH
lb_abspath() {

	# usage error
	[ $# == 0 ] && return 1

	# get directory and file names
	local path directory=$(dirname "$*") file=$(basename "$*")

	# root directory is always ok
	if [ "$directory" == "/" ] ; then
		path="/"
	else
		# get absolute path of the parent directory
		# if path does not exists, error
		path=$(cd "$directory" &> /dev/null && pwd) || return 2
	fi

	# case of root path (basename=/)
	if [ "$file" == "/" ] ; then
		echo /
	else
		# return absolute path

		# case of the current directory (do not put /path/to/./)
		if [ "$file" != "." ] ; then

			# do not put //file if parent directory is root
			if [ "$directory" != "/" ] ; then
				path+="/"
			fi

			path+=$file
		fi

		echo "$path"
	fi
}


# Get real path of a file/directory
# Usage: lb_realpath PATH
lb_realpath() {

	# test if path exists
	[ -e "$1" ] || return 1

	if [ "$lb_current_os" == macOS ] ; then
		# macOS does not support readlink -f option
		perl -e 'use Cwd "abs_path";print abs_path(shift)' "$1" || return 2
	else
		# Linux & Windows
		local path

		if [ "$lb_current_os" == Windows ] ; then
			# convert windows paths (C:\dir\file -> /cygdrive/c/dir/file)
			# then we will find real path
			path=$(cygpath "$1")
		else
			path=$1
		fi

		# find real path
		readlink -f "$path" 2> /dev/null || return 2
	fi
}


# Test if a path is writable
# Usage: lb_is_writable PATH
lb_is_writable() {

	# usage error
	[ -z "$1" ] && return 1

	# if file/folder exists
	if [ -e "$*" ] ; then
		# cancel if not writable
		[ -w "$*" ] || return 2
	else
		# if file/folder does not exists

		# cancel if parent directory does not exists
		[ -d "$(dirname "$*")" ] || return 4

		# cancel if parent directory is not writable
		[ -w "$(dirname "$*")" ] || return 3
	fi
}


# Edit a file with sed command
# Usage: lb_edit PATTERN FILE
lb_edit() {
	if $lb_oldsed ; then
		sed -i '' "$@"
	else
		sed -i "$@"
	fi
}


######################
#  SYSTEM UTILITIES  #
######################

# Detect current OS family
# Usage: lb_current_os
lb_current_os() {
	case $(uname 2> /dev/null) in
		Darwin)
			echo macOS
			;;
		CYGWIN*)
			echo Windows
			;;
		*)
			echo Linux
			;;
	esac
}


# Test if a user exists
# Usage: lb_user_exists USER [USER...]
lb_user_exists() {

	# usage error
	[ $# == 0 ] && return 1

	local user
	for user in "$@" ; do
		[ -z "$user" ] && return 1
		# check groups of the user
		if ! groups $user &> /dev/null ; then
			return 1
		fi
	done
}


# Test if an user is in a group
# Usage: lb_in_group GROUP [USER]
lb_in_group() {

	# usage error
	[ -z "$1" ] && return 1

	# get current user if not defined
	local user=$2

	# get current user
	if [ -z "$user" ] ; then
		user=$(whoami)
	fi

	# get groups of the user: 2nd part of the groups result (user : group1 group2 ...)
	local groups=($(groups $user 2> /dev/null | cut -d: -f2))

	# no groups found
	[ ${#groups[@]} == 0 ] && return 3

	# find if user is in group
	lb_in_array "$1" "${groups[@]}"
}


# Get users members of a group
# Usage: lb_group_members GROUP
lb_group_members() {

	# usage error
	[ -z "$1" ] && return 1

	# not compatible with macOS and Windows
	[ "$lb_current_os" != Linux ] && return 3

	# get line of group file
	local groups=$(grep -E "^$1:.*:" /etc/group 2> /dev/null)

	# groups not found
	[ -z "$groups" ] && return 2

	echo "$groups" | sed "s/^$1:.*://; s/,/ /g"
}


# Generate a random password
# Usage: lb_generate_password [SIZE]
lb_generate_password() {

	# default options
	local password size=16

	# get size option
	if [ -n "$1" ] ; then
		# check if is integer
		lb_is_integer $1 || return 1

		# size must be between 1 and 32
		if [ $size -ge 1 ] && [ $size -le 32 ] ; then
			size=$1
		else
			return 1
		fi
	fi

	# generate password
	if lb_command_exists openssl ; then
		# with openssl random command
		password=$(openssl rand -base64 32 2> /dev/null)
	else
		# print date timestamp + nanoseconds then generate md5 checksum
		# then encode in base64
		if [ "$lb_current_os" == macOS ] ; then
			password=$(date +%s%N | shasum -a 256 | base64) || return 2
		else
			password=$(date +%s%N | sha256sum | base64) || return 2
		fi
	fi

	# return password at the right size
	echo "${password:0:$size}"
}


# Send an email
# Usage: lb_email [OPTIONS] RECIPIENT[,RECIPIENT,...] MESSAGE
lb_email() {

	# usage error
	[ $# -lt 2 ] && return 1

	# default options and local variables
	local subject sender replyto cc bcc message message_html
	local multipart=false separator="_----------=_MailPart_118845H_15_62347"
	local attachments=()

	# email commands
	local cmd email_commands=(/usr/sbin/sendmail)

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-s|--subject)
				[ -z "$2" ] && return 1
				subject=$2
				shift
				;;
			-r|--reply-to)
				[ -z "$2" ] && return 1
				replyto=$2
				shift
				;;
			-c|--cc)
				[ -z "$2" ] && return 1
				cc=$2
				shift
				;;
			-b|--bcc)
				[ -z "$2" ] && return 1
				bcc=$2
				shift
				;;
			-a|--attachment)
				[ -f "$2" ] || return 1
				attachments+=("$2")
				shift
				;;
			--sender)
				[ -z "$2" ] && return 1
				sender=$2
				shift
				;;
			--html)
				[ -z "$2" ] && return 1
				message_html=$2
				multipart=true
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if missing text and at least one option
	[ $# -lt 2 ] && return 1

	local recipients=$1
	shift

	# usage error if missing message
	# could be not detected by test above if recipents field has some spaces
	[ -z "$*" ] && return 1

	# search compatible command to send email
	local c
	for c in ${email_commands[@]} ; do
		if lb_command_exists "$c" ; then
			cmd=$c
			break
		fi
	done

	# if no command to send email, error
	[ -z "$cmd" ] && return 2

	# set email header

	if [ -n "$sender" ] ; then
		message+="From: $sender
"
	fi

	message+="To: $recipients
"

	if [ -n "$cc" ] ; then
		message+="Cc: $cc
"
	fi

	if [ -n "$bcc" ] ; then
		message+="Bcc: $bcc
"
	fi

	if [ -n "$replyto" ] ; then
		message+="Reply-To: $replyto
"
	fi

	if [ -n "$subject" ] ; then
		message+="Subject: $subject
"
	fi

	message+="MIME-Version: 1.0
"

	# mixed definition (if attachments)
	if [ ${#attachments[@]} -gt 0 ] ; then
		message+="Content-Type: multipart/mixed; boundary=\"${separator}_mixed\"

--${separator}_mixed
"
	fi

	# multipart definition (if HTML + TXT)
	if $multipart ; then
		message+="Content-Type: multipart/alternative; boundary=\"$separator\"

--$separator
"
	fi

	# mail in TXT
	message+="Content-Type: text/plain; charset=\"utf-8\"

$*
"

	# mail in HTML + close multipart
	if $multipart ; then
		message+="
--$separator
Content-Type: text/html; charset=\"utf-8\"

$message_html
--$separator--"
	fi

	# add attachments
	if [ ${#attachments[@]} -gt 0 ] ; then
		local i attachment filename filetype

		for ((i=0; i < ${#attachments[@]}; i++)) ; do
			attachment=${attachments[i]}
			filename=$(basename "$attachment")
			filetype=$(file --mime-type "$attachment" 2> /dev/null | sed 's/.*: //')

			message+="
--${separator}_mixed
Content-Type: $filetype
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=\"$filename\"

$(base64 "$attachment")
"
		done

		# close mixed section
		message+="--${separator}_mixed--"
fi

	# send email
	case $cmd in
		/usr/sbin/sendmail)
			if ! echo "$message" | /usr/sbin/sendmail -t ; then
				return 3
			fi
			;;
		*)
			# no program found to send email
			return 2
			;;
	esac
}


######################
#  USER INTERACTION  #
######################

# Ask a question to user to answer by yes or no
# Usage: lb_yesno [OPTIONS] TEXT
lb_yesno() {

	# default options
	local yes_default=false cancel_mode=false
	local yes_label=$lb_default_yes_shortlabel no_label=$lb_default_no_shortlabel cancel_label=$lb_default_cancel_shortlabel

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-y|--yes)
				yes_default=true
				;;
			-c|--cancel)
				cancel_mode=true
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
			--cancel-label)
				[ -z "$2" ] && return 1
				cancel_label=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# question is missing
	[ -z "$1" ] && return 1

	# print question (if not quiet mode)
	if [ "$lb_quietmode" != true ] ; then
		# defines question
		local question="("
		if $yes_default ; then
			question+="$(echo "$yes_label" | tr '[:lower:]' '[:upper:]')/$(echo "$no_label" | tr '[:upper:]' '[:lower:]')"
		else
			question+="$(echo "$yes_label" | tr '[:upper:]' '[:lower:]')/$(echo "$no_label" | tr '[:lower:]' '[:upper:]')"
		fi

		# add cancel choice
		if $cancel_mode ; then
			question+="/$(echo "$cancel_label" | tr '[:upper:]' '[:lower:]')"
		fi

		# ends question
		question+=")"

		# print question
		echo -e -n "$* $question: "
	fi

	# read user input
	local choice
	read choice

	# defaut behaviour if input is empty
	if [ -z "$choice" ] ; then
		if $yes_default ; then
			return 0
		else
			return 2
		fi
	fi

	# compare to confirmation string
	if [ "$(echo "$choice" | tr '[:upper:]' '[:lower:]')" != "$(echo "$yes_label" | tr '[:upper:]' '[:lower:]')" ] ; then

		# cancel case
		if $cancel_mode ; then
			if [ "$(echo "$choice" | tr '[:upper:]' '[:lower:]')" == "$(echo "$cancel_label" | tr '[:upper:]' '[:lower:]')" ] ; then
				return 3
			fi
		fi

		# answer is no
		return 2
	fi
}


# Prompt user to choose an option
# Usage: lb_choose_option [OPTIONS] CHOICE [CHOICE...]
lb_choose_option=()
lb_choose_option() {

	# reset result
	lb_choose_option=()

	# default options
	local default=() multiple_choices=false
	local label=$lb_default_chopt_label cancel_label=$lb_default_cancel_shortlabel

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
			-l|--label)
				[ -z "$2" ] && return 1
				label=$2
				shift
				;;
			-m|--multiple)
				multiple_choices=true
				;;
			-c|--cancel-label)
				[ -z "$2" ] && return 1
				cancel_label=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# missing at least 1 choice option
	[ -z "$1" ] && return 1

	# options: initialize with an empty first value (option ID starts to 1, not 0)
	local options=("")

	# prepare choice options
	options+=("$@")

	# verify if default options are valid
	if [ ${#default[@]} -gt 0 ] ; then
		local d
		for d in ${default[@]} ; do
			if ! lb_is_integer $d ; then
				return 1
			fi
			if [ $d -lt 1 ] || [ $d -ge ${#options[@]} ] ; then
				return 1
			fi
		done
	fi

	# print question (if not quiet mode)
	if [ "$lb_quietmode" != true ] ; then
		# print question
		echo -e "$label"

		# print options
		local i
		for ((i=1; i < ${#options[@]}; i++)) ; do
			echo "  $i. ${options[i]}"
		done

		echo

		# print default option
		if [ ${#default[@]} -gt 0 ] ; then
			echo -n "[$(lb_join , ${default[@]})]: "
		else
			echo -n "[$cancel_label]: "
		fi
	fi

	# read user input
	local choices
	read choices

	# defaut behaviour if input is empty
	if [ -z "$choices" ] ; then
		if [ ${#default[@]} -gt 0 ] ; then
			# default option
			lb_choose_option=(${default[@]})
		else
			# cancel code
			return 2
		fi
	fi

	# if user made a choice

	# convert choices to an array
	if $multiple_choices ; then
		lb_split , $choices
		choices=(${lb_split[@]})
	fi

	# parsing choices
	local c
	for c in ${choices[@]} ; do
		# check cancel option
		if [ "$c" == "$cancel_label" ] ; then
			lb_choose_option=()
			return 2
		fi

		# strict check type
		if ! lb_is_integer "$c" ; then
			lb_choose_option=()
			return 3
		fi

		# check if user choice is valid
		if [ $c -lt 1 ] || [ $c -ge ${#options[@]} ] ; then
			lb_choose_option=()
			return 3
		fi

		# save choice if not already done
		if ! lb_in_array "$c" "${lb_choose_option[@]}" ; then
			lb_choose_option+=("$c")
		fi
	done
}


# Ask user to enter a text
# Usage: lb_input_text [OPTIONS] TEXT
lb_input_text=""
lb_input_text() {

	# reset result
	lb_input_text=""

	# default options
	local default opts

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-d|--default)
				[ -z "$2" ] && return 1
				default=$2
				shift
				;;
			-n)
				opts="-n "
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# text is not defined
	[ -z "$1" ] && return 1

	# print question (if not quiet mode)
	if [ "$lb_quietmode" != true ] ; then
		echo -n -e "$*"
		[ -n "$default" ] && echo -n -e " [$default]"
	fi

	# add separator
	echo $opts " "

	# read user input without ignoring backslashes
	read -r lb_input_text

	# if empty
	if [ -z "$lb_input_text" ] ; then
		# default value if set
		if [ -n "$default" ] ; then
			lb_input_text=$default
		else
			return 2
		fi
	fi
}


# Ask user to enter a password
# Usage: lb_input_password [OPTIONS] [TEXT]
lb_input_password=""
lb_input_password() {

	# reset result
	lb_input_password=""

	# default options
	local label=$lb_default_pwd_label confirm_label=$lb_default_pwd_confirm_label
	local confirm=false min_size=0

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
				lb_is_integer $2 || return 1
				[ $2 -lt 1 ] && return 1
				min_size=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# text label
	if [ $# -gt 0 ] ; then
		label=$*
	fi

	# print question (if not quiet mode)
	[ "$lb_quietmode" != true ] && echo -n -e "$label "

	# prompt user for password
	read -s -r lb_input_password
	# line return
	echo

	# if empty, exit with error
	[ -z "$lb_input_password" ] && return 2

	# check password size (if --min-size option is set)
	if [ $min_size -gt 0 ] ; then
		if [ $(echo -n "$lb_input_password" | wc -m) -lt $min_size ] ; then
			lb_input_password=""
			return 4
		fi
	fi

	# if no confirmation, return OK
	$confirm || return 0

	# if confirmation, save current password
	local password_confirm=$lb_input_password

	# print confirmation question (if not quiet mode)
	[ "$lb_quietmode" != true ] && echo -n -e "$confirm_label "

	# prompt password confirmation
	read -s -r password_confirm
	# line return
	echo

	# if passwords mismatch, return error
	if [ "$lb_input_password" != "$password_confirm" ] ; then
		lb_input_password=""
		return 3
	fi
}


###############################
#  ALIASES AND COMPATIBILITY  #
###############################

# Print a message
# See lb_print for usage
lb_echo() {
	lb_print "$@"
}


# Print a message to stderr
# See lb_print for usage
lb_error() {
	>&2 lb_print "$@"
}


# Get log level
# See lb_get_log_level for usage
lb_get_loglevel() {
	lb_get_log_level "$@"
}


# Set log level
# See lb_set_log_level for usage
lb_set_loglevel() {
	lb_set_log_level "$@"
}


# Common display levels functions
# See lb_display for usage
lb_display_critical() {
	lb_display -p -l "$lb_default_critical_label" "$@"
}

lb_display_error() {
	lb_display -p -l "$lb_default_error_label" "$@"
}

lb_display_warning() {
	lb_display -p -l "$lb_default_warning_label" "$@"
}

lb_warning() {
	lb_display_warning "$@"
}

lb_display_info() {
	lb_display -p -l "$lb_default_info_label" "$@"
}

lb_info() {
	lb_display_info "$@"
}

lb_display_debug() {
	lb_display -p -l "$lb_default_debug_label" "$@"
}

lb_debug() {
	lb_display_debug "$@"
}

# Common log functions
# Usage: lb_log_* [OPTIONS] TEXT
# See lb_log for options usage
lb_log_critical() {
	lb_log -p -l "$lb_default_critical_label" "$@"
}

lb_log_error() {
	lb_log -p -l "$lb_default_error_label" "$@"
}

lb_log_warning() {
	lb_log -p -l "$lb_default_warning_label" "$@"
}

lb_log_info() {
	lb_log -p -l "$lb_default_info_label" "$@"
}

lb_log_debug() {
	lb_log -p -l "$lb_default_debug_label" "$@"
}


# Aliases for old functions compatibility
lb_detect_os() {
	lb_current_os
}
lb_array_contains() {
	lb_in_array "$@"
}
lb_dir_is_empty() {
	lb_is_dir_empty "$@"
}


####################
#  INITIALIZATION  #
####################

lb_load_result=0

# context variables
declare -r lb_current_os=$(lb_current_os)
declare -r lb_current_hostname=$(hostname 2> /dev/null)
declare -r lb_current_user=$(whoami)
declare -r lb_current_path=$(pwd)

# libbash context
declare -r lb_path=$(lb_realpath "$BASH_SOURCE")
declare -r lb_directory=$(dirname "$lb_path")

# current script context
declare -r lb_current_script=$(lb_realpath "$0")
declare -r lb_current_script_directory=$(dirname "$lb_current_script")
lb_current_script_name=$(basename "$lb_current_script")

# verify if variables are set
for v in lb_current_os lb_current_hostname lb_current_user lb_current_path \
         lb_path lb_directory \
         lb_current_script lb_current_script_name lb_current_script_directory ; do
	if [ -z "${!v}" ] ; then
		lb_error "libbash.sh: [WARNING] variable \$$v could not be set"
		lb_load_result=4
	fi
done

# get current user language (e.g. fr, en, ...)
lb_lang=${LANG:0:2}

# get options
while [ $# -gt 0 ] ; do
	case $1 in
		-g|--gui)
			lb_load_gui=0

			# load libbash GUI
			source "$lb_directory/libbash_gui.sh" &> /dev/null || lb_load_gui=$?

			case $lb_load_gui in
				0)
					# GUI loaded; continue
					;;
				2)
					lb_error "libbash.sh GUI: [ERROR] cannot set a GUI interface"
					lb_load_result=5
					;;
				*)
					lb_error "libbash.sh: [ERROR] cannot load GUI part. Please verify the path $lb_directory."
					lb_load_result=2
					;;
			esac
			;;
		-l|--lang)
			# no errors if bad options
			if [ -n "$2" ] ; then
				lb_lang=$2
				shift
			fi
			;;
		-q|--quiet)
			# activate quiet mode
			lb_quietmode=true
			;;
		*)
			break
			;;
	esac
	shift # get next option
done

# load translations (do not exit if errors)
case $lb_lang in
	fr)
		if ! source "$lb_directory/locales/$lb_lang.sh" &> /dev/null ; then
			lb_error "libbash.sh: [WARNING] cannot load translation: $lb_lang"
			lb_load_result=3
		fi
		;;
esac

# if macOS, disable text formatting in console
if [ "$lb_current_os" == macOS ] ; then
	lb_format_print=false
fi

# detect old sed command (mostly on macOS)
if ! sed --version &> /dev/null ; then
	lb_oldsed=true
fi

return $lb_load_result
