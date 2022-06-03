# libbash.sh documentation

## Introduction
libbash.sh is a library of functions to easely write bash scripts.

## Usage
Add libbash.sh to your script before using functions:
```bash
source "/path/to/libbash.sh" [OPTIONS]
```
Then call the functions described below.

## Options
```
-g, --gui        Load libbash.sh GUI
-l, --lang LANG  Load a specific translation (by default the current terminal language)
-q, --quiet      Disable any output in functions
```

Note: If you call libbash.sh without any of these options and if you want to use some options in your own script, you have to add a simple character at the end of the source command to avoid overwriting your own options.

```bash
# example: this will prevent to call libbash with --quiet option and disable your own --quiet script option
source /path/to/libbash.sh -
if [ "$1" = "--quiet" ] ; then
	...
fi
```

### libbash.sh GUI
To use the GUI functions, you have to load libbash.sh with the `--gui` (or `-g`) option.
See the [GUI documentation](libbash_gui.md) for more informations.

### Locales
By default, libbash.sh translation is loaded in the current terminal language.
But you can specify a language by the `--lang` option.
Currently supported languages:
- `en`: English (default if language not found)
- `fr`: French

You can also add your own translation in `locales` directory.

## Return codes
When you load libbash.sh, you can have the following return codes:
- 0: libbash.sh is loaded
- 1: libbash.sh file does not exists (in most cases), or is corrupted
- 2: cannot load libbash.sh GUI or some dependencies
- 3: cannot load translation file
- 4: some variables could not be initialized
- 5: cannot set a GUI interface (if GUI loaded)

## Variables
You can use the following variables that are initialized when you include libbash.sh in your scripts (read only):
- `$lb_version`: the current libbash.sh version
- `$lb_current_os`: your current Operating System (result of `lb_current_os` function)
- `$lb_current_hostname`: your current host name (result of `hostname` command)
- `$lb_current_user`: your username (result of `whoami` command)
- `$lb_current_uid`: your user ID
- `$lb_current_path`: your current path (result of `pwd` command)
- `$lb_path`: real path of libbash.sh
- `$lb_directory`: libbash.sh directory real path
- `$lb_current_script`: real path of your current script
- `$lb_current_script_directory`: real directory path of your current script

You can use and modify the following variables in your scripts:
- `$lb_current_script_name`: name of your current script (same as `basename $0` by default)
- `$lb_quietmode`: (boolean, false by default) if set to `true`, it will disable any display in console (including questions in `lb_yesno` and `lb_choose_option`)
- `$lb_exitcode`: script exit code (integer, 0 by default) that will be send if using `lb_exit` (same as `exit $lb_exitcode`)
- `$lb_exit_cmd`: array that contains a command to execute when `lb_exit()` function is called (empty by default)

**Warning: DO NOT CREATE** any other variable or function with `lb_` prefix in your scripts
(nor `lbg_` if you use libbash.sh GUI) as you could override or broke some features.

## Functions
Be careful with functions with short options (e.g. `lb_exit -q -f`): options must be called separately (e.g. `lb_exit -qf` will not work).
Functions with a `*` are not fully supported on every OS yet (may change in the future).

