# libbash.sh GUI documentation

## Introduction
libbash.sh GUI features some functions to display dialogs and notifications for scripts with graphical interfaces.

## GUI tools
GUI tools are commands used to display GUI dialogs and notifications to the user.

libbash.sh GUI currently supports the following GUI tools:
- kdialog
- zenity
- osascript (Apple script for macOS)
- cscript (VBscript for Windows)
- dialog

## Usage
libbash.sh GUI needs to be included **after** libbash:
```bash
source "/path/to/libbash.sh"
source "/path/to/libbash_gui.sh"
```
Then call the functions described below.

**Note**: The `libash_gui.sh` file does not need to be in the same directory than `libbash.sh`.

## The case of cron jobs (on Linux)
If you plan to execute a script from a cron job, dialogs (like notifications) may no be printed.
It's because the `$DISPLAY` variable is not set in the cron job context.

To avoid that, you have to manually set the DISPLAY variable in your script with the command:
```bash
export DISPLAY=":0"
```

You can get users current display with the following command (replace `myuser` by your user):
```bash
who | grep "^myuser .*(:[0-9])$" | head -1 | sed "s/.*(\(:[0-9]*\))$/\1/g"
```

**Note**: If you set the DISPLAY variable AFTER integrate libbash GUI, then you have to reset the GUI tool with calling the `lbg_set_gui` function (see usage below).

## Variables
You can use the following variables that are initialized when you include libbash_gui.sh in your scripts:
- `$lbg_path`: the current path of libbash GUI

## Functions
All functions are named with the `lbg_` prefix.
Functions with a `*` are not fully supported on every OS yet (may change in the future).

