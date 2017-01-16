# libbash.sh documentation

## Introduction
libbash.sh is a library of functions to easely write bash scripts.

## Usage
Add libbash.sh to your script before using functions:
```bash
source "/path/to/libbash.sh"
```
Then call the functions described below.

## Translations
If you want to, you can also use a translated version of libbash.

To use it, you have to include the locales **after** libbash.sh:
```bash
source "/path/to/libbash/locales/LANG.sh"
```

Supported languages:
- French (fr)

## Variables
You can use the following variables that are initialized when you include `libbash.sh` in your scripts:
- `$lb_current_script`: your current script (equal to `$0`)
- `$lb_current_script_name`: your current script name (result of command `basename $0`)
- `$lb_current_script_directory`: your current script name (result of command `dirname $0`)
- `$lb_current_path`: your current script name (result of command `pwd`)
- `$lb_exitcode`: script exit code (0 by default) that will be send if using `lb_exit` (equivalent to run `exit $lb_exitcode`)

## Functions
All functions are named with the `lb_` prefix.
Functions with a `*` are not fully supported on every OS yet (may change in the future).

* Basic bash functions
	* [lb_command_exists](#lb_command_exists)
	* [lb_function_exists](#lb_function_exists)
	* [lb_test_arguments](#lb_test_arguments)
* Display
	* [lb_print (or lb_echo)](#lb_print)
	* [lb_error](#lb_error)
	* [lb_display](#lb_display)
	* [lb_display_critical, lb_display_error, lb_display_warning, lb_display_info, lb_display_debug](#lb_display_presets)
	* [lb_result](#lb_result)
	* [lb_short_result](#lb_short_result)
* Logs
	* [lb_get_logfile](#lb_get_logfile)
	* [lb_set_logfile](#lb_set_logfile)
	* [lb_get_loglevel](#lb_get_loglevel)
	* [lb_set_loglevel](#lb_set_loglevel)
	* [lb_log](#lb_log)
	* [lb_log_critical, lb_log_error, lb_log_warning, lb_log_info, lb_log_debug](#lb_log_presets)
* Operations on variables
	* [lb_is_integer](#lb_is_integer)
	* [lb_array_contains](#lb_array_contains)
* Filesystem
	* [lb_df_fstype](#lb_df_fstype)*
	* [lb_df_space_left](#lb_df_space_left)
	* [lb_df_mountpoint](#lb_df_mountpoint)
	* [lb_df_uuid](#lb_df_uuid)*
* Files and directories
	* [lb_homepath](#lb_homepath)

---------------------------------------------------------------
## Basic bash functions
---------------------------------------------------------------
<a name="lb_command_exists"></a>
### lb_command_exists
Check if a command (or executable file) exists.

#### Usage
```bash
lb_command_exists COMMAND
```

#### Exit codes
- 0: command exists
- 1: usage error
- 2: command does not exists

#### Example
```bash
if lb_command_exists supertux2 ; then
	echo "You're ready to play to supertux!"
fi
```

---------------------------------------------------------------
<a name="lb_function_exists"></a>
### lb_function_exists
Check if a function exists.

#### Usage
```bash
lb_function_exists FUNCTION
```

#### Exit codes
- 0: function exists
- 1: usage error
- 2: function does not exists
- 3: command exists, but is not a function

#### Example
```bash
print_hello() {
	echo "Hello"
}

if lb_function_exists print_hello ; then
	print_hello
fi
```

---------------------------------------------------------------
<a name="lb_test_arguments"></a>
### lb_test_arguments
Test number of arguments passed to a function.

#### Usage
```bash
lb_test_arguments OPERATOR N [ARG...]
```

#### Arguments
```
OPERATOR  common bash comparison pattern: -eq|-ne|-lt|-le|-gt|-ge
N         expected number to compare to
ARG       your arguments; (e.g. $* without quotes)
```

#### Exit codes
- 0: arguments OK
- 1: usage error
- 2: arguments not OK

#### Example
```bash
if lb_test_arguments -lt 2 $* ; then
	echo "You have to give at least 2 arguments to this script."
fi
```

---------------------------------------------------------------
## Display
---------------------------------------------------------------
<a name="lb_print"></a>
### lb_print (or lb_echo)
Print a message to the console, with colors and formatting

#### Usage
```bash
lb_print [OPTIONS] TEXT
```
or
```bash
lb_echo [OPTIONS] TEXT
```

#### macOS case
For now, messages are not formatted for macOS consoles.

#### Options
```
-n         No line return after text
--bold     Format text in bold
--cyan,
--green,
--yellow,
--red      Format text with colours
```

#### Exit codes
Exit code of the `echo` command.

#### Example
```bash
lb_print --green "This is a green text."
```

---------------------------------------------------------------
<a name="lb_error"></a>
### lb_error
Print a message to the console, with colors and formatting, redirected to stderr.

#### Usage
```bash
lb_error [OPTIONS] TEXT
```
See [lb_print](#lb_print) for usage.

#### Example
```bash
lb_error --red "This is an error."
```

---------------------------------------------------------------
<a name="lb_display"></a>
### lb_display
Print a message to the console, can set a verbose level and can append to logs.

If you use the `--level MYLEVEL` option, the message will be displayed (and logged if option `--log` is set)
only if `MYLEVEL` is greater or equal to the current log level.

To set a log level, see [lb_set_loglevel](#lb_set_loglevel).

To set a log file, see [lb_set_logfile](#lb_set_logfile).

#### Usage
```bash
lb_display [OPTIONS] TEXT
```

#### Options
```
-n                 No line return after text
-l, --level LEVEL  Choose a display level (will be the same for logs)
-p, --prefix       Print "[LOG_LEVEL] " prefix before text
--log              Append text to log file if defined
```

#### Exit codes
- 0: OK
- 1: usage error
- 2: logs could not be written

#### Example
```bash
lb_display --log "This message you see will be stored in logs."
```

---------------------------------------------------------------
<a name="lb_display_presets"></a>
### lb_display_critical, lb_display_error, lb_display_warning, lb_display_info, lb_display_debug
Shortcuts to display with common log levels.

It uses the `lb_display` function with `--prefix` and `--level` options.

#### Usage
```bash
lb_display_... [OPTIONS] TEXT
```
See [lb_display](#lb_display) for usage.

#### Example
```bash
lb_display_critical "This is a critical error!"
```

---------------------------------------------------------------
<a name="lb_result"></a>
### lb_result
Manage a result and print a label to the console to indicate if a command succeeded or failed.

#### Usage
```bash
lb_result [OPTIONS] [EXIT_CODE]
```

#### Options
```
--ok-label LABEL       Set a ok label
--failed-label LABEL   Set a failed label
--log                  Append result to log file
-l, --log-level LEVEL  Choose a display level (will be the same for logs)
-e, --save-exit-code   Save the result to the $lb_exitcode variable
-x, --exit-on-error    Exit if result is not ok (exit code not to 0)
-q, --quiet            Do not print anything

EXIT_CODE              Specify an exit code. If not set, variable $? will be used.
```

#### Exit codes
Exit code forwarded of the command (1 may can also be an usage error).

#### Example
```bash
echo "Processing..."
mycommand
lb_result
```

---------------------------------------------------------------
<a name="lb_short_result"></a>
### lb_short_result
Print a short result label to the console to indicate if a command succeeded or failed.

It uses the `lb_result` function with `--ok-label [  OK  ]` and `--failed-label [ FAILED ]` options.

#### Usage
```bash
lb_short_result [OPTIONS] EXIT_CODE
```

Be careful that exit code is required!

See [lb_result](#lb_result) for options usage.

#### Example
```bash
echo -n "Starting service...   "
my_service &> /dev/null
lb_short_result $?
```

---------------------------------------------------------------
## Logs
---------------------------------------------------------------
<a name="lb_get_logfile"></a>
### lb_get_logfile
Return path of the defined log file.

To set a log file, see [lb_set_logfile](#lb_set_logfile).

#### Usage
```bash
lb_get_logfile
```

#### Exit codes
- 0: OK
- 1: Log file is not set
- 2: Log file is not writable

#### Example
```bash
logfile=$(lb_get_logfile)
```

---------------------------------------------------------------
<a name="lb_set_logfile"></a>
### lb_set_logfile
Return path of the defined log file.

To set a log file, see [lb_set_logfile](#lb_set_logfile).

#### Usage
```bash
lb_set_logfile [OPTIONS] FILE
```

#### Options
```
-a, --append     If log file already exists, append to it
-x, --overwrite  If log file already exists, overwrite it
```

#### Exit codes
- 0: Log file set
- 1: Usage error
- 2: Log file cannot be created or is not writable
- 3: Log file already exists, but append option is not set
- 4: Path exists but is not a regular file

#### Example
```bash
lb_set_logfile /path/to/logfile.log
```

---------------------------------------------------------------
<a name="lb_get_loglevel"></a>
### lb_get_loglevel
Get the current log level (or the id of a level).

See [lb_set_loglevel](#lb_set_loglevel) for more details on default log levels.

#### Usage
```bash
lb_get_loglevel [OPTIONS] [LEVEL]
```

#### Options
```
--id  Get log level ID instead of its name
```

#### Exit codes
- 0: OK
- 1: Log level is not set
- 2: Log level not found

#### Example
```bash
current_loglevel=$(lb_get_loglevel)
```

---------------------------------------------------------------
<a name="lb_set_loglevel"></a>
### lb_set_loglevel
Set the log level for logging.

#### Usage
```bash
lb_set_loglevel LEVEL
```

#### Log levels
Default log levels are:
- 0. CRITICAL
- 1. ERROR
- 2. WARNING
- 3. INFO
- 4. DEBUG

The default log level is set to maximum (DEBUG by default), which means that it will print logs of every levels.

Please note that if you set a log level, every messages with a lower level will also be displayed/logged.

If you display/log a message with an unknown log level, it will always be displayed/logged.

#### Exit codes
- 0: Log level set
- 1: Usage error
- 2: Specified log level not found

#### Example
```bash
# set normal logs
lb_set_loglevel INFO
```

---------------------------------------------------------------
<a name="lb_log"></a>
### lb_log
Print text into a log file.

If you use the `--level MYLEVEL` option, the message will be logged
only if `MYLEVEL` is greater or equal to the current log level.

To set a log level, see [lb_set_loglevel](#lb_set_loglevel).

To set a log file, see [lb_set_logfile](#lb_set_logfile).

#### Usage
```bash
lb_log [OPTIONS] TEXT
```

#### Options
```
-n                 No line return after text
-l, --level LEVEL  Choose a log level
-p, --prefix       Print "[LOG_LEVEL] " prefix before text
-d, --date-prefix  Print [date] prefix
-a, --all-prefix   Print level and date prefixes
-x, --overwrite    Clean log file before print text
```

#### Exit codes
- 0: OK
- 1: Log file is not set
- 2: Error while writing into file

#### Example
```bash
lb_log "This line will be printed in the log file."
```

---------------------------------------------------------------
<a name="lb_log_presets"></a>
### lb_log_critical, lb_log_error, lb_log_warning, lb_log_info, lb_log_debug
Shortcuts to log with common log levels.

It uses the `lb_log` function with `--prefix` and `--level` options.

#### Usage
```bash
lb_log_... [OPTIONS] TEXT
```
See [lb_log](#lb_log) for usage.

#### Example
```bash
lb_log_error "There was an error in your script!"
```

---------------------------------------------------------------
## Operations on variables
---------------------------------------------------------------
<a name="lb_is_integer"></a>
### lb_is_integer
Test if a value is integer.

#### Usage
```bash
lb_is_integer VALUE
```

#### Exit codes
- 0: value is an integer
- 1: value is not an integer

#### Example
```bash
x="-1"
if lb_is_integer $x ; then
	echo "x is an integer"
fi
```

---------------------------------------------------------------
<a name="lb_array_contains"></a>
### lb_array_contains
Check if an array contains a value.

#### Usage
```bash
lb_array_contains VALUE "${ARRAY[@]}"
```
**Warning**: put your array between quotes or search will fail if you have spaces in values.

#### Exit codes
- 0: value was found in array
- 1: usage error
- 2: value is NOT in array

#### Example
```bash
array=(one two three)
if lb_array_contains "one" "${array[@]}" ; then
	echo "one is in array"
fi
```

---------------------------------------------------------------
## Filesystem
---------------------------------------------------------------
<a name="lb_df_fstype"></a>
### lb_df_fstype
Give the filesystem type of a path.

**NOT SUPPORTED YET ON macOS**

#### Usage
```bash
lb_df_fstype PATH
```
Note: PATH may also be a device path (e.g. /dev/sda1)

#### Exit codes
- 0: OK
- 1: usage error
- 2: PATH does not exists
- 3: unknown error
- 4: command not supported on this system

#### Example
```bash
root_fstype=$(lb_df_fstype /)
```

---------------------------------------------------------------
<a name="lb_df_space_left"></a>
### lb_df_space_left
Get space left on partition in bytes.

#### Usage
```bash
lb_df_space_left PATH
```
Note: PATH may also be a device path (e.g. /dev/sda1)

#### Exit codes
- 0: OK
- 1: usage error
- 2: PATH does not exists
- 3: unknown error

#### Example
```bash
space_left=$(lb_df_space_left /)
```

---------------------------------------------------------------
<a name="lb_df_mountpoint"></a>
### lb_df_mountpoint
Get mount point of a partition.

#### Usage
```bash
lb_df_mountpoint PATH
```
Note: PATH may also be a device path (e.g. /dev/sda1)

#### Exit codes
- 0: OK
- 1: usage error
- 2: PATH does not exists
- 3: unknown error

#### Example
```bash
mountpoint=$(lb_df_mountpoint /)
```

---------------------------------------------------------------
<a name="lb_df_uuid"></a>
### lb_df_uuid
Get the disk UUID for a given path.

**NOT SUPPORTED YET ON macOS**

#### Usage
```bash
lb_df_uuid PATH
```
Note: PATH may also be a device path (e.g. /dev/sda1)

#### Exit codes
- 0: OK
- 1: usage error
- 2: path does not exists
- 3: unknown error
- 4: command not supported on this system
- 5: disk UUID not found

#### Example
```bash
disk_uuid=$(lb_df_uuid /media/usbkey)
```

---------------------------------------------------------------
<a name="lb_homepath"></a>
### lb_homepath
Get home path of an user.

#### Usage
```bash
lb_homepath [USER]
```
If USER not set, using current user.

#### Exit codes
- 0: OK
- 1: usage error

#### Example
```bash
home=$(lb_homepath)
```
