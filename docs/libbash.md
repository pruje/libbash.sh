# libbash.sh documentation

## Introduction
libbash.sh features some functions to display dialogs and notifications for scripts with graphical interfaces.

## Usage
Add libbash.sh to your script before using functions:
```bash
source "/path/to/libbash.sh"
```
Then call the functions described below.

## Functions
All functions are named with the `lb_` prefix. See documentation below for each function.

### Table of content
- Basic bash functions
  - [lb_function_exists](#lb_function_exists)
  - [lb_test_arguments](#lb_test_arguments)
- Filesystem
  - [lb_df_fstype](#lb_df_fstype)*

Functions with a `*` are not yet supported on every OS.

-----------------------------------------------------------
<a name="lb_function_exists"></a>
### lb_function_exists
Test if a function exists.

#### Usage
```bash
lb_function_exists FUNCTION_NAME
```

#### Exit codes
- 0: function exists
- 1: function does not exists
- 2: command exists, but it's not a function

---------------------------------------------------------------
<a name="lb_test_arguments"></a>
### lb_test_arguments
Test number of arguments passed to a function.

#### Usage
```bash
lb_test_arguments OPERATOR N [VALUE...]
```
A common usage of this function would be `lb_test_arguments -ge 1 $*` to test if user has passed at least one argument to your script.

#### Arguments
```bash
OPERATOR  common bash comparison pattern: -eq|-ne|-lt|-le|-gt|-ge
N         expected number to compare to
VALUE     your arguments; (e.g. $* without quotes)
```

#### Exit codes
- 0: arguments OK
- 1: no
- 255: usage error

---------------------------------------------------------------
<a name="lb_df_fstype"></a>
### lb_df_fstype
Give the filesystem type of a path.

**NOT COMPATIBILE YET WITH macOS**

#### Usage
```bash
myfilesystem=$(lb_df_fstype PATH)
```

#### Exit codes
- 0: OK
- 1: error
- 2: usage error