* GUI tools
	* [lbg_get_gui](#lbg_get_gui)
	* [lbg_set_gui](#lbg_set_gui)
* Messages and notifications
	* [lbg_display_info, lbg_info](#lbg_display_info)
	* [lbg_display_warning, lbg_warning](#lbg_display_warning)
	* [lbg_display_error, lbg_error](#lbg_display_error)
	* [lbg_display_critical, lbg_critical](#lbg_display_critical)
	* [lbg_display_debug, lbg_debug](#lbg_display_debug)
	* [lbg_notify](#lbg_notify)*
* User interaction
	* [lbg_yesno](#lbg_yesno)
	* [lbg_choose_option](#lbg_choose_option)
	* [lbg_input_text](#lbg_input_text)
	* [lbg_input_password](#lbg_input_password)*
* Files and directories
	* [lbg_choose_directory](#lbg_choose_directory)*
	* [lbg_choose_file](#lbg_choose_file)*
	* [lbg_open_directory](#lbg_open_directory)

---------------------------------------------------------------
## GUI tools
---------------------------------------------------------------
<a name="lbg_get_gui"></a>
### lbg_get_gui
Get the current GUI tool name (see available tools above).

#### Usage
```bash
lbg_get_gui
```

#### Exit codes
- 0: OK
- 1: No GUI tool available on this system

#### Example
```bash
gui_tool=$(lbg_get_gui)
```

---------------------------------------------------------------
<a name="lbg_set_gui"></a>
### lbg_set_gui
Set a GUI tool to be used (see the supported tools above).

By default, the first tool available in the list is used. If no tool specified,
the default one will be set.
If multiple tools are given, the first available will be set.

e.g. if `kdialog` and `zenity` are installed, `kdialog` will be used over `zenity`,
that's why you can set `zenity` if you prefer.

#### Usage
```bash
lbg_set_gui [GUI_TOOL...]
```

#### Exit codes
- 0: GUI tool set
- 1: GUI tool not supported
- 3: GUI tool not available on this system
- 4: GUI tool available, but no X server is currently running (stay in console mode)

#### Example
```bash
if lbg_set_gui zenity ; then
    echo "Using zenity for dialogs."
fi
```

---------------------------------------------------------------
## Messages and notifications
---------------------------------------------------------------
<a name="lbg_display_info"></a>
### lbg_display_info, lbg_info
Display an info message dialog.

#### Usage
```bash
lbg_display_info [OPTIONS] TEXT
```
or
```bash
lbg_info [OPTIONS] TEXT
```
Note: you can also give `TEXT` argument using stdin or pipes.

#### Options
```
-t, --title TEXT  Set a title to the dialog
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Unknown dialog error

#### Example
```bash
lbg_info "This is an info message."
```

---------------------------------------------------------------
<a name="lbg_display_warning"></a>
### lbg_display_warning, lbg_warning
Displays a warning message dialog.

#### Usage
```bash
lbg_display_warning [OPTIONS] TEXT
```
or
```bash
lbg_warning [OPTIONS] TEXT
```
Note: you can also give `TEXT` argument using stdin or pipes.

#### Options
```
-t, --title TEXT  Set a title to the dialog
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Unknown dialog error

#### Example
```bash
lbg_warning "This is a warning message."
```

---------------------------------------------------------------
<a name="lbg_display_error"></a>
### lbg_display_error, lbg_error
Displays an error message dialog.

#### Usage
```bash
lbg_display_error [OPTIONS] TEXT
```
or
```bash
lbg_error [OPTIONS] TEXT
```
Note: you can also give `TEXT` argument using stdin or pipes.

#### Options
```
-t, --title TEXT  Set a title to the dialog
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Unknown dialog error

#### Example
```bash
lbg_display_error "This is an error message."
```

---------------------------------------------------------------
<a name="lbg_display_critical"></a>
### lbg_display_critical, lbg_critical
Displays a critical error mesage dialog.

#### Usage
```bash
lbg_display_critical [OPTIONS] TEXT
```
or
```bash
lbg_critical [OPTIONS] TEXT
```
Note: you can also give `TEXT` argument using stdin or pipes.

#### Options
```
-t, --title TEXT  Set a title to the dialog
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Unknown dialog error

#### Example
```bash
lbg_critical "This is a critical error message."
```

---------------------------------------------------------------
<a name="lbg_display_debug"></a>
### lbg_display_debug, lbg_debug
Displays a debug info message dialog.

#### Usage
```bash
lbg_display_debug [OPTIONS] TEXT
```
or
```bash
lbg_debug [OPTIONS] TEXT
```
Note: you can also give `TEXT` argument using stdin or pipes.

#### Options
```
-t, --title TEXT  Set a title to the dialog
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Unknown dialog error

#### Example
```bash
lbg_debug "This is a debug message."
```

---------------------------------------------------------------
<a name="lbg_notify"></a>
### lbg_notify
Displays a notification popup.

**WARNING**: System notifications are not displayed on Windows yet (messages are displayed in console).

#### Usage
```bash
lbg_notify [OPTIONS] TEXT
```
Note: you can also give `TEXT` argument using stdin or pipes.

#### notify-send
On Linux systems, the `notify-send` command is used by default over `zenity --notification` command.
We chose it because it is more powerful and have a better integration on every desktop environments.
But if you want, you can use the `--no-notify-send` option to not use it and use your chosen GUI tool.

#### Options
```
-t, --title TEXT   Set a title to the notification
--timeout SECONDS  Timeout before notification disapears (if not set, use default system)
                   This option is NOT available on macOS
--no-notify-send   Do not use the notify-send command if exists*
```

\* See above for more details

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Notification command error

#### Example
```bash
lbg_notify --timeout 5 "This notification will disapper in 5 seconds..."
```

---------------------------------------------------------------
## User interaction
---------------------------------------------------------------
<a name="lbg_yesno"></a>
### lbg_yesno
Displays a dialog to ask a question to answer by yes or no.

#### Usage
```bash
lbg_yesno [OPTIONS] TEXT
```

#### Options
```
-y, --yes         Set Yes as default button (not available on kdialog and zenity)
--yes-label TEXT  Change Yes label (not available on zenity and Windows)
--no-label TEXT   Change No label (not available on zenity and Windows)
-t, --title TEXT  Set a title to the dialog
```

#### Exit codes
- 0: Yes
- 1: Usage error
- 2: No

#### Example
```bash
if ! lbg_yesno "Do you want to continue?" ; then
    exit
fi
```

---------------------------------------------------------------
<a name="lbg_choose_option"></a>
### lbg_choose_option
Displays a dialog to ask user to choose one or multiple options.

Chosen IDs are set into the `$lbg_choose_option` (array) variable.

#### Usage
```bash
lbg_choose_option [OPTIONS] CHOICE [CHOICE...]
```

#### Options
```
-d, --default ID[,ID...]  Option(s) to use by default (IDs starts to 1)
-m, --multiple            Allow user to choose between multiple options
-l, --label TEXT          Set a question label (default: "Choose an option:")
-t, --title TEXT          Set a title to the dialog
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Cancelled
- 3: Bad choice

#### Example
```bash
if lbg_choose_option --label "Choose a planet:" --default 1 Earth Jupiter ; then
    chosen_planet=$lbg_choose_option
fi

if lbg_choose_option --multiple --label "Choose valid countries:" --default 1,2 France USA Neverland ; then
    chosen_countries=(${lbg_choose_option[@]})
fi
```

---------------------------------------------------------------
<a name="lbg_input_text"></a>
### lbg_input_text
Displays a dialog to ask user to input a text.

Input text is stored into the `$lbg_input_text` variable.

#### Usage
```bash
lbg_input_text [OPTIONS] TEXT
```

#### Options
```
-d, --default TEXT  Default value
-t, --title TEXT    Set a title to the dialog
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Cancelled

#### Example
```bash
if lbg_input_text --default $(whoami) "Please enter your username:" ; then
    user_name=$lbg_input_text
fi
```

---------------------------------------------------------------
<a name="lbg_input_password"></a>
### lbg_input_password
Displays a dialog to ask user to input a password.

**WARNING**: No password dialog is displayed on Windows (prompt in console).

#### Usage
```bash
lbg_input_password [OPTIONS] [QUESTION_TEXT]
```
Password is stored into the `$lbg_input_password` variable.

#### Options
```
-c, --confirm         Display a confirm password dialog
--confirm-label TEXT  Set the confirmation label (not available on zenity)
-m, --min-size N      Force password to have at least N characters
-t, --title TEXT      Set a title for the dialog
QUESTION_TEXT         Set a label for the question (not available on zenity)
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Cancelled
- 3: Passwords mismatch
- 4: Password is too short (if `--min-size` option is set)

#### Example
```bash
if lbg_input_password ; then
    user_password=$lbg_input_password
fi
```

---------------------------------------------------------------
## Files and directories
---------------------------------------------------------------
<a name="lbg_choose_directory"></a>
### lbg_choose_directory
Displays a dialog to choose an existing directory.

Path of the chosen directory is set into the `$lbg_choose_directory` variable.

#### Usage
```bash
lbg_choose_directory [OPTIONS] [PATH]
```

#### Options
```
-a, --absolute-path  Return absolute path of the directory
-t, --title TEXT     Set a title to the dialog
PATH                 Starting path (current directory by default)
```

**WARNING**: On Windows, starting path is not working with cscript dialogs (but works in console mode).

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Cancelled
- 3: Chosen path does not exists or is not a directory

#### Example
```bash
if lbg_choose_directory /opt ; then
    opt_path=$lbg_choose_directory
fi
```

---------------------------------------------------------------
<a name="lbg_choose_file"></a>
### lbg_choose_file
Displays a dialog to choose an existing file.

Path of the chosen file is set into the `$lbg_choose_file` variable.

**WARNING**: This function is not supported on Windows with cscript (but works in console mode).

#### Usage
```bash
lbg_choose_file [OPTIONS] [PATH]
```

#### Options
```
-s, --save           Save mode (create/save a file instead of open an existing one)
-f, --filter FILTER  Set file filters
                     e.g. -f "*.jpg" to filter by JPEG files
-a, --absolute-path  Return absolute path of the file
-t, --title TEXT     Set a title to the dialog
PATH                 Starting path or default file path (open current directory by default)
```

**WARNING**: File filters are not supported yet with dialog command neither with macOS osascript dialogs.

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Cancelled
- 3: Chosen path does not exists or is not a file (if open mode) or invalid parent directory (if save mode)
- 4: Cannot get absolute path of the file*

\* In this case, you can, however, retrieve the chosen path in the `$lbg_choose_file` variable.

#### Example
```bash
if lbg_choose_file --filter "*.txt" ; then
    text_file="$lbg_choose_file"
fi
```

---------------------------------------------------------------
<a name="lbg_open_directory"></a>
### lbg_open_directory
Open directories in a graphical file browser.

#### Usage
```bash
lbg_choose_directory [OPTIONS] [PATH...]
```

#### Options
```
-e, --explorer CMD  Open directory with a custom application
PATH                Directory path (current directory by default)
```

#### Exit codes
- 0: OK
- 1: Usage error
- 2: Explorer command does not exists
- 3: Unknown error (happens often on Windows)
- 4: One or more of the specified paths are not existing directories

**Note**: On some OS like Windows, this function may work but return a bad exit code.

#### Example
```bash
# open home directory
lbg_open_directory ~
```

---------------------------------------------------------------

## License
libbash.sh is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for the full license text.

## Credits
Author: Jean Prunneaux  [http://jean.prunneaux.com](http://jean.prunneaux.com)

Website: [https://github.com/pruje/libbash.sh](https://github.com/pruje/libbash.sh)
