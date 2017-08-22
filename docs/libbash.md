# libbash.sh documentation

## Introduction
libbash.sh is a library of functions to easely write bash scripts.

## Usage
Add libbash.sh to your script before using functions:
```bash
source "/path/to/libbash.sh"
```
Then call the functions described below.

If you want to use libbash.sh GUI, use the `--gui` option as argument when loading libbash:
```bash
source "/path/to/libbash.sh" --gui
```

By default, libbash.sh translation is loaded in the user language. You can specify a language with the `--lang` option:
```bash
source "/path/to/libbash.sh" --lang fr
```

Supported languages:
- `en`: English (default)
- `fr`: French

## Variables
You can use the following variables that are initialized when you include libbash.sh in your scripts:
- `$lb_version`: the current libbash.sh version
- `$lb_path`: path of libbash.sh
- `$lb_directory`: libbash.sh directory
- `$lb_current_script`: path of your current script (same as `$0`)
- `$lb_current_script_name`: name of your current script (same as `basename "$0"`)
- `$lb_current_script_directory`: directory of your current script (same as `dirname "$0"`)
- `$lb_current_path`: your current path (same as `pwd`)
- `$lb_current_os`: your current Operating System (result of `lb_current_os` function)
- `$lb_current_user`: your user name (same as `whoami`)
- `$lb_exitcode`: script exit code (0 by default) that will be send if using `lb_exit` (same as `exit $lb_exitcode`)
- `$lb_exit_cmd`: array that contains a command to execute when `lb_exit()` function is called (empty by default)

## Functions
All functions are named with the `lb_` prefix.
Functions with a `*` are not fully supported on every OS yet (may change in the future).

