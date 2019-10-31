# Changelog
This project adheres to [Semantic Versioning](http://semver.org/).

## 1.14.4 (2019-10-31)
### Bugfixes
- Fixed bug and enhance reliability of `lb_generate_password`
- Enhance reliability of df functions

## 1.14.3 (2019-10-08)
### Bugfixes
- Fixed bug when inserting a value in empty file in `lb_set_config`
- Improve documentation about libbash options calls

## 1.14.2 (2019-09-23)
### New features
- New option `--no-spaces` in `lb_set_logfile` to set values like `param=value`

### Changes
- `lb_get_config` gets the last value of the file/section if multiple values found
- `lb_set_config` sets the last value of the file/section if multiple values found
- Minor improvements in `lb_is_comment`

### Bugfixes
- Fixed bug in section detection in `lb_set_config`

## 1.14.1 (2019-09-03)
### Changes
- `lb_set_logfile` creates log file if it does not exists

### Bugfixes
- Add usage error detection for `lb_edit`

## 1.14.0 (2019-08-24)
### New features
- New option in `lb_set_logfile` to write logs in Windows format
- New option in `lb_abspath` to not test absolute paths

### Changes
- `lb_get_config` and `lb_set_config` sets quotes automatically
- Minor code optimizations

### Bugfixes
- Avoid reading Windows endline characters in config values
- Insert new config lines failed on macOS/*BSD
- Fix spaces detection in grep regex for macOS/*BSD compatibility

## 1.13.0 (2019-07-22)
### New features
- Add stdin support for some functions:
   - `lb_print`
   - `lb_error`
   - `lb_display` and `lb_display_*`
   - `lb_log`
   - `lb_trim`
   - `lb_is_comment`
   - `lb_email`
   - `lbg_display_*`
   - `lbg_notify`
- New analyse mode for `lb_read_config`
- `lb_getargs` and `lb_getopt` now supports options with syntax `--option=value`
- New filters argument in `lb_import_config` to import only some variables
- New function: `lb_migrate_config` to migrate config files

### Changes
- Internal variables and functions are renamed with custom prefix
- Code cleaning

## 1.12.2 (2019-05-15)
- Append an empty line above a new section in `lb_set_config`

## 1.12.1 (2019-04-09)
- Minor improvements for variables
- Update documentation for BSD support

## 1.12.0 (2019-03-18)
- Add support for BSD systems

## 1.11.0 (2019-02-01)
- New function: `lb_istrue` to test boolean values
- Fixed a bug in `lbg_open_directory` for Windows
- Many code optimizations
- Improve documentation

## 1.10.0 (2019-01-19)
- New functions: `lb_getargs` and `lb_getopt` to improve arguments parsing in scripts
- New quiet mode to disable displays (+ editable variable `$lb_quietmode`)
- Improve documentation and examples

## 1.9.2 (2018-08-26)
- Detect `sed` version to make `lb_edit()` work on any system
- Some context variables are now read-only

## 1.9.1 (2018-07-06)
- Use `lb_edit()` in `lb_set_config()` to avoid create backup files

## 1.9.0 (2018-06-08)
### Added
- New function: `lb_edit()` to edit a file properly with the `sed -i` command

### Changes
- `lb_array_contains()` renamed to `lb_in_array()` (old name kept for compatibility)
- `lb_dir_is_empty()` renamed to `lb_is_dir_empty()` (old name kept for compatibility)
- Improve error management to avoid crashes when using command `set -e`
- Code quality improved by [ShellCheck](https://www.shellcheck.net/)
- Various performance improvements

## 1.8.0 (2018-01-26)
### New features
- New function: `lb_split()` to split a string into array
- New function: `lb_join()` to join array into string

### Changes
- `lb_command_exists()` now returns only error code 1 and accepts multiple arguments
- `lb_function_exists()` accepts multiple arguments
- `lb_user_exists()` now returns only error code 1 and accepts multiple arguments
- More strict results in `lb_is_number()`, `lb_is_integer()` and `lb_is_boolean()`: all arguments are verified
- `lb_array_contains()` now returns 2 if no array is provided
- Major code refactoring to improve local variables use and readability

## 1.7.2 (2017-12-16)
- Improve loading and add new return codes for libbash loading status

## 1.7.1 (2017-12-01)
- Fix bad values in `$lb_current_script` `$lb_current_script_name` and `$lb_current_script_directory` (bug exists since v1.6.0)
- Fix section bugs in `lb_read_config()` and `lb_import_config()` when reading files with Windows end of line format

## 1.7.0 (2017-11-25)
- New function: `lb_get_config()` to get a single value from a config file
- New option to send emails in HTML format in `lb_email()` function
- New option to add files attachments in emails in `lb_email()` function
- Speed optimizations
- Minor bugfixes
- Various improvements in documentation

## 1.6.3 (2017-11-13)
- Add new `$lb_current_hostname` variable

## 1.6.2 (2017-10-18)
- [Windows] Fixed a bug for `lb_set_logfile()` and `lb_get_logfile()` which failed if logfile was in a samba share

## 1.6.1 (2017-10-13)
- New aliases for display functions:
    - `lb_warning()` -> `lb_display_warning()`
    - `lb_info()` -> `lb_display_info()`
    - `lb_debug()` -> `lb_display_debug()`
- New aliases for dialogs functions:
    - `lbg_critical()` -> `lbg_display_critical()`
    - `lbg_error()` -> `lbg_display_error()`
    - `lbg_warning()` -> `lbg_display_warning()`
    - `lbg_info()` -> `lbg_display_info()`
    - `lbg_debug()` -> `lbg_display_debug()`

## 1.6.0 (2017-10-07)
- New function: `lb_date2timestamp()` to convert a date to a timestamp
- New function: `lb_timestamp2date()` to convert a timestamp to a date
- New debian package available to deploy libbash files in `/usr/lib/libbash`
- Minor improvements in code and documentation

## 1.5.0 (2017-10-01)
- New function: `lb_group_members()` to get users members of a group (works only on Linux systems)
- New function: `lb_set_config()` for setting values
- Support for config INI files for `lb_read_config()` and `lb_import_config()`: ';' lines are comments, sections supported
- New options for `lb_read_config()` and `lb_import_config()` to filter by config sections
- Removed multiple files support for `lb_import_config()`
- Improvements in documentation

## 1.4.1 (2017-09-14)
- Improved speed of config reading in `lb_read_config()` and `lb_import_config()`
- Improvements in documentation

## 1.4.0 (2017-09-11)
- New function: `lb_read_config()` to read a config file (like `lb_import_config()` without assigning to variables)
- Fixed a bug in `lb_import_config()` for values containing the `=` character
- Huge performance improvements in `lb_import_config()`
- Add support in `lb_df_fstype()` for Linux systems without `lsblk` command

## 1.3.2 (2017-09-07)
- Various performance improvements

## 1.3.1 (2017-09-02)
- Changed results of `lb_df_space_left()` in KB instead of bytes to avoid differences between Linux and macOS
- Add test and error code for files not readable in `lb_import_config()`

## 1.3.0 (2017-08-31)
- New function: `lb_import_config()` to read a file and import values into variables
- New function: `lbg_open_directory()` to open a GUI file browser
- New `--multiple` option in `lb_choose_option()` to let user choose multiple options
- Changed arguments for `lb_input_password()` and `lbg_input_password()` (this does not break backward compatibility)
- Minor code improvements

## 1.2.2 (2017-06-29)
- Removed \n printed on Windows dialogs

## 1.2.1 (2017-06-28)
- Fixed a very specific case for cscript on Windows that cannot run vbscripts from an absolute path

## 1.2.0 (2017-06-28)
- Added Windows GUI support for `lbg_input_text()`, `lbg_choose_option()` and `lbg_choose_directory()`
- Improve results of `lb_df_fstype()` and `lb_df_uuid()` using `lsblk` command on Linux (see documentation)
- `lbg_input_text()` now supports backslashes entries without putting doubles
- Various improvements in source code and documentation

## 1.1.2 (2017-06-28)
- Fixed a bug in `lb_compare_versions()` that caused bad results when comparing 0.x versions

## 1.1.1 (2017-06-13)
- Major bugfix in arguments loading that caused bugs for `getopts` command in user scripts

## 1.1.0 (2017-06-07)
- Add support for Windows systems powered by [Cygwin](https://www.cygwin.com)!
- New variable and options to run a command when `lb_exit()` is called (see documentation)
- New functions: `lb_user_exists()` and `lb_in_group()`

## 1.0.0 (2017-05-17)
- New function: `lb_is_email()` to test if a string is a valid email
- New display level support with functions: `lb_get_display_level()` and `lb_set_display_level()`
  (since now, the display level was the same as the log level)
- New variables: `$lb_current_user` (current user name), `$lb_path` (libbash.sh path),
  `$lbg_path` (libbash.sh GUI path) and `$lb_directory` (libbash.sh directory)
- New option in `lb_input_password()` and `lbg_input_password()` to check minimum size of a password
- New options to load libbash GUI and locales
- Automatic loading of locales for user language
- Renamed `lb_get_loglevel()` to `lb_get_log_level()` and `lb_set_loglevel()` to `lb_set_log_level()`
  (+ added aliases to not break compatibility)
- Renamed `lb_detect_os()` to `lb_current_os()` (+ added alias to not break compatibility)
- Many improvements and optimizations in source code
- Improvements in documentation

## 0.4.1 (2017-04-24)
- New function: `lb_trim()`
- Fix missing quotes that could cause bugs in paths with spaces

## 0.4.0 (2017-04-01)
- New functions: `lb_is_boolean()`, `lb_compare_versions()` and `lb_generate_password()`
- Minor code improvements

## 0.3.3 (2017-03-22)
- New `$lb_current_os` variable with current OS
- `lbg_set_gui()` with no argument now sets the default GUI tool (useful when reseting)
- Delete `lb_log()` write error messages

## 0.3.2 (2017-03-21)
- Fix bug on zenity notifications that hung scripts (removed the `--listen` option)

## 0.3.1 (2017-03-07)
- Bugfixes and improvements on `lb_result()`, `lb_short_result()` and `lb_exit()`
- New `--error-exitcode` option for `lb_result()` and `lb_short_result()` to set a custom exit code if error
- **WARNING**: the former `-e` option alias used for `--save-exitcode` is renamed to `-s` in `lb_result()` and `lb_short_result()`
- Documentation: add [script examples and demo](examples)

## 0.3.0 (2017-02-11)
- New function: `lb_abspath()`
- New function: `lb_is_comment()`
- Console size detection and improvements for the dialog command
- Add `--absolute-path` options to `lbg_choose_file()` and `lbg_choose_directory()`
- Change behaviour for `lb_result()` on exit to return `$lb_exitcode` variable and not command result
- Renamed option `--save-exit-code` to `--save-exitcode` for `lb_result()` and `lb_short_result()`
- Set explicit returns to functions to avoid confusion and maybe errors

## 0.2.0 (2017-02-06)
- New function: `lb_is_number()`
- Add macOS support for `lb_df_fstype()`
- Add macOS support for `lb_df_uuid()`
- Better implementation of `lb_short_result()`: exit code argument is now an option

## 0.1.2 (2017-02-04)
- Fix bug in `lb_exit()`: bad variable name

## 0.1.1 (2017-02-01)
- Add a missing French translation

## 0.1.0 (2017-01-21)
- First release on Github

---------------------------------------------------------------

## License
libbash.sh is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for the full license text.

## Credits
Author: Jean Prunneaux  [http://jean.prunneaux.com](http://jean.prunneaux.com)

Website: [https://github.com/pruje/libbash.sh](https://github.com/pruje/libbash.sh)
