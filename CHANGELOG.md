# Changelog

## 0.3.1 (2017-03-07)
- Bugfixes and improvements on lb_result(), lb_short_result() and lb_exit()
- New `--error-exitcode` option for lb_result() and lb_short_result() to set a custom exit code if error
- **WARNING**: the former `-e` option alias used for `--save-exitcode` is renamed to `-s` in lb_result() and lb_short_result()
- Documentation: add [script examples and demo](examples)

## 0.3.0 (2017-02-11)
- New function: lb_abspath()
- New function: lb_is_comment()
- Console size detection and improvements for the dialog command
- Add `--absolute-path` options to lbg_choose_file() and lbg_choose_directory()
- Change behaviour for lb_result() on exit to return $lb_exitcode variable and not command result
- Renamed option `--save-exit-code` to `--save-exitcode` for lb_result() and lb_short_result()
- Set explicit returns to functions to avoid confusion and maybe errors

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

---------------------------------------------------------------

## License
libbash.sh is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for the full license text.

## Credits
Author: Jean Prunneaux  [http://jean.prunneaux.com](http://jean.prunneaux.com)

Website: [https://github.com/pruje/libbash.sh](https://github.com/pruje/libbash.sh)