* Bash utilities
	* [lb_command_exists](#lb_command_exists)
	* [lb_function_exists](#lb_function_exists)
	* [lb_cmd_to_array](#lb_cmd_to_array)
	* [lb_getargs](#lb_getargs)
	* [lb_getopt](#lb_getopt)
	* [lb_exit](#lb_exit)
* Display
	* [lb_get_display_level](#lb_get_display_level)
	* [lb_set_display_level](#lb_set_display_level)
	* [lb_print (or lb_echo)](#lb_print)
	* [lb_error](#lb_error)
	* [lb_display](#lb_display)
	* [lb_display_critical, lb_display_error, lb_display_warning, lb_display_info, lb_display_debug](#lb_display_presets)
	* [lb_result](#lb_result)
	* [lb_short_result](#lb_short_result)
* Logs
	* [lb_get_logfile](#lb_get_logfile)
	* [lb_set_logfile](#lb_set_logfile)
	* [lb_get_log_level](#lb_get_log_level)
	* [lb_set_log_level](#lb_set_log_level)
	* [lb_log](#lb_log)
	* [lb_log_critical, lb_log_error, lb_log_warning, lb_log_info, lb_log_debug](#lb_log_presets)
* Configuration files
	* [lb_read_config](#lb_read_config)
	* [lb_import_config](#lb_import_config)
	* [lb_migrate_config](#lb_migrate_config)
	* [lb_get_config](#lb_get_config)
	* [lb_set_config](#lb_set_config)
* Operations on variables
	* [lb_istrue](#lb_istrue)
	* [lb_is_number](#lb_is_number)
	* [lb_is_integer](#lb_is_integer)
	* [lb_is_boolean](#lb_is_boolean)
	* [lb_is_email](#lb_is_email)
	* [lb_is_comment](#lb_is_comment)
	* [lb_trim](#lb_trim)
	* [lb_split](#lb_split)
	* [lb_join](#lb_join)
	* [lb_in_array](#lb_in_array)
	* [lb_date2timestamp](#lb_date2timestamp)
	* [lb_timestamp2date](#lb_timestamp2date)
	* [lb_compare_versions](#lb_compare_versions)
* Filesystem
	* [lb_df_fstype](#lb_df_fstype)
	* [lb_df_space_left](#lb_df_space_left)
	* [lb_df_mountpoint](#lb_df_mountpoint)
	* [lb_df_uuid](#lb_df_uuid)*
* Files and directories
	* [lb_homepath](#lb_homepath)
	* [lb_is_dir_empty](#lb_is_dir_empty)
	* [lb_abspath](#lb_abspath)
	* [lb_realpath](#lb_realpath)
	* [lb_is_writable](#lb_is_writable)
	* [lb_edit](#lb_edit)
* System utilities
	* [lb_current_os](#lb_current_os)
	* [lb_current_uid](#lb_current_uid)
	* [lb_user_exists](#lb_user_exists)
	* [lb_ami_root](#lb_ami_root)
	* [lb_in_group](#lb_in_group)
	* [lb_group_exists](#lb_group_exists)*
	* [lb_group_members](#lb_group_members)*
	* [lb_generate_password](#lb_generate_password)
	* [lb_email](#lb_email)*
* User interaction
	* [lb_yesno](#lb_yesno)
	* [lb_choose_option](#lb_choose_option)
	* [lb_input_text](#lb_input_text)
	* [lb_input_password](#lb_input_password)
	* [lb_say](#lb_say)

---------------------------------------------------------------
## Bash utilities
---------------------------------------------------------------
<a name="lb_command_exists"></a>
### lb_command_exists
Check if a command exists.
Works for commands, functions and executable files.

#### Usage
```bash
lb_command_exists COMMAND [COMMAND...]
```

#### Exit codes
- 0: Command(s) exists
- 1: Command(s) does not exists

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
lb_function_exists FUNCTION [FUNCTION...]
```

#### Exit codes
- 0: Function(s) exists
- 1: Usage error
- 2: Function(s) does not exists
- 3: Command exists, but is not a function

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
<a name="lb_cmd_to_array"></a>
### lb_cmd_to_array
Run a command and put the results in an array. Values are separated by line returns.
Useful for parsing results of `find` or `grep` commands, because values with spaces
are not considered as separated values.

#### Usage
```bash
lb_cmd_to_array CMD [ARGS]
```

#### Exit codes
Exit code of the command (1 if no command provided)

#### Example
```bash
# search all jpg files
lb_cmd_to_array find . -name '*.jpg'

# parse all jpg files, without problems with spaces in file names
for f in "${lb_cmd_to_array[@]}" ; do
	echo "File found: $f"
	...
done
```

---------------------------------------------------------------
<a name="lb_getargs"></a>
### lb_getargs
Parse arguments and split concatenated options.
Combined with [lb_getopt](#lb_getopt), you can create scripts with full options,
better than with the `getopts` command.

Note: A common usage of this function is `lb_getargs "$@"`
to split arguments of your current script (see complete example below).

#### Usage
```bash
lb_getargs "$@"
```
**Warning**: put quotes to support spaces in arguments.

#### Exit codes
- 0: Arguments parsed
- 1: No arguments

#### Example
```bash
# parse and get arguments
lb_getargs "$@" && set -- "${lb_getargs[@]}"

# if you called the current script with arguments:
#   -rp /home
# now arguments ($@) are:
#   -r -p /home

# get options
while [ $# -gt 0 ] ; do
    case $1 in
        -p|--path)
            path=$(lb_getopt "$@")
            if [ $? != 0 ] ; then
                echo "Usage error: missing path"
                exit 1
            fi
            shift # remove the value
            ;;
        -r|--recursive)
            recursive=true
            ;;
        -*)
            echo "Unknown option: $1"
            exit 1
            ;;
        *)
            # not an option: stop parsing
            break
            ;;
    esac
    shift # go the the next argument
done

# other arguments are available in $@ variable
```

---------------------------------------------------------------
<a name="lb_getopt"></a>
### lb_getopt
Get value of an option.

#### Usage
```bash
lb_getopt "$@"
```
**Warning**: put quotes to support spaces in arguments.

#### Exit codes
- 0: Value returned
- 1: Option value is missing

#### Example
See the complete example of the [lb_getargs function](#lb_getargs) above.

---------------------------------------------------------------
<a name="lb_exit"></a>
### lb_exit
Run a command (optional) and exit script with a specified exit code.

#### Usage
```bash
lb_exit [OPTIONS] [EXIT_CODE]
```

#### Options
```
-f, --forward-exitcode  Forward exitcode from the exit command
                        (defined in the $lb_exit_cmd variable)
-q, --quiet             Quiet mode (do not print exit command output)

EXIT_CODE  Specify an exit code (if not set, $lb_exitcode will be used)
```

#### Example
```bash
# print a message and exit script with code 42
lb_exit_cmd=(echo "So long and thanks for all the fish!")
lb_exitcode=42

lb_exit
```

---------------------------------------------------------------
## Display
---------------------------------------------------------------
<a name="lb_get_display_level"></a>
### lb_get_display_level
Get the current display (verbose) level (or the id of a level).

See [lb_set_log_level](#lb_set_log_level) for more details on default display/log levels.

#### Usage
```bash
lb_get_display_level [OPTIONS] [LEVEL_NAME]
```

#### Options
```
--id  Get display level ID instead of its name
```

#### Exit codes
- 0: OK
- 1: Display level is not set
- 2: Display level not found

#### Example
```bash
current_display_level=$(lb_get_display_level)
```

---------------------------------------------------------------
<a name="lb_set_display_level"></a>
### lb_set_display_level
Set the display (verbose) level for messages using [lb_display](#lb_display) function.

#### Usage
```bash
lb_set_display_level LEVEL_NAME
```

#### Display levels
Default display levels are the same as the log level. See [lb_set_log_level](#lb_set_log_level) for more details.

The default display level is set to maximum (DEBUG by default), which means that it will print all messages.

Please note that if you set a display level, every messages with a lower level will also be displayed.

If you display a message with an unknown display level, it will be displayed.

#### Exit codes
- 0: Display level set
- 1: Usage error
- 2: Specified display level not found

#### Example
```bash
# set normal verbose mode
lb_set_display_level INFO
```

---------------------------------------------------------------
<a name="lb_print"></a>
### lb_print (or lb_echo)
Print a message to the console, with colors and formatting.

#### Usage
```bash
lb_print [OPTIONS] TEXT
```
or
```bash
lb_echo [OPTIONS] TEXT
```
Note: you can also give `TEXT` argument using stdin or pipes.

#### macOS case
For now, messages are not formatted in macOS terminal.

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

To set a log level, see [lb_set_log_level](#lb_set_log_level).

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
--say              Say text
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Logs could not be written
- 3: Unknown error while printing

#### Example
```bash
lb_display --log --say "This message you see and hear will be stored in logs."
```

---------------------------------------------------------------
<a name="lb_display_presets"></a>
### lb_display_critical, lb_display_error, lb_display_warning, lb_display_info, lb_display_debug
Shortcuts to display with common log levels.

It uses the `lb_display` function with `--prefix` and `--level` options.

Available functions:
- `lb_display_critical`
- `lb_display_error`
- `lb_display_warning` (or `lb_warning`)
- `lb_display_info` (or `lb_info`)
- `lb_display_debug` (or `lb_debug`)

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
Manage a command result code and print a label to the console to indicate if a command succeeded or failed.

#### Usage
```bash
lb_result [OPTIONS] [EXIT_CODE]
```

#### Options
```
--ok-label LABEL           Set a success label (default: OK)
--failed-label LABEL       Set a failed label (default: FAILED)
-d, --display-level LEVEL  Choose a display level
--log                      Append result to log file
-l, --log-level LEVEL      Choose a log level
--smart-levels             Set display and log levels to INFO if ok and ERROR if failed
                           (equals calling -d INFO -l INFO if ok and -d ERROR -l ERROR if failed)
--say                      Say result
-s, --save-exitcode        Save the result to the $lb_exitcode variable
-e, --error-exitcode CODE  Set a custom code to the $lb_exitcode variable if error
-x, --exit-on-error        Exit if result is not ok (exit code not to 0)
-q, --quiet                Quiet mode, do not print anything (just follow result code)

EXIT_CODE                  Specify an exit code. If not set, variable $? will be used
```

#### Exit codes
Exit code forwarded of the command (beware that 1 could also mean an usage error).

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

It is an alias to the `lb_result` function with `--ok-label [  OK  ]` and `--failed-label [ FAILED ]` options.

#### Usage
```bash
lb_short_result [OPTIONS] [EXIT_CODE]
```
See [lb_result](#lb_result) for options usage.

#### Exit codes
Exit code forwarded of the command (beware that 1 could also mean an usage error).

#### Example
```bash
echo -n "Starting service...   "
my_service &> /dev/null
lb_short_result
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
Set path of the log file. If file does not exists, it is created.

#### Usage
```bash
lb_set_logfile [OPTIONS] PATH
```

#### Options
```
-a, --append      Append to the file if exists
-x, --overwrite   Overwrite file if exists
-w, --win-format  Write logs with Windows end of lines
```

#### Exit codes
- 0: Log file set
- 1: Usage error
- 2: Log file cannot be created or is not writable
- 3: Log file already exists, but append option is not set
- 4: Path exists, but is not a regular file

#### Example
```bash
lb_set_logfile /path/to/logfile.log
```

---------------------------------------------------------------
<a name="lb_get_log_level"></a>
### lb_get_log_level
Get the current log level (or the id of a level).

See [lb_set_log_level](#lb_set_log_level) for more details on default log levels.

#### Usage
```bash
lb_get_log_level [OPTIONS] [LEVEL_NAME]
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
current_log_level=$(lb_get_log_level)
```

---------------------------------------------------------------
<a name="lb_set_log_level"></a>
### lb_set_log_level
Set the log level for logging.

#### Usage
```bash
lb_set_log_level LEVEL_NAME
```

#### Log levels
Default log levels are (from lower to higher):
- 0. CRITICAL
- 1. ERROR
- 2. WARNING
- 3. INFO
- 4. DEBUG

The default log level is set to maximum (DEBUG by default), which means that it will print logs of every levels.

Please note that if you set a log level, every messages with a lower level will also be logged.

If you log a message with an unknown log level, it will always be logged.

#### Exit codes
- 0: Log level set
- 1: Usage error
- 2: Specified log level not found

#### Example
```bash
# set normal logs
lb_set_log_level INFO
```

---------------------------------------------------------------
<a name="lb_log"></a>
### lb_log
Print text into the log file.

If you use the `--level MYLEVEL` option, the message will be logged
only if `MYLEVEL` is greater or equal to the current log level.

To set a log level, see [lb_set_log_level](#lb_set_log_level).

To set a log file, see [lb_set_logfile](#lb_set_logfile).

#### Usage
```bash
lb_log [OPTIONS] TEXT
```
Note: you can also give `TEXT` argument using stdin or pipes.

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
## Configuration files
---------------------------------------------------------------
<a name="lb_read_config"></a>
### lb_read_config
Read a config file and put each line that is not a comment or empty into the `${lb_read_config[@]}` array variable.

Config file definition:
- Simple text file
- Using `#` or `;` at start of line as comment
- INI files are required if using sections filter

#### Usage
```bash
lb_read_config [OPTIONS] PATH
```

#### Options
```
-s, --section SECTION  Read parameters only in the specified section(s)
-a, --analyse          Analyse mode: return sections and parameters names, even defaults in comments
```

#### Exit codes
- 0: File read
- 1: Usage error or file(s) does not exists
- 2: File exists but is not readable
- 3: Specified section was not found

#### Examples
Read and print values
```bash
lb_read_config my_config.conf
for i in "${lb_read_config[@]}" ; do
	echo "$i"
done
```

---------------------------------------------------------------
<a name="lb_import_config"></a>
### lb_import_config
Import a config file and assign values to bash variables.

Config file definition:
- Simple text file
- Using `#` or `;` at start of line as comment
- INI files are required if using sections filter
- Values with spaces should have quotes like: `param = 'my value'` or `param = "my value"`
- Lines that contains $ and \` characters are not imported to avoid shell injection. You can import them anyway with the `--unsecure` option (see below).

#### Usage
```bash
lb_import_config [OPTIONS] PATH [FILTERS...]
```

#### Options
```
-s, --section SECTION     Import parameters only in the specified section(s)
-t, --template-file FILE  Use a config file as reference to import only defined parameters
-e, --all-errors          Return all errors in exit codes
-u, --unsecure            Do not prevent shell injection (could be dangerous)

FILTERS                   List of parameters that should be imported (others will be ignored)
```

#### Exit codes
- 0: Configuration imported
- 1: Usage error or file(s) does not exists
- 2: One or more parameters were not imported, or specified section not found
- 3: One or more line has a bad syntax (if `--all-errors` option is enabled)
- 4: One or more line contains shell commands or variables (if `--all-errors` option is enabled)
- 5: File exists but is not readable
- 6: Read template failed

#### Example
```bash
### content of my_config.conf
hello_message = "Hello dear users"

users = (John Mark)

other_thing = "Something useless"
### end content of my_config.conf
```

1. Simple import of config:
```bash
lb_import_config my_config.conf

# print bye message
echo "$hello_message ${users[@]}"
```

2. Secure import with a template:
```bash
### content of template.conf
hello_message = ""
users = ()
### end content of template.conf

lb_import_config --template template.conf my_config.conf

# $other_thing will be empty

# print bye message
echo "$hello_message ${users[@]}"
```

---------------------------------------------------------------
<a name="lb_migrate_config"></a>
### lb_migrate_config
Migrate a config file to a new one.
Import from old config parameters only defined in new config.
Be careful that old defined values are lost! To avoid that, you have to code an upgrade procedure.

#### Usage
```bash
lb_migrate_config OLD_FILE NEW_FILE
```

#### Exit codes
- 0: Configuration migrated
- 1: File(s) does not exists
- 2: One or more parameters were not migrated
- 3: File(s) are not readable/writable
- 4: Failed to analyse new config file

#### Example
```bash
lb_migrate_config old_config.conf new_config.conf
```

---------------------------------------------------------------
<a name="lb_get_config"></a>
### lb_get_config
Get a parameter in a config file.

Config file definition:
- Simple text file
- Using `#` or `;` at start of line as comment
- INI files are required if using sections filter

#### Usage
```bash
lb_get_config [OPTIONS] FILE PARAM
```

You can also get config from stdin with using the following syntax:
```bash
... | lb_get_config [OPTIONS] - PARAM
```

#### Options
```
-s, --section SECTION  Get the parameter only in the specified section
```

#### Exit codes
- 0: Configuration file updated
- 1: Usage error or file(s) does not exists
- 2: Configuration file is not readable
- 3: Parameter not found

#### Example
```bash
myoption=$(lb_get_config my_config.conf myoption)
```

---------------------------------------------------------------
<a name="lb_set_config"></a>
### lb_set_config
Set a parameter in a config file.

Config file definition:
- Simple text file
- Using `#` or `;` at start of line as comment
- INI files are required if using sections filter

#### Usage
```bash
lb_set_config [OPTIONS] FILE PARAM VALUE
```

#### Options
```
-s, --section SECTION  Set the parameter only in the specified section
--strict               Strict mode: do not insert parameter if it does not exists
--no-spaces            Insert values like 'param=value' instead of 'param = value'
```

#### Exit codes
- 0: Configuration file updated
- 1: Usage error or file(s) does not exists
- 2: Configuration file is not readable/writable
- 3: Parameter does not exists (if strict mode)
- 4: Error in setting config

#### Example
```bash
lb_set_config my_config.conf myoption "My value"
```

---------------------------------------------------------------
## Operations on variables
---------------------------------------------------------------
<a name="lb_istrue"></a>
### lb_istrue
Test if a value is boolean and true.
Useful to test variables quickly and securely (see example below).

#### Usage
```bash
lb_istrue VALUE
```

#### Exit codes
- 0: Value is true
- 1: Value is NOT true

#### Example
```bash
# WITHOUT lb_istrue:
x=youvebeenhacked
if $x ; then
	echo "yes, it's true, but a hack command might have been called"
fi

# WITH lb_istrue:
x=true
if lb_istrue $x ; then
    echo "yes, it's true and not a hack"
fi
```

---------------------------------------------------------------
<a name="lb_is_number"></a>
### lb_is_number
Test if a value is a number.

#### Usage
```bash
lb_is_number VALUE
```

#### Exit codes
- 0: Value is a number
- 1: Value is not a number

#### Example
```bash
x=-42.9
if lb_is_number "$x" ; then
    echo "x is a number"
fi
```

---------------------------------------------------------------
<a name="lb_is_integer"></a>
### lb_is_integer
Test if a value is a integer.

#### Usage
```bash
lb_is_integer VALUE
```

#### Exit codes
- 0: Value is an integer
- 1: Value is not an integer

#### Example
```bash
x=-10
if lb_is_integer "$x" ; then
    echo "x is an integer"
fi
```

---------------------------------------------------------------
<a name="lb_is_boolean"></a>
### lb_is_boolean
Test if a value is a boolean.

#### Usage
```bash
lb_is_boolean VALUE
```

#### Exit codes
- 0: Value is a boolean
- 1: Value is not a boolean

#### Example
```bash
x=false
if lb_is_boolean "$x" ; then
    echo "x is a boolean"
fi
```

---------------------------------------------------------------
<a name="lb_is_email"></a>
### lb_is_email
Test if a string is a valid email address.

#### Usage
```bash
lb_is_email STRING
```

#### Exit codes
- 0: Is an email address
- 1: Is not an email address

#### Example
```bash
x="me@domain.com"
if lb_is_email "$x" ; then
    echo "x is an email address"
fi
```

---------------------------------------------------------------
<a name="lb_is_comment"></a>
### lb_is_comment
Test if a text is a comment.

In source codes, comments are preceded by a symbol like `#`, `//`, ...

#### Usage
```bash
lb_is_comment [OPTIONS] TEXT
```
Note: you can also give `TEXT` argument using stdin or pipes.

#### Options
```
-s, --symbol STRING  Comment symbol (can use multiple values, '#' by default)
-n, --not-empty      Empty text are not considered as comments
```

#### Exit codes
- 0: Text is a comment
- 1: Usage error
- 2: Text is not a comment
- 3: Text is empty (if `--not-empty` option is set)

#### Example
```bash
# read config file without comments
while read line ; do
    if ! lb_is_comment $line ; then
        echo "$line"
    fi
done < "config.sh"
```

---------------------------------------------------------------
<a name="lb_trim"></a>
### lb_trim
Deletes spaces before and after a string.

#### Usage
```bash
lb_trim STRING
```
Note: you can also give `STRING` argument using stdin or pipes.

#### Exit codes
Exit code of the `echo` command.

#### Example
```bash
# get config line without spaces before and after text
config_line="    param='value with spaces'  "
config=$(lb_trim "$config_line")
```

---------------------------------------------------------------
<a name="lb_split"></a>
### lb_split
Split a string into array.

#### Usage
```bash
lb_split DELIMITER STRING
```

#### Exit codes
- 0: Split OK
- 1: Usage error

#### Example
```bash
users="john,peter"

lb_split , "$users"

for u in "${lb_split[@]}" ; do
	echo "User $u exists"
done
```

---------------------------------------------------------------
<a name="lb_join"></a>
### lb_join
Join an array into string.

#### Usage
```bash
lb_join DELIMITER "${ARRAY[@]}"
```
**Warning**: put your array between quotes or search will fail if you have
spaces in values.

#### Exit codes
- 0: Join OK
- 1: Usage error

#### Example
```bash
users=(john peter)
echo "Users: $(lb_join ", " "${users[@]}")"
```

---------------------------------------------------------------
<a name="lb_in_array"></a>
### lb_in_array
Check if an array contains a value.

Note: This function was called `lb_array_contains()` and has been renamed in
version 1.9.0. You can still use the old name because there is an alias for
compatibility, but it is no longer recommended.

#### Usage
```bash
lb_in_array VALUE "${ARRAY[@]}"
```
**Warning**: put your array between quotes or search will fail if you have
spaces in values.

#### Exit codes
- 0: Value is in array
- 1: Usage error
- 2: Value is NOT in array

#### Example
```bash
array=(one two three)
if lb_in_array one "${array[@]}" ; then
    echo "one is in array"
fi
```

---------------------------------------------------------------
<a name="lb_date2timestamp"></a>
### lb_date2timestamp
Convert a date into a timestamp.

#### Usage
```bash
lb_date2timestamp [OPTIONS] DATE
```

**Note: Date must be formatted in `YYYY-MM-DD HH:MM:SS`**

#### Options
```
-u, --utc  Date and timestamp are using UTC
```

#### Exit codes
- 0: Date converted
- 1: Usage error
- 2: Conversion error; date may be invalid

#### Example
```bash
timestamp=$(lb_date2timestamp '2017-12-31 23:59:59')
```

---------------------------------------------------------------
<a name="lb_timestamp2date"></a>
### lb_timestamp2date
Convert a timestamp to a date.

#### Usage
```bash
lb_timestamp2date [OPTIONS] TIMESTAMP
```

#### Options
```
-f, --format FORMAT  Specify a date format to return
-u, --utc            Timestamp and date are using UTC
```

Date formats: see the `date` command help for available formats; do not put the
`+` at the beginning.

#### Exit codes
- 0: Timestamp converted
- 1: Usage error
- 2: Conversion error; timestamp may be invalid

#### Example
```bash
date=$(lb_timestamp2date -f '%Y-%m-%d %H:%M:%S' 1514764799)
```

---------------------------------------------------------------
<a name="lb_compare_versions"></a>
### lb_compare_versions
Compare 2 software versions.

Versions must be in semantic versionning format (https://semver.org),
but the function can support incomplete versions
(e.g. 1.0 and 2 are converted to 1.0.0 and 2.0.0 respectively).

#### Usage
```bash
lb_compare_versions VERSION_1 OPERATOR VERSION_2
```

#### Options
```
VERSION_1  Software version
OPERATOR   Bash comparison pattern: -eq|-ne|-lt|-le|-gt|-ge
VERSION_2  Software version
```

#### Exit codes
- 0: Comparison OK
- 1: Usage error
- 2: Comparison NOT OK

#### Example
```bash
version1=2.0.1
version2=1.8.9
if lb_compare_versions $version1 -ge $version2 ; then
    echo "Newer version: $version1"
else
    echo "Newer version: $version2"
fi
```

---------------------------------------------------------------
## Filesystem
---------------------------------------------------------------
<a name="lb_df_fstype"></a>
### lb_df_fstype
Give the filesystem type of a partition.

#### Usage
```bash
lb_df_fstype PATH
```
Note: PATH may be any folder/file (not only mount points) or a device path (e.g. /dev/sda1)

#### Results
Results for each filesystem type:
- FAT16/FAT32:
    - Linux/Windows: `vfat`
    - macOS: `msdos`
- exFAT: `exfat` (for Linux systems without lsblk command, will return `fuseblk`)
- NTFS: `ntfs` (for Linux systems without lsblk command, will return `fuseblk`)
- HFS+:
    - Linux: `hfsplus`
    - macOS: `hfs`
    - Windows: **not supported**
- ext2/ext3/ext4:
    - Linux: `ext2`/`ext3`/`ext4`
    - macOS/Windows: **not supported**
- btrfs:
    - Linux: `btrfs`

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Given PATH does not exists
- 3: Unknown error

#### Example
```bash
root_fstype=$(lb_df_fstype /)
```

---------------------------------------------------------------
<a name="lb_df_space_left"></a>
### lb_df_space_left
Get space left on partition in kilobytes (1KB = 1024 bytes).

#### Usage
```bash
lb_df_space_left PATH
```
Note: PATH may be any folder/file (not only mount points) or a device path (e.g. /dev/sda1)

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Given PATH does not exists
- 3: Unknown error

#### Example
```bash
space_left=$(lb_df_space_left /)
```

---------------------------------------------------------------
<a name="lb_df_mountpoint"></a>
### lb_df_mountpoint
Get the mount point path of a partition.

#### Usage
```bash
lb_df_mountpoint PATH
```
Note: PATH may be any folder/file (not only mount points) or a device path (e.g. /dev/sda1)

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Given PATH does not exists
- 3: Unknown error

#### Example
```bash
mountpoint=$(lb_df_mountpoint /)
```

---------------------------------------------------------------
<a name="lb_df_uuid"></a>
### lb_df_uuid
Get the disk UUID for a given path.

**WARNING**: This function is not supported on BSD and Windows systems.

#### Usage
```bash
lb_df_uuid PATH
```
Note: PATH may be any folder/file (not only mount points) or a device path (e.g. /dev/sda1)

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Given PATH does not exists
- 3: Unknown error
- 4: Not supported

#### Example
```bash
disk_uuid=$(lb_df_uuid /media/usbkey)
```

---------------------------------------------------------------
## Files and directories
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
- 1: Home path not found

#### Example
```bash
home=$(lb_homepath)
```

---------------------------------------------------------------
<a name="lb_is_dir_empty"></a>
### lb_is_dir_empty
Test if a directory is empty.

Note: This function was called `lb_dir_is_empty()` and has been renamed in
version 1.9.0. You can still use the old name because there is an alias for
compatibility, but it is no longer recommended.

#### Usage
```bash
lb_is_dir_empty PATH
```

#### Exit codes
- 0: Directory is empty
- 1: Given PATH is not a directory
- 2: Access rights error
- 3: Directory is not empty

#### Example
```bash
# if directory is empty, delete it
if lb_is_dir_empty /empty/directory/ ; then
    rmdir /empty/directory/
fi
```

---------------------------------------------------------------
<a name="lb_abspath"></a>
### lb_abspath
Get the absolute path of a file or directory.

#### Usage
```bash
lb_abspath [OPTIONS] PATH
```

#### Options
```
-n, --no-test  Do not test if path exists (if an absolute path is given in argument)
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Cannot resolve path (parent directory does not exists)

#### Example
```bash
abs_path=$(lb_abspath file.txt)
```

---------------------------------------------------------------
<a name="lb_realpath"></a>
### lb_realpath
Get the real path of a file or directory.

- If the given path, it will return its absolute path.
- If the given path is a symbolic link, it will return the absolute path of the link target.
- If the given path has a parent directory that is a symbolic link, it will return the real absolute path.
- If a Windows path is given, it will be converted to Cygwin path

#### Usage
```bash
lb_realpath PATH
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Path not found

#### Example
```bash
real_path=$(lb_realpath /path/link_to_file)
```

---------------------------------------------------------------
<a name="lb_is_writable"></a>
### lb_is_writable
Test if a path (file or directory) is writable.

#### The weird Samba case
On Windows, this may fails if you are not owner on a network share file/folder.
We recommand you to do something like the following if you can be in this case:

```bash
if ! lb_is_writable "$logfile" ; then
	if [ "$(lb_df_fstype "$(dirname "$logfile")")" != smbfs ] ; then
		echo "File is not writable!"
	fi
fi
```

#### Usage
```bash
lb_is_writable PATH
```

#### Exit codes
- 0: Is writable (exists or can be created)
- 1: Usage error
- 2: Exists but is not writable
- 3: Does not exists and parent directory is not writable
- 4: Does not exists and parent directory does not exists

#### Example
```bash
# create file if pat his writable
if lb_is_writable /path/to/file ; then
    touch /path/to/file
fi
```

---------------------------------------------------------------
<a name="lb_edit"></a>
### lb_edit
Edit a file withe the `sed -i` command.

#### Usage
```bash
lb_edit PATTERN PATH
```

#### Exit codes
Exit codes are forwarded from the `sed` command.
See the sed manual for more information about them.

#### Example
```bash
# replace a by b in a file
lb_edit 's/a/b/g' myfile.txt
```

---------------------------------------------------------------
## System utilities
---------------------------------------------------------------
<a name="lb_current_os"></a>
### lb_current_os
Detect current operating system family.

#### Usage
```bash
lb_current_os
```

#### Results
Available results:
- BSD
- Linux
- macOS
- Windows

#### Example
```bash
case $(lb_current_os) in
		BSD)
				echo "You are on a BSD system."
				;;
		macOS)
        echo "You are on a macOS system."
        ;;
    Windows)
        echo "It seems you are on cygwin on Windows!"
        ;;
    *)
        echo "You are on a Linux system."
        ;;
esac
```

---------------------------------------------------------------
<a name="lb_current_uid"></a>
### lb_current_uid
Return current user ID.

#### Usage
```bash
lb_current_uid
```

#### Exit codes
- 0: UID returned
- 1: Unknown error

#### Example
```bash
my_uid=$(lb_current_uid)
```

---------------------------------------------------------------
<a name="lb_user_exists"></a>
### lb_user_exists
Test if an user exists.

#### Usage
```bash
lb_user_exists USER [USER...]
```

#### Exit codes
- 0: User(s) exists
- 1: User(s) does not exists

#### Example
```bash
if lb_user_exists darthvader ; then
    echo "Darth Vader rules your computer!"
fi
```

---------------------------------------------------------------
<a name="lb_ami_root"></a>
### lb_ami_root
Test if current user is root.

#### Usage
```bash
lb_ami_root
```

#### Exit codes
- 0: User is root
- 1: User is not root

#### Example
```bash
if lb_ami_root ; then
    apt-get install -y somepackage
else
    echo "You must be root to do that!"
fi
```
---------------------------------------------------------------
<a name="lb_in_group"></a>
### lb_in_group
Test if an user is member of a group.

#### Usage
```bash
lb_in_group GROUP [USER]
```

Note: if USER is not specified, current user is used

#### Exit codes
- 0: User is member of the group
- 1: Usage error
- 2: User is NOT member of the group
- 3: User does not exists

#### Example
```bash
if lb_in_group empire ; then
    echo "You are part of the empire."
fi
```

---------------------------------------------------------------
<a name="lb_group_exists"></a>
### lb_group_exists
Test if a group exists.

**WARNING**: This function is not supported on macOS and Windows systems.

#### Usage
```bash
lb_group_exists GROUP [GROUP...]
```

#### Exit codes
- 0: Group(s) exists
- 1: Group(s) does not exists
- 2: Not supported

#### Example
```bash
if lb_group_exists empire ; then
    echo "The empire strikes back!"
fi
```

---------------------------------------------------------------
<a name="lb_group_members"></a>
### lb_group_members
List users member of a group.

**WARNING**: This function is not supported on macOS and Windows systems.

#### Usage
```bash
lb_group_members GROUP
```

#### Exit codes
- 0: Members are returned
- 1: Usage error
- 2: Group does not exists
- 3: Not supported

#### Example
```bash
# get system administrators
administrators=(lb_group_members adm)
```

---------------------------------------------------------------
<a name="lb_generate_password"></a>
### lb_generate_password
Generate a random password.

#### Usage
```bash
lb_generate_password [SIZE]
```

#### Options
```
SIZE  Set the password size (16 by default; use value between 1 and 32)
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Unknown command error

#### Example
```bash
# generate a password of 12 characters
password=$(lb_generate_password 12)
```

---------------------------------------------------------------
<a name="lb_email"></a>
### lb_email
Send an email.

You must have sendmail installed and a proper SMTP server or relay configured.
You can install the `ssmtp` program (on Linux) to easely send emails via an existing account (like GMail or else).

**WARNING**: This function is not supported on Windows systems.

#### Usage
```bash
lb_email [OPTIONS] RECIPIENT[,RECIPIENT,...] MESSAGE
```
Note: you can also give `MESSAGE` argument using stdin or pipes.

#### Options
```
-s, --subject TEXT           Email subject
-r, --reply-to EMAIL         Email address to reply to
-c, --cc EMAIL[,EMAIL,...]   Add email addresses in the CC field
-b, --bcc EMAIL[,EMAIL,...]  Add email addresses in the BCC field
-a, --attachment PATH        Add attachments to the email
--sender EMAIL               Specify a sender email address
--html MESSAGE               Send a HTML version of the TEXT
--mail-command COMMAND       Use custom command to send email
                             (supported: /usr/bin/mail, /usr/sbin/sendmail)
```

#### Exit codes
- 0: Email sent
- 1: Usage error (or attachment does not exists)
- 2: No program available to send email
- 3: Unknown error from the program sender

#### Notes regarding email contents
To avoid bugs, be sure that you have correctly set your message and HTML body between quotes.
For example, if you import content from a file, call it like this: `"$(cat mail.txt)"`.

#### Example
```bash
lb_email --subject "Test" me@example.com "Hello, this is an email!"
```

---------------------------------------------------------------
## User interaction
---------------------------------------------------------------
<a name="lb_yesno"></a>
### lb_yesno
Ask a question to user to answer by yes or no.

#### Usage
```bash
lb_yesno [OPTIONS] TEXT
```

#### Options
```
-y, --yes            Set yes as default option
-c, --cancel         Add a cancel option
--yes-label TEXT     Label to use for "YES"
--no-label TEXT      Label to use for "NO"
--cancel-label TEXT  Label to use for cancel option
```

#### Exit codes
- 0: Yes
- 1: Usage error
- 2: No
- 3: Cancelled

#### Example
```bash
if ! lb_yesno "Do you want to continue?" ; then
    exit
fi
```

---------------------------------------------------------------
<a name="lb_choose_option"></a>
### lb_choose_option
Ask user to choose one or multiple options.

Chosen IDs are set into the `$lb_choose_option` (array) variable.

#### Usage
```bash
lb_choose_option [OPTIONS] CHOICE [CHOICE...]
```

#### Options
```
-d, --default ID[,ID...]  Option(s) to use by default (IDs starts to 1)
-m, --multiple            Allow user to choose between multiple options
-l, --label TEXT          Set a question label (default: "Choose an option:")
-c, --cancel-label TEXT   Set a cancel label (default: c)
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Cancelled
- 3: Bad choice

#### Example
```bash
if lb_choose_option --label "Choose a planet:" --default 1 Earth Jupiter ; then
    chosen_planet=$lb_choose_option
fi

if lb_choose_option --multiple --label "Choose valid countries:" --default 1,2 France USA Neverland ; then
    chosen_countries=(${lb_choose_option[@]})
fi
```

---------------------------------------------------------------
<a name="lb_input_text"></a>
### lb_input_text
Ask user to enter a text.

Input text is set into the `$lb_input_text` variable.

#### Usage
```bash
lb_input_text [OPTIONS] QUESTION_TEXT
```

#### Options
```
-d, --default TEXT  Default text
-n                  No line return after question
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: User entered an empty text (cancelled)

#### Example
```bash
if lb_input_text "Please enter your name:" ; then
    user_name=$lb_input_text
fi
```

---------------------------------------------------------------
<a name="lb_input_password"></a>
### lb_input_password
Ask user to enter a password.

Input password is set into the `$lb_input_password` variable.

#### Usage
```bash
lb_input_password [OPTIONS] [QUESTION_TEXT]
```

#### Options
```
-c, --confirm         Ask user to confirm password
--confirm-label TEXT  Set a label for the confirm question
-m, --min-size N      Force password to have at least N characters
QUESTION_TEXT         Set a label for the question
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Password is empty (cancelled)
- 3: Passwords mismatch
- 4: Password is too short (if `--min-size` option is set)

#### Example
```bash
# ask user password twice
if lb_input_password --confirm ; then
	user_password=$lb_input_password
fi
```

---------------------------------------------------------------
<a name="lb_say"></a>
### lb_say
Say something with text-to-speech.

#### Usage
```bash
lb_say TEXT
```

#### Exit codes
- 0: OK
- 1: Other error
- 2: No text-to-speech command found

#### Example
```bash
lb_say "Hello world!"
```

---------------------------------------------------------------

## License
libbash.sh is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for the full license text.

## Credits
Author: Jean Prunneaux https://jean.prunneaux.com

Website: https://github.com/pruje/libbash.sh