* Bash utilities
	* [lb_command_exists](#lb_command_exists)
	* [lb_function_exists](#lb_function_exists)
	* [lb_test_arguments](#lb_test_arguments)
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
* Operations on variables
	* [lb_is_number](#lb_is_number)
	* [lb_is_integer](#lb_is_integer)
	* [lb_is_boolean](#lb_is_boolean)
	* [lb_is_email](#lb_is_email)
	* [lb_is_comment](#lb_is_comment)
	* [lb_trim](#lb_trim)
	* [lb_array_contains](#lb_array_contains)
	* [lb_compare_versions](#lb_compare_versions)
* Filesystem
	* [lb_df_fstype](#lb_df_fstype)
	* [lb_df_space_left](#lb_df_space_left)
	* [lb_df_mountpoint](#lb_df_mountpoint)
	* [lb_df_uuid](#lb_df_uuid)*
* Files and directories
	* [lb_homepath](#lb_homepath)
	* [lb_dir_is_empty](#lb_dir_is_empty)
	* [lb_abspath](#lb_abspath)
	* [lb_realpath](#lb_realpath)
	* [lb_is_writable](#lb_is_writable)
* System utilities
	* [lb_current_os](#lb_current_os)
	* [lb_user_exists](#lb_user_exists)
	* [lb_in_group](#lb_in_group)
	* [lb_generate_password](#lb_generate_password)
	* [lb_email](#lb_email)
* User interaction
	* [lb_yesno](#lb_yesno)
	* [lb_choose_option](#lb_choose_option)
	* [lb_input_text](#lb_input_text)
	* [lb_input_password](#lb_input_password)

---------------------------------------------------------------
## Bash utilities
---------------------------------------------------------------
<a name="lb_command_exists"></a>
### lb_command_exists
Check if a command exists.
Works for commands, functions and executable files.

#### Usage
```bash
lb_command_exists COMMAND
```

#### Exit codes
- 0: Command exists
- 1: Usage error
- 2: Command does not exists

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
- 0: Function exists
- 1: Usage error
- 2: Function does not exists
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
<a name="lb_test_arguments"></a>
### lb_test_arguments
Test number of arguments passed to a script/function.

Note: A common usage of this function would be `lb_test_arguments -ge 1 $*`
to test if user has passed at least one argument to your script/function.

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
- 0: Arguments OK
- 1: Usage error
- 2: Arguments not OK

#### Example
```bash
if lb_test_arguments -lt 2 $* ; then
    echo "You have to give at least 2 arguments to this script."
fi
```

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
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Logs could not be written
- 3: Unknown error while printing

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
Manage a command result code and print a label to the console to indicate if a command succeeded or failed.

#### Usage
```bash
lb_result [OPTIONS] [EXIT_CODE]
```

#### Options
```
--ok-label LABEL           Set a success label (default: OK)
--failed-label LABEL       Set a failed label (default: FAILED)
--log                      Append text to log file
-l, --log-level LEVEL      Choose a display level (will be the same for logs)
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

It uses the `lb_result` function with `--ok-label [  OK  ]` and `--failed-label [ FAILED ]` options.

#### Usage
```bash
lb_short_result [OPTIONS] [EXIT_CODE]
```

#### Options
```
--log                      Append text to log file
-l, --log-level LEVEL      Choose a display level (will be the same for logs)
-s, --save-exitcode        Save the result to the $lb_exitcode variable
-e, --error-exitcode CODE  Set a custom code to the $lb_exitcode variable if error
-x, --exit-on-error        Exit if result is not ok (exit code not to 0)
-q, --quiet                Do not print anything

EXIT_CODE                  Specify an exit code. If not set, variable $? will be used
```

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
Set path of the log file.

#### Usage
```bash
lb_set_logfile [OPTIONS] PATH
```

#### Options
```
-a, --append     Append to the file if exists
-x, --overwrite  Overwrite file if exists
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
x="-42.9"
if lb_is_number $x ; then
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
x="-1"
if lb_is_integer $x ; then
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
if lb_is_boolean $x ; then
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
if lb_is_email $x ; then
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
Deletes spaces before and after a text.

#### Usage
```bash
lb_trim TEXT
```

#### Exit codes
Exit code of the `echo` command.

#### Example
```bash
# get config line without spaces before and after text
config_line="    param='value with spaces'  "
config=$(lb_trim "$config_line")
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
- 0: Value is in array
- 1: Usage error
- 2: Value is NOT in array

#### Example
```bash
array=(one two three)
if lb_array_contains "one" "${array[@]}" ; then
    echo "one is in array"
fi
```

---------------------------------------------------------------
<a name="lb_compare_versions"></a>
### lb_compare_versions
Compare 2 software versions.

Versions must be in semantic versionning format (http://semver.org),
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
version1="2.0.1"
version2="1.8.9"
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
- exFAT: `exfat`
- NTFS: `ntfs`
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
Get space left on partition in bytes.

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

**WARNING**: This function is not supported yet on Windows.

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
<a name="lb_dir_is_empty"></a>
### lb_dir_is_empty
Test if a directory is empty.

#### Usage
```bash
lb_dir_is_empty PATH
```

#### Exit codes
- 0: Directory is empty
- 1: Given PATH is not a directory
- 2: Access rights error
- 3: Directory is not empty

#### Example
```bash
# if directory is empty, delete it
if lb_dir_is_empty /empty/directory/ ; then
    rmdir /empty/directory/
fi
```

---------------------------------------------------------------
<a name="lb_abspath"></a>
### lb_abspath
Get the absolute path of a file or directory.

#### Usage
```bash
lb_abspath PATH
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
- Linux
- macOS
- Windows

#### Example
```bash
case $(lb_current_os) in
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
<a name="lb_user_exists"></a>
### lb_user_exists
Test if an user exists.

#### Usage
```bash
lb_user_exists USER
```

#### Exit codes
- 0: User exists
- 1: Usage error
- 2: User does not exists

#### Example
```bash
if lb_user_exists darthvader ; then
    echo "Darth Vader rules your computer!"
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

#### Usage
```bash
lb_email [OPTIONS] RECIPIENT[,RECIPIENT,...] MESSAGE
```

#### Options
```
-s, --subject TEXT           Email subject
--sender EMAIL               Sender email address
-r, --reply-to EMAIL         Email address to reply to
-c, --cc EMAIL[,EMAIL,...]   Add email addresses in the CC field
-b, --bcc EMAIL[,EMAIL,...]  Add email addresses in the BCC field
```

#### Exit codes
- 0: Email sent
- 1: Usage error
- 2: No program available to send email
- 3: Unknown error from the program sender

#### Example
```bash
lb_email --subject "Test" me@example.com "Hello, this is a message!"
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
Ask user to choose an option.

The chosen ID is set into the `$lb_choose_option` variable.

#### Usage
```bash
lb_choose_option [OPTIONS] CHOICE [CHOICE...]
```

#### Options
```
-d, --default ID         Option to use by default (IDs starts to 1)
-l, --label TEXT         Set a label question (default: "Choose an option:")
-c, --cancel-label TEXT  Set a cancel label (default: c)
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Cancelled
- 3: Bad choice

#### Example
```bash
if lb_choose_option --label "Choose a country:" --default 1 "France" "USA" "Other" ; then
    chosen_country=$lb_choose_option
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
    user_name="$lb_input_text"
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
	user_password="$lb_input_password"
fi
```

---------------------------------------------------------------

## License
libbash.sh is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for the full license text.

## Credits
Author: Jean Prunneaux  [http://jean.prunneaux.com](http://jean.prunneaux.com)

Website: [https://github.com/pruje/libbash.sh](https://github.com/pruje/libbash.sh)
