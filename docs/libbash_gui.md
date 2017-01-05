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

## Functions
All libbash.sh GUI functions are named with the `lbg_` prefix. See documentation below for each function.

### Table of content
* Environment settings
	* [lbg_get_gui](#lbg_get_gui)
	* [lbg_test_gui](#lbg_test_gui)
	* [lbg_set_gui](#lbg_set_gui)
* User interaction
	* [lbg_yesno](#lbg_yesno)
	* [lbg_input_password](#lbg_input_password2)

---------------------------------------------------------------
<a name="lbg_get_gui"></a>
### lbg_get_gui
Get the current GUI tool name (see available tools above).

#### Usage
```bash
my_gui_tool=$(lbg_get_gui)
```

#### Exit codes
- 0: OK
- 1: no GUI tool available on the system

---------------------------------------------------------------
<a name="lbg_test_gui"></a>
### lbg_test_gui
Test if a GUI tool is available on your system (see the supported tools above).

#### Usage
```bash
lbg_test_gui GUI_TOOL
```

#### Exit codes
- 0: GUI tool ready to be used
- 1: usage error
- 2: GUI tool not available on the system

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
- 2: GUI tool not available on the system

---------------------------------------------------------------
<a name="lbg_yesno"></a>
### lbg_yesno
Displays a dialog to ask a question to user.

#### Usage
```bash
lbg_yesno [OPTIONS] TEXT
```

#### Options
```bash
-t, --title TEXT  Set a title to the dialog
--yes-label TEXT  Change Yes label (not available on zenity)
--no-label TEXT   Change No label (not available on zenity)
-y, --yes         Set Yes as selected button (not available on kdialog and zenity)
```

#### Exit codes
- 0: yes
- 1: no
- 2: usage error

---------------------------------------------------------------
<a name="lbg_input_password"></a>
### lbg_input_password
Displays a dialog to ask user to input a password.

#### Usage
```bash
lbg_input_password [options]
```
Result is stored into the `$lbg_input_password` variable.

#### Options
```bash
-t, --title TEXT      Set a title to the dialog
-l, --label TEXT      Change label (not available on zenity)
-c, --confirm         Display a confirm password dialog
--confirm-label TEXT  Change confirmation label (not available on zenity)
```

#### Exit codes
- 0: OK
- 1: cancel or failed
- 2: usage error
