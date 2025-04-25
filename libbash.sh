########################################################
#                                                      #
#  libbash.sh                                          #
#  A library of useful functions for bash developers   #
#                                                      #
#  MIT License                                         #
#  Copyright (c) 2017-2022 Jean Prunneaux              #
#  Website: https://github.com/pruje/libbash.sh        #
#                                                      #
#  Version 1.21.0 (2022-06-03)                         #
#                                                      #
########################################################

declare -r lb_version=1.21.0

# Index
#
#   * Internal functions
#       lb__powershell
#   * Bash utilities
#       lb_command_exists
#       lb_function_exists
#       lb_cmd_to_array
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
#       lb_migrate_config
#       lb_get_config
#       lb_set_config
#   * Operations on variables
#       lb_istrue
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
#       lb_current_uid
#       lb_user_exists
#       lb_ami_root
#       lb_in_group
#       lb_group_exists
#       lb_group_members
#       lb_generate_password
#       lb_email
#   * User interacion
#       lb_yesno
#       lb_choose_option
#       lb_input_text
#       lb_input_password
#       lb_say
#   * Aliases and compatibility
#       lb_critical
#       lb_echo
#       lb_err
#       lb_error
#       lb_get_loglevel
#       lb_set_loglevel
#       lb_display_critical
#       lb_display_error
#       lb_display_warning
#       lb_warn
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
#       lb_test_arguments
#   * Variables
#   * Initialization


##################################
#  INTERNAL FUNCTIONS            #
#  DO NOT PUBLISH DOCUMENTATION  #
##################################

# Run powershell command
# Usage: lb__powershell COMMAND
lb__powershell() {
	powershell -ExecutionPolicy ByPass -File "$(cygpath -w "$lb_directory"/inc/libbash.ps1)" "$@"
}


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
		[ "$type" = function ] || return 3
	done
}


# Get result of a command and put it in array
# Usage: lb_cmd_to_array CMD [ARGS]
lb_cmd_to_array=()
lb_cmd_to_array() {
	# reset variable
	lb_cmd_to_array=()

	[ -n "$1" ] || return 1

	# save current field separator and set a new with line return
	local old_IFS=$IFS IFS=$'\n'

	lb_cmd_to_array=($("$@"))
	local res=$?

	# restore field separator
	IFS=$old_IFS

	return $res
}


# Get command arguments and split options in array
# Usage: lb_getargs "$@"
lb_getargs=()
lb_getargs() {
	# reset variable
	lb_getargs=()

	# no arguments
	[ $# -gt 0 ] || return 1

	# parse arguments
	local a
	for a in "$@" ; do
		# if multiple options combined, split them
		if [[ $a =~ ^-[a-zA-Z0-9]+$ ]] ; then
			lb_getargs+=($(echo "${a:1}" | grep -o . | sed 's/^/-/'))
		else
			# if syntax --option=value, split to --option value
			if [[ $a =~ ^--.*=.* ]] ; then
				lb_getargs+=("$(echo "$a" | cut -d= -f1)" "$(echo "$a" | cut -d= -f2-)")
			else
				# forward argument
				lb_getargs+=("$a")
			fi
		fi
	done
}


# Get value of an option (e.g. --tail 10 will return 10)
# Usage: lb_getopt "$@"
lb_getopt() {
	# if syntax --option=value
	if [[ $1 =~ ^--.*=.* ]] ; then
		echo "$1" | cut -d= -f2-
		return 0
	fi

	# if no value, quit
	[ $# -ge 2 ] || return 1

	# if next option, quit
	[ "${2:0:1}" != - ] || return 1

	# return option value
	echo "$2"
}


# Exit script with defined exit code
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
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
		if [[ $1 =~ ^-?[0-9]+$ ]] ; then
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
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_get_display_level [OPTIONS] [LEVEL_NAME]
lb_get_display_level() {
	# default options
	local i get_id=false level=$lb__display_level

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
		if [ -z "$lb__display_level" ] ; then
			return 1
		else
			# print actual and exit
			if $get_id ; then
				echo $lb__display_level
			else
				echo "${lb_log_levels[lb__display_level]}"
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
		if [ "${lb_log_levels[i]}" = "$level" ] ; then
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
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_set_display_level LEVEL_NAME
lb_set_display_level() {
	# usage error: must be non empty
	[ -n "$1" ] || return 1

	# search if level exists
	local id
	for ((id=0 ; id < ${#lb_log_levels[@]} ; id++)) ; do
		# search by name and set level id
		if [ "${lb_log_levels[id]}" = $1 ] ; then
			lb__display_level=$id
			return 0
		fi
	done

	# if specified level not found, error
	return 2
}


# Print a message to the console, with colors and formatting
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_print [OPTIONS] TEXT
lb_print() {
	# quiet mode: do not print anything
	[ "$lb_quietmode" != true ] || return 0

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
	if [ "$lb__format_print" = true ] && [ ${#format[@]} -gt 0 ] ; then
		opts+="\e["
		local f
		for f in ${format[@]} ; do
			opts+=";$f"
		done
		opts+="m"

		reset_color="\e[0m"
	fi

	local text=$*

	# if text passed by argument
	if [ ${#text} -gt 0 ] ; then
		echo -e $opts"$text$reset_color"
	else
		# print empty text
		if [ -t 0 ] ; then
			echo
		else
			# print text from stdin
			while read -r text ; do
				echo -e $opts"$text$reset_color"
			done
		fi
	fi
}


# Print a message to the console, can set a verbose level and can append to logs
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_display [OPTIONS] TEXT
lb_display() {
	# default options
	local opts=() display_level display_prefix=false log_message=false say=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-e|-n)
				opts+=($1)
				;;
			-l|--level)
				[ -n "$2" ] || return 1
				display_level=$2
				shift
				;;
			-p|--prefix)
				display_prefix=true
				;;
			--log)
				log_message=true
				;;
			--say)
				say=true
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# other options
	local text=$* prefix display=true result=0

	# get text from stdin
	if [ ${#text} = 0 ] && ! [ -t 0 ] ; then
		local t
		while read -r t ; do
			text+="
$t"
		done
		# delete first line jump
		text=${text:1}
	fi

	# set level prefix
	$display_prefix && [ -n "$display_level" ] && prefix="[$display_level]  "

	# print into logfile
	if $log_message ; then
		# prepare command to log
		local log_opts=("${opts[@]}")
		[ -n "$display_level" ] && log_opts+=(--level "$display_level")

		# write log
		lb_log "${log_opts[@]}" "$prefix$text" || result=2
	fi

	# quiet mode: do not print anything
	if [ "$lb_quietmode" = true ] ; then
		display=false
	else
		# if a display level is set, test current level
		if [ -n "$display_level" ] && [ -n "$lb__display_level" ] ; then
			# get display level ID
			local level_id

			# Note: if level is unknown, message will be displayed
			if level_id=$(lb_get_display_level --id "$display_level") ; then
				# if display level is higher than default, will not display (but can log)
				[ $level_id -le $lb__display_level ] || display=false
			fi
		fi
	fi

	if $display ; then
		# enable coloured prefixes
		if $display_prefix ; then
			case $display_level in
				$lb__critical_label)
					prefix="[$(lb_print --red "$display_level")]  "
					;;
				$lb__error_label)
					prefix="[$(lb_print --red "$display_level")]  "
					;;
				$lb__warning_label)
					prefix="[$(lb_print --yellow "$display_level")]  "
					;;
				$lb__info_label)
					prefix="[$(lb_print --green "$display_level")]  "
					;;
				$lb__debug_label)
					prefix="[$(lb_print --cyan "$display_level")]  "
					;;
			esac
		fi

		# print text
		lb_print "${opts[@]}" "$prefix$text" || return 3
	fi

	$say && (lb_say "$text" &)

	return $result
}


# Manage command result and display label
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_result [OPTIONS] [EXIT_CODE]
lb_result() {
	# get last command result
	local result=$?

	# default values and options
	local ok_label=$lb__result_ok_label failed_label=$lb__result_failed_label
	local display_cmd=(lb_display) log_cmd=(lb_log) log=false say_cmd=(lb_say) say=false smart_levels=false
	local error_exitcode save_exitcode=false exit_on_error=false quiet_mode=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			--ok-label)
				[ -n "$2" ] || return 1
				ok_label=$2
				shift
				;;
			--failed-label)
				[ -n "$2" ] || return 1
				failed_label=$2
				shift
				;;
			-d|--display-level)
				[ -n "$2" ] || return 1
				display_cmd+=(-l "$2")
				shift
				;;
			--log)
				log=true
				;;
			-l|--log-level)
				[ -n "$2" ] || return 1
				log_cmd+=(-l "$2")
				shift
				;;
			--smart-levels)
				smart_levels=true
				;;
			--say)
				say=true
				;;
			-s|--save-exitcode)
				save_exitcode=true
				;;
			-e|--error-exitcode)
				# check type and validity
				[[ $2 =~ ^-?[0-9]+$ ]] || return 1
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
		[[ $1 =~ ^-?[0-9]+$ ]] || return 1
		result=$1
	fi

	# save result to exit code
	$save_exitcode && lb_exitcode=$result

	# log & display result
	if [ $result = 0 ] ; then
		if $log ; then
			$smart_levels && log_cmd+=(-l INFO)
			log_cmd+=("$ok_label")
		fi

		$say && say_cmd+=("$ok_label")

		if ! $quiet_mode ; then
			$smart_levels && display_cmd+=(-l INFO)
			display_cmd+=("$ok_label")
		fi
	else
		if $log ; then
			$smart_levels && log_cmd+=(-l ERROR)
			log_cmd+=("$failed_label")
		fi

		$say && say_cmd+=("$failed_label")

		if ! $quiet_mode ; then
			$smart_levels && display_cmd+=(-l ERROR)
			display_cmd+=("$failed_label")
		fi
	fi

	# log & display result
	$log && "${log_cmd[@]}"
	$quiet_mode || "${display_cmd[@]}"
	$say && ("${say_cmd[@]}" &)

	if [ $result != 0 ] ; then
		# if save exit code is not set and error exitcode is specified, save it
		if ! $save_exitcode && [ -n "$error_exitcode" ] ; then
			lb_exitcode=$error_exitcode
		fi

		# if exit on error, exit
		$exit_on_error && lb_exit
	fi

	return $result
}


