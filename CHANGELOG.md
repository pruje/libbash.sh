# Changelog

## 0.3.0 (2017-02-08)
- New function: lb_abspath()
- New function: lb_is_comment()
- Add --absolute-path options to lbg_choose_file() and lbg_choose_directory()
- Change behaviour for lb_result() on exit to return $lb_exitcode variable and not command result
- Renamed option --save-exit-code to --save-exitcode for lb_result() and lb_short_result()

## 0.2.0 (2017-02-06)
- New function: lb_is_number()
- Add macOS support for lb_df_fstype()
- Add macOS support for lb_df_uuid()
- Better implementation of lb_short_result(): exit code argument is now an option

## 0.1.2 (2017-02-04)
- Fix bug in lb_exit(): bad variable name

## 0.1.1 (2017-02-01)
- Add a missing French translation

## 0.1.0 (2017-01-21)
- First release on Github
