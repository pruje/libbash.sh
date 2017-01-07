# libbash.sh documentation

## Introduction
libbash.sh is a library of functions to easely write bash scripts.

## Usage
Add libbash.sh to your script before using functions:
```bash
source "/path/to/libbash.sh"
```
Then call the functions described below.

## Functions documentation
All functions are named with the `lb_` prefix.
Functions with a `*` are not fully supported on every OS yet (may change in the future).

* Basic bash functions
	* [lb_command_exists](#lb_command_exists)
	* [lb_function_exists](#lb_function_exists)
	* [lb_test_arguments](#lb_test_arguments)
* Display
	* [lb_print, lb_echo](#lb_print)
	* [lb_error](#lb_error)
	* [lb_display](#lb_display)
	* [lb_display_critical, lb_display_error, lb_display_warning, lb_display_info, lb_display_debug](#lb_display_presets)
	* [lb_print_result, lb_result](#lb_print_result)
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

---------------------------------------------------------------
## Basic bash functions
---------------------------------------------------------------
<a name="lb_command_exists"></a>
### lb_command_exists
Check if a command exists.

#### Usage
```bash
lb_command_exists COMMAND
```

#### Exit codes
- 0: command exists
- 1: command does not exists
- 255: usage error

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

---------------------------------------------------------------
<a name="lb_test_arguments"></a>
### lb_test_arguments
Test number of arguments passed to a function.

#### Usage
```bash
lb_test_arguments OPERATOR N [VALUE...]
```
e.g. `lb_test_arguments -ge 1 $*`: test if user has passed at least one argument to your script.

#### Arguments
```
OPERATOR  common bash comparison pattern: -eq|-ne|-lt|-le|-gt|-ge
N         expected number to compare to
VALUE     your arguments; (e.g. $* without quotes)
```

#### Exit codes
- 0: OK
- 1: not OK
- 255: usage error

---------------------------------------------------------------
## Display
---------------------------------------------------------------
<a name="lb_print"></a>
### lb_print, lb_echo
Print a message to the console, with colors and formatting

#### Usage
```bash
lb_print [OPTIONS] TEXT
```
or
```bash
lb_echo [OPTIONS] TEXT
```

#### macOS and console formatting
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

---------------------------------------------------------------
<a name="lb_error"></a>
### lb_error
Print a message to the console, with colors and formatting, redirected to stderr.
For more informations, see `lb_print` documentation.

#### Usage
```bash
lb_error [OPTIONS] TEXT
```
Options are the same than the [lb_print](#lb_print) function.

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
Exit code of the [lb_print](#lb_print) command.

---------------------------------------------------------------
<a name="lb_display_presets"></a>
### lb_display_critical, lb_display_error, lb_display_warning, lb_display_info, lb_display_debug
Shortcuts to display with common log levels.

It uses the `lb_display` function with `--prefix` and `--level` options.

For more informations, see [lb_display](#lb_display) documentation.

---------------------------------------------------------------
<a name="lb_print_result"></a>
### lb_print_result, lb_result
Print a result label to the console to indicate if a command succeeded or failed.

#### Usage
```bash
lb_print_result [OPTIONS] [EXIT_CODE]
```
or
```bash
lb_result [OPTIONS] [EXIT_CODE]
```

#### Options
```
--ok-label LABEL       Set a ok label
--failed-label LABEL   Set a failed label
--log                  Append result to log file
-l, --log-level LEVEL  Choose a display level (will be the same for logs)
-x, --error-on-exit    Exit if result is not ok (exit code not to 0)

EXIT_CODE              Specify an exit code. If not set, variable $? will be used.
```

#### Exit codes
Exit code forwarded of the last command or specified in argument.

---------------------------------------------------------------
<a name="lb_short_result"></a>
### lb_short_result
Print a short result label to the console to indicate if a command succeeded or failed.

It uses the `lb_print_result` function with `--ok-label [  OK  ]` and `--failed-label [ FAILED ]` options.

For more informations, see [lb_print_result](#lb_print_result) documentation.

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
0: OK
1: Log file is not set
2: Log file is not writable

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
0: Log file set
1: Usage error
2: Log file cannot be created or is not writable
3: Log file already exists, but append option is not set
4: Path exists but is not a regular file

---------------------------------------------------------------
<a name="lb_get_loglevel"></a>
### lb_get_loglevel
Get current log level.

See [lb_set_loglevel](#lb_set_loglevel) for more details on default log levels.

#### Usage
```bash
lb_get_loglevel [OPTIONS]
```

#### Options
```
--id  Get log level ID instead of its name
```

#### Exit codes
0: OK
1: Log level is not set
2: Current log level not found

---------------------------------------------------------------
<a name="lb_set_loglevel"></a>
### lb_set_loglevel
Set a log level.

#### Usage
```bash
lb_set_loglevel LEVEL
```

#### Log levels
Default log levels are:
0. CRITICAL
1. ERROR
2. WARNING
3. INFO
4. DEBUG

The default log level is DEBUG, which means that it displays and logs every levels.

Please note that if you set a log level, every messages with a lower level will also be displayed/logged.

If you display/log a message with an unknown log level, it will always be displayed/logged.

#### Exit codes
0: Log level set
1: Usage error
2: Specified log level not found

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
0: OK
1: Log file is not set
2: Error while writing into file

---------------------------------------------------------------
<a name="lb_log_presets"></a>
### lb_log_critical, lb_log_error, lb_log_warning, lb_log_info, lb_log_debug
Shortcuts to log with common log levels.

It uses the `lb_log` function with `--prefix` and `--level` options.

For more informations, see [lb_log](#lb_log) documentation.

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
- 0: is integer
- 1: is not integer

---------------------------------------------------------------
<a name="lb_array_contains"></a>
### lb_array_contains
Check if an array contains a value.

**Warning: put your array between quotes or search will fail if you have spaces in values.**

#### Usage
```bash
lb_array_contains VALUE "${ARRAY[@]}"
```

#### Exit codes
- 0: value was found in array
- 1: usage error
- 2: value is NOT in array

---------------------------------------------------------------
<a name="lb_df_fstype"></a>
### lb_df_fstype
Give the filesystem type of a path.

**NOT COMPATIBILE YET WITH macOS**

#### Usage
```bash
myfilesystem=$(lb_df_fstype PATH)
```

#### Exit codes
- 0: OK
- 1: error
- 2: usage error
