# libbash.sh
A Bash library that features common functions useful for Bash developpers.

Tired to search the web any time you don't know or remember how to do a basic action in a bash script?
Just include libbash.sh to your script and use the functions!

libbash.sh features functions to:
- test if a program is installed
- search a value in an array
- ask user to confirm an action by yes or no
- print text in colours
- create and write log files
- ask user to enter and confirm a password
- ...

libbash.sh comes also with a GUI part to:
- display info/warning/error messages
- display system notifications
- ask user to choose a file/directory
- ...

See documentation for more info.

libbash.sh is compatible with Linux and macOS systems.

## Usage
Add `libbash.sh` to your script:
```bash
source "/path/to/libbash.sh"
```

If you want to use libbash.sh GUI, add `libbash_gui.sh` to your script **after** `libbash.sh`:
```bash
source "/path/to/libbash_gui.sh"
```

**Note: DO NOT USE** variables or functions with `lb_` prefix in your scripts
(nor `lbg_` if you use libbash.sh GUI) as you could override or broke some libbash.sh features.

## Documentation
- [libbash.sh](docs/libbash.md)
- [libbash GUI](docs/libbash_gui.md)

## License
libbash.sh is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for the full license text.

## Credits
Author: Jean Prunneaux  [http://jean.prunneaux.com](http://jean.prunneaux.com)

Website: [https://github.com/pruje/libbash.sh](https://github.com/pruje/libbash.sh)
