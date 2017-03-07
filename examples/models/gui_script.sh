#!/bin/bash
#
#  My custom script using GUI functions
#


####################
#  INITIALIZATION  #
####################

# get real path of the script
if [ "$(uname)" == "Darwin" ] ; then
	# macOS which does not support readlink -f option
	current_script="$(perl -e 'use Cwd "abs_path";print abs_path(shift)' "$0")"
else
	current_script="$(readlink -f "$0")"
fi

# get directory of the current script
script_directory="$(dirname "$current_script")"

# load libbash
source "$script_directory/libbash.sh/libbash.sh" > /dev/null
if [ $? != 0 ] ; then
	echo >&2 "Error: cannot load libbash. Please add it to the '$script_directory/libbash.sh' directory."
	exit 1
fi

# load libbash GUI
source "$script_directory/libbash.sh/libbash_gui.sh" > /dev/null
if [ $? != 0 ] ; then
	echo >&2 "Error: cannot load libbash GUI. Please add it to the '$script_directory/libbash.sh' directory."
	exit 1
fi

# load translations

# get user language
lang="${LANG:0:2}"
# load translations (do not print errors if failed)
case "$lang" in
	fr)
		source "$script_directory/libbash.sh/locales/$lang.sh" &> /dev/null
		;;
esac

# change current script name
lb_current_script_name="myscript"


##################
#  MAIN PROGRAM  #
##################

# INSERT YOUR CODE HERE


# exit with exitcode
lb_exit
