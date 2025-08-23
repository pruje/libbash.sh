# libbash.sh
A Bash library that features common functions useful for Bash developpers.

Tired to search the web any time you don't know or remember how to do a basic action in a bash script?
Just include libbash.sh to your script and use the functions!

libbash.sh features **more than 60 functions** to:
- test if a program is installed
- search a value in an array
- ask user to confirm an action by yes or no
- print text in colours
- create and write log files
- ask user to enter and confirm a password
- read and write into config files
- ...

libbash.sh comes also with a GUI part with **15 functions** to:
- display info/warning/error messages
- display system notifications
- ask user to choose a file/directory
- ...

See documentation for more info.

libbash.sh is compatible with Linux, BSD and macOS systems and works on Windows
with [Cygwin](https://www.cygwin.com).

Read our [wiki](https://github.com/pruje/libbash.sh/wiki) for some tips and tricks and other resources.

# Usage
Add `libbash.sh` to your script:
```bash
source "/path/to/libbash.sh" -
```

That's all! To use more powerful features like interactive windows, please read the documentation.

# Documentation
- [libbash.sh](docs/libbash.md)
- [libbash GUI](docs/libbash_gui.md)

# Examples
- A simple demo of libbash.sh: [examples](examples)
- A major project that uses libbash.sh: [time2backup](https://github.com/time2backup/time2backup)

# Tests
libbash.sh comes with some unit tests powered by [BATS](https://bats-core.readthedocs.io).

To simply run tests, you can execute:
```bash
bats tests/*.bats
```

# License
libbash.sh is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for the full license text.

# Credits
Author: Jean Prunneaux https://jean.prunneaux.com

Sources: https://github.com/pruje/libbash.sh

Help us to improve libbash.sh in [submitting issues](https://github.com/pruje/libbash.sh/issues) to report a bug or request new features!
