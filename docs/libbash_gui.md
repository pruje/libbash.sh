# libbash.sh GUI documentation

## Introduction
libbash.sh GUI features some functions to display dialogs and notifications for scripts with graphical interfaces.

## GUI tools
GUI tools are commands used to display GUI dialogs and notifications to the user.

libbash.sh GUI currently supports the following GUI tools:
- kdialog
- zenity
- osascript (Apple script for macOS)
- dialog

## Usage
libbash.sh GUI needs to be included **after** libbash:
```bash
source "/path/to/libbash.sh"
source "/path/to/libbash_gui.sh"
```
Then call the functions described below.

**Note:** The `libash_gui.sh` file does not need to be in the same directory than `libbash.sh`.

## Functions documentation
All functions are named with the `lbg_` prefix.
Functions with a `*` are not fully supported on every OS yet (may change in the future).

* GUI tools
	* [lbg_get_gui](#lbg_get_gui)
	* [lbg_set_gui](#lbg_set_gui)
* Messages and notifications
	* [lbg_display_info](#lbg_display_info)
	* [lbg_display_warning](#lbg_display_warning)
	* [lbg_display_error](#lbg_display_error)
	* [lbg_display_critical](#lbg_display_critical)
	* [lbg_display_debug](#lbg_display_debug)
	* [lbg_notify](#lbg_notify)
* User interaction
	* [lbg_yesno](#lbg_yesno)
	* [lbg_choose_option](#lbg_choose_option)
	* [lbg_input_text](#lbg_input_text)
	* [lbg_input_password](#lbg_input_password)
	* [lbg_choose_directory](#lbg_choose_directory)
	* [lbg_choose_file](#lbg_choose_file)

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
- 1: no GUI tool available on this system

#### Example
```bash
gui_tool=$(lbg_get_gui)
```

---------------------------------------------------------------
<a name="lbg_set_gui"></a>
### lbg_set_gui
Specify a GUI tool to be used (see the supported tools above).
By default, the first tool available in the list is used.

e.g. if `kdialog` and `zenity` are installed, `kdialog` will be used over `zenity`,
that's why you can set `zenity` if you prefer.

#### Usage
```bash
lbg_set_gui GUI_TOOL
```

#### Exit codes
- 0: GUI tool set
- 1: usage error
- 2: GUI tool not supported
- 3: GUI tool not available on this system
- 4: GUI tool available, but no X server is currently running (stay in console mode)

#### Example
```bash
if lbg_set_gui zenity ; then
	echo "Using zenity for dialogs."
fi
```

---------------------------------------------------------------
<a name="lbg_display_info"></a>
### lbg_display_info
Display an info dialog.

#### Usage
```bash
lbg_display_info [OPTIONS] TEXT
```

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
lbg_display_info "This is an info message."
```

---------------------------------------------------------------
<a name="lbg_display_warning"></a>
### lbg_display_warning
Displays a warning dialog.

#### Usage
```bash
lbg_display_warning [OPTIONS] TEXT
```

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
lbg_display_warning "This is a warning message."
```

---------------------------------------------------------------
<a name="lbg_display_error"></a>
### lbg_display_error
Displays an error dialog.

#### Usage
```bash
lbg_display_error [OPTIONS] TEXT
```

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
### lbg_display_critical
Displays a critical error dialog.

#### Usage
```bash
lbg_display_critical [OPTIONS] TEXT
```

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
lbg_display_critical "This is a critical error message."
```

---------------------------------------------------------------
<a name="lbg_display_debug"></a>
### lbg_display_debug
Displays a debug info dialog.

#### Usage
```bash
lbg_display_debug [OPTIONS] TEXT
```

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
lbg_display_debug "This is a debug message."
```

---------------------------------------------------------------
<a name="lbg_notify"></a>
### lbg_notify
Displays a notification.

#### Usage
```bash
lbg_notify [OPTIONS] TEXT
```

#### notify-send
On Linux systems, the `notify-send` command is used by default over kdialog or zenity commands.
We choosed it because it is more powerful and have a better integration on every desktop environments.
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
- Dialog exit codes are forwarded
- 1: usage error

#### Example
```bash
lbg_notify "This is a notification."
```

---------------------------------------------------------------
<a name="lbg_yesno"></a>
### lbg_yesno
Displays a dialog to ask a question to user.

#### Usage
```bash
lbg_yesno [OPTIONS] TEXT
```

#### Options
```
-y, --yes         Set Yes as selected button (not available on kdialog and zenity)
--yes-label TEXT  Change Yes label (not available on zenity)
--no-label TEXT   Change No label (not available on zenity)
-t, --title TEXT  Set a title to the dialog
```

#### Exit codes
- 0: yes
- 1: usage error
- 2: no
- 3: cancelled

#### Example
```bash
if ! lbg_yesno "Do you want to continue?" ; then
	exit
fi
```

---------------------------------------------------------------
<a name="lbg_input_text"></a>
### lbg_input_text
Displays a dialog to ask user to input a text.

#### Usage
```bash
lbg_input_text [OPTIONS] TEXT
```
Result is stored into the `$lbg_input_text` variable.

#### Options
```
-d, --default TEXT  Default value
-t, --title TEXT    Set a title to the dialog
```

#### Exit codes
- 0: OK
- 1: usage error
- 2: cancelled

#### Example
```bash
if lbg_input_text "Please enter your name:" ; then
	user_name="$lbg_input_text"
fi
```

---------------------------------------------------------------
<a name="lbg_input_password"></a>
### lbg_input_password
Displays a dialog to ask user to input a password.

#### Usage
```bash
lbg_input_password [OPTIONS]
```
Result is stored into the `$lbg_input_password` variable.

#### Options
```
-l, --label TEXT      Change label (not available on zenity)
-c, --confirm         Display a confirm password dialog
--confirm-label TEXT  Change confirmation label (not available on zenity)
-t, --title TEXT      Set a title to the dialog
```

#### Exit codes
- 0: OK
- 1: usage error
- 2: cancelled
- 3: passwords mismatch

#### Example
```bash
if lbg_input_password ; then
	user_password="$lbg_input_password"
fi
```
