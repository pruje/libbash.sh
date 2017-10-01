# Changelog

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
