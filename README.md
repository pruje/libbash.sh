# libbash.sh
A Bash library that features common functions useful for Bash developpers.

Tired to search the web any time you don't know or remember how to do a basic action in a bash script?
Just include libbash.sh to your script and use the functions!

libbash.sh features **47 functions** to:
- test if a program is installed
- search a value in an array
- ask user to confirm an action by yes or no
- print text in colours
- create and write log files
- ask user to enter and confirm a password
- ...

libbash.sh comes also with a GUI part with **13 functions** to:
- display info/warning/error messages
- display system notifications
- ask user to choose a file/directory
- ...

See documentation for more info.

libbash.sh is compatible with Linux and macOS systems and works partially on Windows with [Cygwin](https://www.cygwin.com).
See documentation to know which functions are not supported yet.

## Usage
Add `libbash.sh` to your script:
```bash
source "/path/to/libbash.sh"
```

If you want to use libbash.sh GUI, use the `--gui` option as argument when loading libbash:
```bash
source "/path/to/libbash.sh" --gui
```

**Note: DO NOT USE** variables or functions with `lb_` prefix in your scripts
(nor `lbg_` if you use libbash.sh GUI) as you could override or broke some libbash.sh features. But you can use some libbash.sh variables (see documentation).

## Translations
By default, libbash.sh translation is loaded in the user language. You can specify a language with the `--lang` option:
```bash
source "/path/to/libbash.sh" --lang fr
```

Supported languages:
- `en`: English (default)
- `fr`: French

## Documentation
- [libbash.sh](docs/libbash.md)
- [libbash GUI](docs/libbash_gui.md)

## Examples
- A simple demo of libbash.sh: [examples](examples)
- A complete project using libbash.sh: [time2backup](https://github.com/time2backup/time2backup)

## License
libbash.sh is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for the full license text.

## Credits
Author: Jean Prunneaux  [http://jean.prunneaux.com](http://jean.prunneaux.com)

Website: [https://github.com/pruje/libbash.sh](https://github.com/pruje/libbash.sh)

Help us to improve libbash.sh in [submitting issues](https://github.com/pruje/libbash.sh/issues) to report a bug or request new features!