# Manage command result and display label in short mode
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_short_result [OPTIONS] [EXIT_CODE]
lb_short_result() {
	# get last command result
	local result=$?

	lb_result --ok-label "[ $(echo "$lb__ok_label" | tr '[:lower:]' '[:upper:]') ]" \
	          --failed-label "[ $(echo "$lb__failed_label" | tr '[:lower:]' '[:upper:]') ]" "$@" $result
}


##########
#  LOGS  #
##########

# Return path of the defined log file
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_get_logfile
lb_get_logfile() {
	# if no log file defined, error
	[ -n "$lb_logfile" ] || return 1

	# test if log file is writable
	if ! lb_is_writable "$lb_logfile" ; then
		# do not return error if samba share: cannot determine rights in some cases
		[ "$(lb_df_fstype "$(dirname "$lb_logfile")")" = smbfs ] || return 2
	fi

	# return log file path
	echo "$lb_logfile"
}


# Set path of the log file
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_set_logfile [OPTIONS] PATH
lb_set_logfile() {
	# default options
	local overwrite=false append=false win_format=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-a|--append)
				append=true
				;;
			-x|--overwrite)
				overwrite=true
				;;
			-w|--win-format)
				win_format=true
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
		[ "$(lb_df_fstype "$(dirname "$*")")" = smbfs ] || return 2
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
	else
		# if file does not exists, create it
		touch "$*" || return 2
	fi

	# set log file path
	lb_logfile=$*
	lb__log_winformat=$win_format

	# if not set, set higher log level
	if [ -z "$lb__log_level" ] && [ ${#lb_log_levels[@]} -gt 0 ] ; then
		lb__log_level=$((${#lb_log_levels[@]} - 1))
	fi
}


# Get current log level
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_get_log_level [OPTIONS] [LEVEL_NAME]
lb_get_log_level() {
	# default options
	local i get_id=false level=$lb__log_level

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
		if [ -z "$lb__log_level" ] ; then
			return 1
		else
			# print actual and exit
			if $get_id ; then
				echo $lb__log_level
			else
				echo "${lb_log_levels[lb__log_level]}"
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
		if [ "${lb_log_levels[i]}" = "$level" ] ; then
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
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_set_log_level LEVEL_NAME
lb_set_log_level() {
	# usage error
	[ -n "$1" ] || return 1

	# search if level exists
	local id
	for ((id=0 ; id < ${#lb_log_levels[@]} ; id++)) ; do
		# search by name and set level id
		if [ "${lb_log_levels[id]}" = $1 ] ; then
			lb__log_level=$id
			return 0
		fi
	done

	# if specified level not found, error
	return 2
}


# Print text into log file
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_log [OPTIONS] TEXT
lb_log() {
	# exit if log file is not set
	[ -n "$lb_logfile" ] || return 1

	# default options
	local echo_opts=(-e) level
	local prefix=false date_prefix=false overwrite=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-n)
				echo_opts+=(-n)
				;;
			-l|--level)
				[ -n "$2" ] || return 1
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

	local text=$*

	# get text from stdin
	if [ ${#text} = 0 ] && ! [ -t 0 ] ; then
		local t
		while read -r t ; do
			text+="
$t"
		done
		# delete first line jump
		text=${text:1}
	fi

	# windows format
	[ "$lb__log_winformat" = true ] && text+="\r"

	# if a default log level is set, test it
	if [ -n "$level" ] && [ -n "$lb__log_level" ] ; then
		local id_level

		# Note: if level unknown, message will be logged
		if id_level=$(lb_get_log_level --id "$level") ; then
			# if log level is higher than default, do not log
			[ $id_level -le $lb__log_level ] || return 0
		fi
	fi

	# initialize log text + tee options
	local log_prefix tee_opts=()

	# add date prefix
	$date_prefix && log_prefix+="$(date +"%d %b %Y %H:%M:%S %z") "

	# add level prefix
	if $prefix && [ -n "$level" ] ; then
		log_prefix+="[$level] "
	fi

	# if not erase, append to file with tee -a
	$overwrite || tee_opts+=(-a)

	# print into log file; do not output text or errors
	echo "${echo_opts[@]}" "$log_prefix$text" | tee "${tee_opts[@]}" "$lb_logfile" &> /dev/null || return 2
}


########################
#  CONFIGURATION FILES #
########################

# Read a config file
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_read_config [OPTIONS] PATH
lb_read_config=()
lb_read_config() {
	# reset variable
	lb_read_config=()

	# default options
	local sections=() analyse=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-s|--section)
				[ -n "$2" ] || return 1
				sections+=("[$2]")
				shift
				;;
			-a|--analyse)
				analyse=true
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# test if file exists
	[ -f "$1" ] || return 1

	# test if file is readable
	[ -r "$1" ] || return 2

	local line s section good_section=false section_found=false filters=(-v '^[[:space:]]*(#|;|$)') result

	# analyse mode: do not filter comments
	$analyse && filters=('^(\[|(#|;)*[a-zA-Z0-9_]+[[:space:]]*=)')

	# read config file line by line; backslashes are not escaped
	while read -r line ; do

		# section detection
		if [ ${#sections[@]} -gt 0 ] || $analyse ; then

			# test if line is a section
			s=$(echo "$line" | grep -Eo '^\[.*\]')

			# filter by sections
			if [ ${#sections[@]} -gt 0 ] ; then
				# if line is a section definition
				if [ -n "$s" ] ; then
					# if section is valid, mark it
					if lb_in_array "$s" "${sections[@]}" ; then
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
					$good_section || continue
				fi
			fi
		fi

		# analyse mode: add parameter to results
		if $analyse ; then

			# section line: save and dont return it
			if [ -n "$s" ] ; then
				section=$(echo "$s" | sed 's/\[\(.*\)\]/\1/')
				continue
			fi

			result=$(echo "$line" | sed 's/^\#*\;*\([a-zA-Z0-9_]*\)[[:space:]]*=.*/\1/')
			[ -z "$section" ] || result=$section.$result

			lb_read_config+=("$result")
		else
			# add line to results
			lb_read_config+=("$line")
		fi

	# read line by line except empty or commented lines (+ delete spaces at the end of lines)
	done < <(grep -E "${filters[@]}" "$1" | sed 's/[[:space:]]*$//')

	# if section was not found, error
	if [ ${#sections[@]} -gt 0 ] && ! $section_found ; then
		return 3
	fi
}


# Import a config file into bash variables
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_import_config [OPTIONS] PATH [PARAMETERS]
lb_import_config() {
	# local variables and default options
	local sections=() template return_errors=false secure_mode=true

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-s|--section)
				[ -n "$2" ] || return 1
				sections+=("[$2]")
				shift
				;;
			-t|--template-file)
				[ -f "$2" ] || return 1
				template=$2
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
	[ -f "$1" ] || return 1

	# test if file is readable
	[ -r "$1" ] || return 5

	local file=$1
	shift

	local filters=("$@") result=0 line s section param param_filter value good_section=false section_found=false

	# read config template
	if [ -n "$template" ] ; then
		lb_read_config -a "$template" || return 6
		filters=("${lb_read_config[@]}")
	fi

	# read file line by line; backslashes are not escaped
	while read -r line ; do

		# test if line is a section
		s=$(echo "$line" | grep -Eo '^\[.*\]')

		# save current section
		[ -z "$s" ] || section=$(echo "$s" | sed 's/\[\(.*\)\]/\1/')

		# filter by sections
		if [ ${#sections[@]} -gt 0 ] ; then
			# if line is a section definition
			if [ -n "$s" ] ; then
				# if section is valid, mark it
				if lb_in_array "$s" "${sections[@]}" ; then
					good_section=true
					section_found=true
				else
					good_section=false
				fi
			else
				# if normal line,
				# if we are not in a good section, continue to the next line
				$good_section || continue
			fi
		fi

		# check syntax of the line (param = value)
		if ! echo "$line" | grep -Eq '^[[:space:]]*[a-zA-Z0-9_]+[[:space:]]*=.*' ; then
			# if section definition, do nothing (not error)
			if ! echo "$line" | grep -Eq '^\[.*\][[:space:]]*$' ; then
				$return_errors && result=3
			fi
			continue
		fi

		# save parameter name
		param=$(echo "$line" | cut -d= -f1 | tr -d '[:space:]')

		# filter parameter
		if [ ${#filters[@]} -gt 0 ] ; then
			param_filter=$param
			[ -z "$section" ] || param_filter=$section.$param

			# not in filter list: continue
			lb_in_array "$param_filter" "${filters[@]}" || continue
		fi

		# get parameter and value
		# Note: use [[:space:]] for macOS compatibility
		value=$(echo "$line" | sed 's/^[[:space:]]*[a-zA-Z0-9_]*[[:space:]]*=[[:space:]]*//')

		# secure config values with prevent bash injection
		if $secure_mode && echo "$value" | grep -Eq '\$|`|<|>' ; then
			$return_errors && result=4
			continue
		fi

		# run command to attribute value to variable
		eval "$param=$value" &> /dev/null || result=2

	# read line by line except empty or commented lines (+ delete spaces at the end of lines)
	done < <(grep -Ev '^[[:space:]]*(#|;|$)' "$file" | sed 's/[[:space:]]*$//')

	# if section was not found, return error
	if [ ${#sections[@]} -gt 0 ] && ! $section_found ; then
		return 2
	fi

	return $result
}


# Migrate config file to another version
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_migrate_config OLD_FILE NEW_FILE
lb_migrate_config() {
	# test if files exists
	if [ -f "$1" ] && [ -f "$2" ] ; then
		true
	else
		return 1
	fi

	# test if files are readable & writable
	if [ -r "$1" ] && [ -r "$2" ] && [ -w "$2" ] ; then
		true
	else
		return 3
	fi

	# analyse new config
	lb_read_config -a "$2" || return 4

	# import old config
	local param section opts=() value result=0
	for param in "${lb_read_config[@]}" ; do
		# reset
		opts=()

		# detect section definition
		if echo "$param" | grep -Eq '^.+\..+' ; then
			section=$(echo "$param" | cut -d. -f1)
			param=$(echo "$param" | cut -d. -f2)
			opts+=(-s "$section")
		fi

		# get old value if exists
		if value=$(lb_get_config "${opts[@]}" "$1" "$param") ; then
			# write value in new config
			lb_set_config "${opts[@]}" "$2" "$param" "$value" || result=2
		fi
	done

	return $result
}


# Get config value
# Usage: lb_get_config [OPTIONS] FILE PARAM
lb_get_config() {
	# default options
	local section text

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-s|--section)
				[ -n "$2" ] || return 1
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
	[ $# -ge 2 ] || return 1

	if [ "$1" = "-" ] ; then
		# get config from stdin
		if ! [ -t 0 ] ; then
			local t
			while read -r t ; do
				text+="
$t"
			done
			# delete first line jump
			text=${text:1}
		fi
	else
		# test is file exists
		[ -f "$1" ] || return 1

		# test if file is readable
		[ -r "$1" ] || return 2

		# get file content
		text=$(cat "$1")
	fi

	# test parameter name
	[[ $2 =~ ^[a-zA-Z0-9_]+$ ]] || return 1

	# search config line
	local config_lines=($(echo "$text" | grep -En "^[[:space:]]*$2[[:space:]]*=" | cut -d: -f1))

	# if line not found, return error
	[ ${#config_lines[@]} -gt 0 ] || return 3

	# sed regex:
	#   1. extract value
	#   2. delete spaces at the end of line
	#   3. delete quotes " and '
	#   4. convert \" to "
	local sed_extract="s/.*$2[[:space:]]*=[[:space:]]*//; s/[[:space:]]*$//; s/^\"\(.*\)\"$/\1/; s/^'\(.*\)'$/\1/; s/\\\\\"/\"/g"

	# if no filter by section, print the last found
	if [ -z "$section" ] ; then
		echo "$text" | sed "${config_lines[${#config_lines[@]}-1]}q;d" | sed "$sed_extract"
		return 0
	fi

	# parse every results (from last to first)
	local i j current_section
	for ((i=${#config_lines[@]}-1; i>=0; i--)) ; do
		# if first line, cannot go up
		[ ${config_lines[i]} = 1 ] && continue

		for ((j=${config_lines[i]}-1; j>=1; j--)) ; do
			current_section=$(echo "$text" | sed "${j}q;d" | grep -Eo '^\[.*\]')

			if [ -n "$current_section" ] ; then
				if [ "$current_section" = "[$section]" ] ; then
					# return value
					echo "$text" | sed "${config_lines[i]}q;d" | sed "$sed_extract"
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
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_set_config [OPTIONS] FILE PARAM VALUE
lb_set_config() {
	# local variables
	local section strict_mode=false no_spaces=false

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-s|--section)
				[ -n "$2" ] || return 1
				section=$2
				shift
				;;
			--strict)
				strict_mode=true
				;;
			--no-spaces)
				no_spaces=true
				;;
			*)
				break
				;;
		esac
		shift # load next option
	done

	# usage error
	[ $# -ge 2 ] || return 1

	# test is file exists
	[ -f "$1" ] || return 1

	# test if file is readable & writable
	if [ -r "$1" ] && [ -w "$1" ] ; then
		true
	else
		return 2
	fi

	# test parameter name
	[[ $2 =~ ^[a-zA-Z0-9_]+$ ]] || return 1

	local config_file=$1 param=$2
	shift 2

	# get value
	local value=$*

	# spaces: add quotes
	if echo "$value" | grep -q '[[:space:]]' ; then
		# if not an array
		if [ "${value:0:1}" != '(' ] && [ "${value:${#value}-1}" != ')' ] ; then
			# add quotes around value + escape quotes if any
			value="\"$(echo "$value" | sed 's/"/\\\\"/g')\""
		fi
	fi

	# Windows files: append \r at the end of line
	[ "$lb_current_os" = Windows ] && value+="\r"

	# prepare line for sed command
	local sed_line=$param

	if $no_spaces ; then
		sed_line+='='
	else
		sed_line+=' = '
	fi

	sed_line+=$(echo "$value" | sed 's/\//\\\//g')

	# search config line
	local config_lines=($(grep -En "^[[:space:]]*(#|;)*[[:space:]]*$param[[:space:]]*=" "$config_file" | cut -d: -f1))

	# if line found, modify line (set the last one if multiple lines)
	if [ ${#config_lines[@]} -gt 0 ] ; then

		# if filter by section, search valid results
		if [ -n "$section" ] ; then

			# save results
			local i j current_section results=(${config_lines[@]})
			# reset results
			config_lines=()

			# parse every results (saved before)
			for i in "${results[@]}" ; do
				# if first line, cannot go up
				[ $i = 1 ] && continue

				for ((j=$i-1; j>=1; j--)) ; do
					current_section=$(sed "${j}q;d" "$config_file" | grep -Eo '^\[.*\]')

					if [ -n "$current_section" ] ; then
						if [ "$current_section" = "[$section]" ] ; then
							config_lines+=($i)
						fi
						break
					fi
				done
			done
		fi

		local config_line

		# recheck results
		if [ ${#config_lines[@]} -gt 0 ] ; then
			# default: last line found
			config_line=${config_lines[${#config_lines[@]}-1]}

			# multiple results: find non commented lines
			if [ ${#config_lines[@]} -gt 1 ] ; then
				# parse results from last to first
				local i
				for ((i=${#config_lines[@]}-1; i>=0; i--)) ; do
					# get the first non commented line
					if ! sed "${config_lines[i]}q;d" "$config_file" | lb_is_comment -s '#' -s ';' ; then
						config_line=${config_lines[i]}
						break
					fi
				done
			fi
		fi

		# if ready to edit
		if [ -n "$config_line" ] ; then
			# modify config file
			# Note: use [[:space:]] for macOS compatibility
			lb_edit "${config_line}s/^#*;*[[:space:]]*$param[[:space:]]*=.*/$sed_line/" "$config_file" || return 4
			return 0
		fi
	fi

	# if line not found (or not in the right section)

	# if strict mode, quit
	$strict_mode && return 3

	# prepare sed insert command
	local sed_insert='$a'

	# if filter by section,
	if [ -n "$section" ] ; then

		# search for the right section
		local section_line=($(grep -En "^\[$section\][[:space:]]*$" "$config_file" | cut -d: -f1))

		# if section exists,
		if [ -n "$section_line" ] ; then
			# if not last line, change sed append command
			[ "$((${section_line[0]}+1))" -le "$(cat "$config_file" | wc -l)" ] && sed_insert=$((${section_line[0]}+1))i
		else
			# if section not found, append it

			# append empty line above new section
			if tail -1 "$config_file" | grep -Evq '^[[:space:]]*$' ; then
				if [ "$lb_current_os" = Windows ] ; then
					echo -e "\r" >> "$config_file" || return 4
				else
					echo >> "$config_file" || return 4
				fi
			fi

			section_line="[$section]"

			# Windows files: add \r at the end of line
			[ "$lb_current_os" = Windows ] && section_line+="\r"

			# append section to file
			echo -e "$section_line" >> "$config_file" || return 4
		fi
	fi

	# the case of an empty file
	if ! [ -s "$config_file" ] ; then
		# insert an empty line
		echo >> "$config_file" || return 4
		# replace the first line
		lb_edit "1s/.*/$sed_line/" "$config_file" || return 4
		return 0
	fi

	# append line to file
	lb_edit "$sed_insert\\
$sed_line
" "$config_file" || return 4
}


############################
#  OPERATIONS ON VARIABLES #
############################

# Test if a boolean is true
# Usage: lb_istrue VALUE
lb_istrue() {
	[ "$*" = true ]
}


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
				[ -n "$2" ] || return 1
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

	local line=$*

	# get text from stdin
	if [ ${#line} = 0 ] ; then
		[ -t 0 ] || read -r line
	fi

	# delete spaces
	line=$(echo "$line" | sed 's/^[[:space:]]*//g')

	# empty line
	if [ -z "$line" ] ; then
		if $empty_is_comment ; then
			return 0
		else
			return 3
		fi
	fi

	# set default comment symbol if none is set
	[ ${#symbols[@]} -gt 0 ] || symbols+=("#")

	# test if text starts with comment symbol
	local s
	for s in "${symbols[@]}" ; do
		[ "${line:0:${#s}}" != "$s" ] || return 0
	done

	# symbol not found: not a comment
	return 2
}


# Deletes spaces before and after a string
# Usage: lb_trim STRING
lb_trim() {
	local string=$*

	# test if text passed by stdin
	if [ ${#string} = 0 ] ; then
		if [ -t 0 ] ; then
			# empty text
			return 0
		else
			# get text from stdin
			while read -r string ; do
				# remove spaces before string
				string=${string#${string%%[![:space:]]*}}
				# remove spaces after string and return it
				echo "${string%${string##*[![:space:]]}}"
			done
		fi
	else
		# remove spaces before string
		string=${string#${string%%[![:space:]]*}}
		# remove spaces after string and return it
		echo "${string%${string##*[![:space:]]}}"
	fi
}


# Split a string into array
# Usage: lb_split DELIMITER STRING
lb_split=()
lb_split() {
	# reset result
	lb_split=()

	# usage error
	[ -n "$1" ] || return 1

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
	[ -n "$1" ] || return 1

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
	[ -n "$1" ] || return 1

	# get search value
	local value search=$1
	shift

	# if array is empty, return not found
	[ $# -gt 0 ] || return 2

	# parse array to find value
	for value in "$@" ; do
		[ "$value" != "$search" ] || return 0
	done

	# not found
	return 2
}


# Convert a date to timestamp
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
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
	[ -n "$1" ] || return 1

	# prepare command
	case $lb_current_os in
		BSD|macOS)
			cmd+=(-j -f '%Y-%m-%d %H:%M:%S')
			;;
		*)
			cmd+=(-d)
			;;
	esac

	# return timestamp
	"${cmd[@]}" "$*" +%s 2> /dev/null || return 2
}


# Convert timestamp to an user readable date
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_timestamp2date [OPTIONS] TIMESTAMP
lb_timestamp2date() {
	# default options
	local format cmd=(date)

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-f|--format)
				[ -n "$2" ] || return 1
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

	# first argument should be an integer
	[[ $1 =~ ^-?[0-9]+$ ]] || return 1

	# prepare command
	case $lb_current_os in
		BSD|macOS)
			cmd+=(-j -f %s $1)
			;;
		*)
			cmd+=(-d @$1)
			;;
	esac

	[ -z "$format" ] || cmd+=("$format")

	# return formatted date
	"${cmd[@]}" 2> /dev/null || return 2
}


# Compare software versions using semantic versionning
# Usage: lb_compare_versions VERSION_1 OPERATOR VERSION_2
lb_compare_versions() {
	# we wait for at least an operator and 2 versions
	[ $# -ge 3 ] || return 1

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
	if [ "$version1" = "$version2" ] ; then
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
			if [ $i = 1 ] ; then
				version1_num=$(echo "$version1_main" | cut -d. -f$i)
				version2_num=$(echo "$version2_main" | cut -d. -f$i)
			else
				# get minor numbers
				version1_num=$(echo "$version1_main" | cut -d. -s -f$i)
				version2_num=$(echo "$version2_main" | cut -d. -s -f$i)
			fi

			# transform simple numbers to dotted numbers
			# e.g. v3 => v3.0, v2.1 => v2.1.0
			[ -n "$version1_num" ] || version1_num=0
			[ -n "$version2_num" ] || version2_num=0

			if [ "$version1_num" = "$version2_num" ] ; then

				# if minor numbers (x.x.x.0), avoid infinite loop
				if [ $i -gt 3 ] ; then
					# end of comparison
					if [ $version1_num = 0 ] && [ $version2_num = 0 ] ; then
						break
					fi
				fi

				# compare next numbers
				i+=1
				continue
			fi

			# version numbers should be integer
			if [[ $version1_num =~ ^-?[0-9]+$ ]] && [[ $version2_num =~ ^-?[0-9]+$ ]] ; then
				# compare versions and quit
				if [ "$version1_num" $operator "$version2_num" ] ; then
					return 0
				else
					return 2
				fi
			else
				# if not integer, error
				return 1
			fi
		done
	fi

	# get pre-release tags
	local version1_tag version2_tag
	[[ "$version1" = *"-"* ]] && version1_tag=$(echo "$version1" | tr -d '[:space:]' | cut -d- -f2)
	[[ "$version2" = *"-"* ]] && version2_tag=$(echo "$version2" | tr -d '[:space:]' | cut -d- -f2)

	# tags are equal
	# this can happen if main versions are different
	# e.g. v1.0 = v1.0.0 or v2.1-beta = v2.1.0-beta
	if [ "$version1_tag" = "$version2_tag" ] ; then
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
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_df_fstype PATH
lb_df_fstype() {
	# usage error
	[ -n "$1" ] || return 1

	# test if path exists
	[ -e "$*" ] || return 2

	case $lb_current_os in
		macOS)
			# get mountpoint
			local mount_point
			mount_point=$(lb_df_mountpoint "$*") || return 3

			# get filesystem type
			diskutil info "$mount_point" | grep 'Type (Bundle):' | cut -d: -f2 | awk '{print $1}'
			;;

		*)
			if which lsblk &> /dev/null ; then
				# get device
				local device=$(df --output=source "$*" 2> /dev/null | tail -n 1)
				[ -n "$device" ] || return 3

				# get "real" fs type
				lsblk --output=FSTYPE "$device" 2> /dev/null | tail -n 1

				[ ${PIPESTATUS[0]} != 0 ] || return 0
			fi

			# no lsblk command or lsblk failed: use df command
			if df --output=fstype &> /dev/null ; then
				df --output=fstype "$*" 2> /dev/null | tail -n 1
			else
				# simple df command (BSD systems or Linux busybox)
				df -T "$*" 2> /dev/null | tail -n 1 | awk '{print $2}'
			fi
			;;
	esac

	[ ${PIPESTATUS[0]} = 0 ] || return 3
}


# Get space left on partition in bytes
# Usage: lb_df_space_left PATH
lb_df_space_left() {
	# usage error
	[ -n "$1" ] || return 1

	# test if path exists
	[ -e "$*" ] || return 2

	# get space available
	if df --output=avail &> /dev/null ; then
		df -k --output=avail "$*" 2> /dev/null | tail -n 1
	else
		# simple df command (BSD/macOS systems or Linux busybox)
		df -k "$*" 2> /dev/null | tail -n 1 | awk '{print $4}'
	fi

	[ ${PIPESTATUS[0]} = 0 ] || return 3
}


# Get mount point path of a partition
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_df_mountpoint PATH
lb_df_mountpoint() {
	# usage error
	[ -n "$1" ] || return 1

	# test if path exists
	[ -e "$*" ] || return 2

	# get mountpoint
	local mountpoint
	case $lb_current_os in
		macOS)
			# Note: macOS has not the same default df output structure than other OS
			mountpoint=$(df "$*" 2> /dev/null | tail -n 1 | awk '{for(i=9;i<=NF;++i) print $i}')
			;;

		*)
			if df --output=target &> /dev/null ; then
				mountpoint=$(df --output=target "$*" 2> /dev/null | tail -n 1)
			else
				# simple df command (BSD systems or Linux busybox)
				mountpoint=$(df "$*" 2> /dev/null | tail -n 1 | awk '{for(i=6;i<=NF;++i) print $i}')
			fi
			;;
	esac

	[ ${PIPESTATUS[0]} = 0 ] || return 3

	# verify if mountpoint exists (security in case of bad spaces detection)
	[ -e "$mountpoint" ] || return 3

	echo "$mountpoint"
}


# Get disk UUID
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_df_uuid PATH
# NOT SUPPORTED ON WINDOWS
lb_df_uuid() {
	# usage error
	[ -n "$1" ] || return 1

	# test if path exists
	[ -e "$*" ] || return 2

	case $lb_current_os in
		macOS)
			# get mountpoint
			local mount_point
			mount_point=$(lb_df_mountpoint "$*") || return 3

			# get filesystem type
			diskutil info "$mount_point" | grep 'Volume UUID:' | cut -d: -f2 | awk '{print $1}'
			;;

		*)
			# lsblk does not exists (BSD systems or Linux busybox): not supported
			which lsblk &> /dev/null || return 4

			# get device
			local device=$(df --output=source "$*" 2> /dev/null | tail -n 1)
			[ -n "$device" ] || return 3

			# get disk UUID
			lsblk --output=UUID "$device" 2> /dev/null | tail -n 1
			;;
	esac

	[ ${PIPESTATUS[0]} = 0 ] || return 3
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

	# test if directory exists
	[ -d "$path" ] || return 1

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
# Usage: lb_abspath [OPTIONS] PATH
lb_abspath() {
	local test_dir=true

	# get options
	case $1 in
		-n|--no-test)
			test_dir=false
			shift
			;;
	esac

	# usage error
	[ -n "$1" ] || return 1

	# get directory and file names
	local path directory=$(dirname "$*") file=$(basename "$*")

	# begin with '/': already an absolute path
	if [ "${directory:0:1}" = / ] ; then
		# test directory
		if $test_dir ; then
			[ -d "$directory" ] || return 2
		fi

		path=$directory
	else
		# get absolute path of the parent directory
		# if path does not exists, error
		path=$(cd "$directory" &> /dev/null && pwd) || return 2
	fi

	# case of root path (basename=/)
	if [ "$file" != / ] ; then
		# case of the current directory (do not put /path/to/./)
		if [ "$file" != "." ] ; then
			# do not put //file if parent directory is /
			[ "$directory" = / ] || path+="/"
			path+=$file
		fi
	fi

	echo "$path"
}


# Get real path of a file/directory
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_realpath PATH
lb_realpath() {
	# test if path exists
	[ -e "$1" ] || return 1

	case $lb_current_os in
		macOS)
			# macOS does not support readlink -f option
			perl -e 'use Cwd "abs_path";print abs_path(shift)' "$1" || return 2
			;;

		*)
			# other OS
			local path=$1

			# convert windows paths (C:\dir\file -> /cygdrive/c/dir/file)
			[ "$lb_current_os" = Windows ] && path=$(cygpath "$1")

			# find real path
			readlink -f "$path" 2> /dev/null || return 2
			;;
	esac
}


# Test if a path is writable
# Usage: lb_is_writable PATH
lb_is_writable() {
	# usage error
	[ -n "$1" ] || return 1

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
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_edit PATTERN FILE
lb_edit() {
	# usage error
	[ $# -ge 2 ] || return 1

	if [ "$lb__oldsed" = true ] ; then
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
		*BSD)
			echo BSD
			;;
		CYGWIN*)
			echo Windows
			;;
		*)
			echo Linux
			;;
	esac
}


# Detect current UID
# Usage: lb_current_uid
lb_current_uid() {
	id -u 2> /dev/null
}


# Test if a user exists
# Usage: lb_user_exists USER [USER...]
lb_user_exists() {
	# usage error
	[ -n "$1" ] || return 1

	local user
	for user in "$@" ; do
		[ -n "$user" ] || return 1
		# check groups of the user
		groups $user &> /dev/null || return 1
	done
}


# Test if current user is root
# Usage: lb_ami_root
lb_ami_root() {
	# test id instead of whoami because in some cases, root is renamed
	[ $(id -u 2> /dev/null) = 0 ]
}


# Test if an user is in a group
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_in_group GROUP [USER]
lb_in_group() {
	# usage error
	[ -n "$1" ] || return 1

	local user=$2

	# get current user if not defined
	[ -n "$user" ] || user=$(whoami)

	# get groups of the user: 2nd part of the groups result (user : group1 group2 ...)
	local groups=($(groups $user 2> /dev/null | cut -d: -f2))

	# no groups found
	[ ${#groups[@]} -gt 0 ] || return 3

	# find if user is in group
	lb_in_array "$1" "${groups[@]}"
}


# Test if a group exists
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_group_exists GROUP [GROUP...]
lb_group_exists() {
	# usage error
	[ -n "$1" ] || return 1

	case $lb_current_os in
		macOS|Windows)
			# OS not compatible
			return 2
			;;
	esac

	local group
	for group in "$@" ; do
		[ -n "$group" ] || return 1
		# check if group exists
		grep -q "^$group:" /etc/group &> /dev/null || return 1
	done
}


# Get users members of a group
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_group_members GROUP
lb_group_members() {
	# usage error
	[ -n "$1" ] || return 1

	case $lb_current_os in
		macOS|Windows)
			# OS not compatible
			return 3
			;;
	esac

	# get line of group file
	local group=$(grep -E "^$1:" /etc/group 2> /dev/null)

	# group not found
	[ -n "$group" ] || return 2

	# extract members and return users separated by spaces
	echo "$group" | sed "s/^$1:.*://; s/,/ /g"
}


# Generate a random password
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_generate_password [SIZE]
lb_generate_password() {
	# default options
	local size=16

	# get size option
	if [ -n "$1" ] ; then
		# check if is integer
		[[ $1 =~ ^-?[0-9]+$ ]] || return 1

		# size must be between 1 and 32
		if [ $size -ge 1 ] && [ $size -le 32 ] ; then
			size=$1
		else
			return 1
		fi
	fi

	local hasher=md5sum
	case $lb_current_os in
		BSD|macOS)
			hasher=md5
			;;
	esac

	# we may retry 10 times if password was not long enough
	local i password
	for i in $(seq 1 10) ; do

		# generate password
		if which openssl &> /dev/null ; then
			# with openssl random command; filter alphanumeric characters only
			password=$(openssl rand -base64 48 | tr -dc '[:alnum:]')
		else
			# test md5 and base64
			which $hasher base64 &> /dev/null || return 2

			# print date timestamp + nanoseconds, generate md5 checksum,
			# encode it in base64 and delete spaces
			password=$(date +%s%N | $hasher | base64 2> /dev/null | tr -d '[:space:]')
		fi

		# test if password is not empty
		[ -n "$password" ] || return 2

		# test size; if not good, retry
		if [ ${#password} -ge $size ] ; then
			echo "${password:0:$size}"
			return 0
		fi
	done

	return 2
}


# Send an email
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_email [OPTIONS] RECIPIENT[,RECIPIENT,...] MESSAGE
lb_email() {
	# usage error
	[ $# = 0 ] && return 1

	# default options and local variables
	local subject sender replyto cc bcc message message_html
	local multipart=false separator="_----------=_MailPart_118845H_15_62347"
	local attachments=()

	# email commands
	local cmd email_commands=(/usr/bin/mail /usr/sbin/sendmail)

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-s|--subject)
				[ -n "$2" ] || return 1
				subject=$2
				shift
				;;
			-r|--reply-to)
				[ -n "$2" ] || return 1
				replyto=$2
				shift
				;;
			-c|--cc)
				[ -n "$2" ] || return 1
				cc=$2
				shift
				;;
			-b|--bcc)
				[ -n "$2" ] || return 1
				bcc=$2
				shift
				;;
			-a|--attachment)
				[ -f "$2" ] || return 1
				attachments+=("$2")
				shift
				;;
			--sender)
				[ -n "$2" ] || return 1
				sender=$2
				shift
				;;
			--html)
				[ -n "$2" ] || return 1
				message_html=$2
				multipart=true
				shift
				;;
			--mail-command)
				lb_in_array "$2" "${email_commands[@]}" || return 1
				# detect if old version of mail command
				if [ "$2" = /usr/bin/mail ] && ! /usr/bin/mail --version &> /dev/null ; then
					return 2
				fi
				cmd=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	local recipients=$1
	# usage error if missing recipients
	[ ${#recipients} = 0 ] && return 1

	shift
	local text=$*

	# get text from stdin
	if [ ${#text} = 0 ] && ! [ -t 0 ] ; then
		local t
		while read -r t ; do
			text+="
$t"
		done
		# delete first line jump
		text=${text:1}
	fi

	# usage error if missing message
	# could be not detected by test above if recipients field has some spaces
	[ ${#text} = 0 ] && return 1

	# search compatible command to send email
	if [ -z "$cmd" ] ; then
		local c
		for c in ${email_commands[@]} ; do
			# test command
			if which "$c" &> /dev/null ; then
				# skip if old version of mail command
				if [ "$c" = /usr/bin/mail ] && ! /usr/bin/mail --version &> /dev/null ; then
					continue
				fi

				cmd=$c
				break
			fi
		done
	fi

	# if no command to send email, error
	[ -z "$cmd" ] && return 2

	# set email header
	[ -n "$sender" ] && message+="From: $sender
"
	message+="To: $recipients
"
	[ -n "$cc" ] && message+="Cc: $cc
"
	[ -n "$bcc" ] && message+="Bcc: $bcc
"
	[ -n "$replyto" ] && message+="Reply-To: $replyto
"
	[ -n "$subject" ] && message+="Subject: $subject
"
	message+="MIME-Version: 1.0
"

	# mixed definition (if attachments)
	[ ${#attachments[@]} -gt 0 ] && message+="Content-Type: multipart/mixed; boundary=\"${separator}_mixed\"

--${separator}_mixed
"

	# multipart definition (if HTML + TXT)
	$multipart && message+="Content-Type: multipart/alternative; boundary=\"$separator\"

--$separator
"

	# mail in TXT
	message+="Content-Type: text/plain; charset=\"utf-8\"

$text
"

	# mail in HTML + close multipart
	$multipart && message+="
--$separator
Content-Type: text/html; charset=\"utf-8\"

$message_html
--$separator--"

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
		/usr/bin/mail|/usr/sbin/sendmail)
			echo "$message" | $cmd -t || return 3
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
	local yes_default=false cancel_mode=false force_mode=false
	local yes_label=$lb__yes_shortlabel no_label=$lb__no_shortlabel cancel_label=$lb__cancel_shortlabel

	# set labels if missing
	[ -n "$yes_label" ] || yes_label=y
	[ -n "$no_label" ] || no_label=n
	[ -n "$cancel_label" ] || cancel_label=c

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-y|--yes)
				yes_default=true
				;;
			-c|--cancel)
				cancel_mode=true
				;;
			-f|--force)
				force_mode=true
				;;
			--yes-label)
				[ -n "$2" ] || return 1
				yes_label=$2
				shift
				;;
			--no-label)
				[ -n "$2" ] || return 1
				no_label=$2
				shift
				;;
			--cancel-label)
				[ -n "$2" ] || return 1
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
	[ -n "$1" ] || return 1

	local question choice
	while true ; do
		# print question (if not quiet mode)
		if [ "$lb_quietmode" != true ] ; then
			# defines question
			if $force_mode ; then
				question="$yes_label/$no_label"
			else
				if $yes_default ; then
					question="$(echo "$yes_label" | tr '[:lower:]' '[:upper:]')/$(echo "$no_label" | tr '[:upper:]' '[:lower:]')"
				else
					question="$(echo "$yes_label" | tr '[:upper:]' '[:lower:]')/$(echo "$no_label" | tr '[:lower:]' '[:upper:]')"
				fi
			fi

			# add cancel choice
			$cancel_mode && question+="/$(echo "$cancel_label" | tr '[:upper:]' '[:lower:]')"

			# print question
			echo -e -n "$* ($question): "
		fi

		# read user input
		read choice

		# if input is empty
		if [ -z "$choice" ] ; then
			# force prompt: ask question again
			! $force_mode || continue

			# default option
			if $yes_default ; then
				return 0
			else
				return 2
			fi
		fi

		# compare to confirmation string
		[ "$(echo "$choice" | tr '[:upper:]' '[:lower:]')" != "$(echo "$yes_label" | tr '[:upper:]' '[:lower:]')" ] || return 0

		# cancel case
		if $cancel_mode && [ "$(echo "$choice" | tr '[:upper:]' '[:lower:]')" = "$(echo "$cancel_label" | tr '[:upper:]' '[:lower:]')" ] ; then
			return 3
		fi

		# force prompt: if not NO, ask question again
		if $force_mode && [ "$(echo "$choice" | tr '[:upper:]' '[:lower:]')" != "$(echo "$no_label" | tr '[:upper:]' '[:lower:]')" ] ; then
			continue
		fi

		# answer is no
		return 2
	done
}


# Ask user to choose one or multiple options
# WARNING: This function has dependencies. You cannot copy/paste it to use it
# without including libbash.sh file.
# Usage: lb_choose_option [OPTIONS] CHOICE [CHOICE...]
lb_choose_option=()
lb_choose_option() {
	# reset result
	lb_choose_option=()

	# default options
	local default=() multiple_choices=false
	local label=$lb__chopt_label cancel_label=$lb__cancel_shortlabel

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-d|--default)
				[ -n "$2" ] || return 1
				# transform option1,option2,... to array
				lb_split , $2
				default=(${lb_split[@]})
				shift
				;;
			-m|--multiple)
				multiple_choices=true
				;;
			-l|--label)
				[ -n "$2" ] || return 1
				label=$2
				shift
				;;
			-c|--cancel-label)
				[ -n "$2" ] || return 1
				cancel_label=$2
				shift
				;;
			*)
				break
				;;
		esac
		shift # load next argument
	done

	# usage error if missing at least 1 choice option
	[ -n "$1" ] || return 1

	# verify if default options are valid
	if [ ${#default[@]} -gt 0 ] ; then
		local d
		for d in "${default[@]}" ; do
			# check if integer
			[[ $d =~ ^-?[0-9]+$ ]] || return 1

			if [ $d -lt 1 ] || [ $d -gt $# ] ; then
				return 1
			fi
		done
	fi

	# change default label if multiple options
	if $multiple_choices ; then
		[ "$label" = "$lb__chopt_label" ] && label=$lb__chopts_label
	fi

	local o choices

	# print question (if not quiet mode)
	if [ "$lb_quietmode" != true ] ; then
		# print question
		echo -e "$label"

		# print options
		local -i i=1
		for o in "$@" ; do
			echo "  $i. $o"
			i+=1
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
	read choices

	# defaut behaviour if input is empty
	if [ -z "$choices" ] ; then
		if [ ${#default[@]} -gt 0 ] ; then
			# return default option(s)
			lb_choose_option=(${default[@]})
			return 0
		else
			# cancel code
			return 2
		fi
	fi

	# convert choices to an array
	if $multiple_choices ; then
		lb_split , $choices
		choices=(${lb_split[@]})
	fi

	# parsing choices
	for o in ${choices[*]} ; do
		# check cancel option
		if [ "$o" = "$cancel_label" ] ; then
			lb_choose_option=()
			return 2
		fi

		# if not integer
		if ! [[ $o =~ ^-?[0-9]+$ ]] ; then
			lb_choose_option=()
			return 3
		fi

		# check if user choice is valid
		if [ $o -lt 1 ] || [ $o -gt $# ] ; then
			lb_choose_option=()
			return 3
		fi

		# save choice (prevent duplicates)
		lb_in_array $o "${lb_choose_option[@]}" || lb_choose_option+=($o)
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
				[ -n "$2" ] || return 1
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
	[ -n "$1" ] || return 1

	# print question (if not quiet mode)
	if [ "$lb_quietmode" != true ] ; then
		echo -n -e "$*"
		[ -z "$default" ] || echo -n -e " [$default]"
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
# Usage: lb_input_password [OPTIONS] [QUESTION_TEXT]
lb_input_password=""
lb_input_password() {
	# reset result
	lb_input_password=""

	# default options
	local label=$lb__pwd_label confirm_label=$lb__pwd_confirm_label
	local confirm=false min_size=0

	# set labels if missing
	[ -n "$label" ] || label="Password:"
	[ -n "$confirm_label" ] || confirm_label="Confirm password:"

	# get options
	while [ $# -gt 0 ] ; do
		case $1 in
			-c|--confirm)
				confirm=true
				;;
			--confirm-label)
				[ -n "$2" ] || return 1
				confirm_label=$2
				shift
				;;
			-m|--min-size)
				# check if integer
				[[ $2 =~ ^-?[0-9]+$ ]] || return 1
				[ $2 -gt 0 ] || return 1
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
	[ -z "$1" ] || label=$*

	# print question (if not quiet mode)
	[ "$lb_quietmode" = true ] || echo -n -e "$label "

	# prompt user for password
	read -s -r lb_input_password
	# line return
	echo

	# if empty, exit with error
	[ -n "$lb_input_password" ] || return 2

	# check password size (if --min-size option is set)
	if [ $min_size -gt 0 ] && [ ${#lb_input_password} -lt $min_size ] ; then
		lb_input_password=""
		return 4
	fi

	# if no confirmation, return OK
	$confirm || return 0

	# if confirmation, save current password
	local password_confirm=$lb_input_password

	# print confirmation question (if not quiet mode)
	[ "$lb_quietmode" = true ] || echo -n -e "$confirm_label "

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


# Say something with text-to-speech
# Usage: lb_say TEXT
lb_say() {
	local text=$* cmd=()

	# get text from stdin
	if [ ${#text} = 0 ] && ! [ -t 0 ] ; then
		local t
		while read -r t ; do
			text+="
$t"
		done
		# delete first line jump
		text=${text:1}
	fi

	# easy commands
	case $lb_current_os in
		macOS)
			say "$text" &> /dev/null
			return
			;;
		Windows)
			lb__powershell say "$text" &> /dev/null
			return
			;;
	esac

	# Linux: check tts software
	lb_command_exists espeak-ng || return 2

	# search for the current language voice (e.g. check fr-fr then fr)
	local lg opts=()
	for lg in $(echo $LANG | cut -d. -f1 | sed 's/_/-/' | tr '[:upper:]' '[:lower:]') $lb__lang ; do
		if lb_in_array $lg $(espeak-ng --voices 2> /dev/null | awk '{print $2}') ; then
			opts=(-v $lg)
			break
		fi
	done

	espeak-ng "${opts[@]}" "$text" &> /dev/null || return 1
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
	lb_display -p -l "$lb__critical_label" "$@"
}

lb_critical() {
	lb_display_critical "$@"
}

lb_display_error() {
	lb_display -p -l "$lb__error_label" "$@"
}

lb_err() {
	lb_display_error "$@"
}

lb_display_warning() {
	lb_display -p -l "$lb__warning_label" "$@"
}

lb_warn() {
	lb_display_warning "$@"
}

lb_warning() {
	lb_display_warning "$@"
}

lb_display_info() {
	lb_display -p -l "$lb__info_label" "$@"
}

lb_info() {
	lb_display_info "$@"
}

lb_display_debug() {
	lb_display -p -l "$lb__debug_label" "$@"
}

lb_debug() {
	lb_display_debug "$@"
}

# Common log functions
# Usage: lb_log_* [OPTIONS] TEXT
# See lb_log for options usage
lb_log_critical() {
	lb_log -p -l "$lb__critical_label" "$@"
}

lb_log_error() {
	lb_log -p -l "$lb__error_label" "$@"
}

lb_log_warning() {
	lb_log -p -l "$lb__warning_label" "$@"
}

lb_log_info() {
	lb_log -p -l "$lb__info_label" "$@"
}

lb_log_debug() {
	lb_log -p -l "$lb__debug_label" "$@"
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


# Test number of arguments passed to a script/function
# DEPRECATED: this function is useless and can be easely replaced by [ $# -op N ]
# Usage: lb_test_arguments OPERATOR N [ARG...]
lb_test_arguments() {
	# we wait for at least an operator and a number
	[ $# -ge 2 ] || return 1

	# arg 2 should be an integer
	[[ $2 =~ ^-?[0-9]+$ ]] || return 1

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


###############
#  VARIABLES  #
###############

# Internal variables

lb__load_result=0

# print formatted strings in console
lb__format_print=true

# get current terminal language (e.g. fr, en, ...)
lb__lang=${LANG:0:2}

# default labels
### translatable
lb__result_ok_label="... Done!"
lb__result_failed_label="... Failed!"
lb__ok_label="OK"
lb__cancel_label="Cancel"
lb__cancel_shortlabel="c"
lb__failed_label="Failed"
lb__yes_label="Yes"
lb__no_label="No"
lb__yes_shortlabel="y"
lb__no_shortlabel="n"
lb__pwd_label="Password:"
lb__pwd_confirm_label="Confirm password:"
lb__chopt_label="Choose an option:"
lb__chopts_label="Choose one ore more options:"
lb__chdir_label="Choose a directory:"
lb__chfile_label="Choose a file:"
lb__debug_label="DEBUG"
lb__info_label="INFO"
lb__warning_label="WARNING"
lb__error_label="ERROR"
lb__critical_label="CRITICAL"
lb__newfile_name="New file"
### END translatable

# Editable variables

# default log and display levels (CRITICAL ERROR WARNING INFO DEBUG)
lb_log_levels=("$lb__critical_label" "$lb__error_label" "$lb__warning_label" "$lb__info_label" "$lb__debug_label")

# exit code
lb_exitcode=0

# command to execute when exit
lb_exit_cmd=()


####################
#  INITIALIZATION  #
####################

# Set constant variables

# system context
declare -r lb_current_os=$(lb_current_os)
declare -r lb_current_hostname=$(hostname 2> /dev/null)
declare -r lb_current_user=$(whoami)
declare -r lb_current_uid=$(id -u 2> /dev/null)
declare -r lb_current_path=$(pwd)

# libbash context
declare -r lb_path=$(lb_realpath "$BASH_SOURCE")
declare -r lb_directory=$(dirname "$lb_path")

# current script context
declare -r lb_current_script=$(lb_realpath "$0")
declare -r lb_current_script_directory=$(dirname "$lb_current_script")
lb_current_script_name=$(basename "$lb_current_script")

# if macOS, disable text formatting in console
[ "$lb_current_os" = macOS ] && lb__format_print=false

# Test sed command
sed --version &> /dev/null
case $? in
	0)
		# normal sed command
		declare -r lb__oldsed=false
		;;
	127)
		# command sed not found
		lb_error "libbash.sh: [ERROR] cannot found sed command. Some functions will not work properly."
		lb__load_result=2
		;;
	*)
		# old sed command (mostly on macOS)
		declare -r lb__oldsed=true
		;;
esac

# Check variables
for v in lb_current_os lb_current_hostname lb_current_user lb_current_path \
         lb_path lb_directory \
         lb_current_script lb_current_script_name lb_current_script_directory ; do
	if [ -z "${!v}" ] ; then
		lb_error "libbash.sh: [WARNING] variable \$$v could not be set"
		lb__load_result=4
	fi
done

# Get options
while [ $# -gt 0 ] ; do
	case $1 in
		-g|--gui)
			# load libbash GUI + prevent crash if running bash with -e option
			lb__load_gui=0
			source "$lb_directory/libbash_gui.sh" &> /dev/null || lb__load_gui=$?
			case $lb__load_gui in
				0)
					# GUI loaded; continue
					;;
				2)
					lb_error "libbash.sh GUI: [ERROR] cannot set a GUI interface"
					lb__load_result=5
					;;
				*)
					lb_error "libbash.sh: [ERROR] cannot load GUI part. Please verify the path $lb_directory."
					lb__load_result=2
					;;
			esac
			;;
		-l|--lang)
			# no errors if bad options
			lb__lang=$(lb_getopt "$@") && shift
			;;
		--lang=*)
			# no errors if bad options
			lb__lang=$(lb_getopt "$@")
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

# Load translations
case $lb__lang in
	fr)
		if source "$lb_directory/locales/$lb__lang.sh" &> /dev/null ; then
			# reset log levels
			lb_loglevels=("$lb__critical_label" "$lb__error_label" "$lb__warning_label" "$lb__info_label" "$lb__debug_label")
		else
			lb_error "libbash.sh: [WARNING] cannot load translation: $lb__lang"
			lb__load_result=3
		fi
		;;
esac

return $lb__load_result
