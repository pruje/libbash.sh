#!/bin/bash
#
#  My custom script using libbash.sh
#


#
#  Initialization
#

# get real path of the script
if [ "$(uname)" == Darwin ] ; then
	# macOS which does not support readlink -f option
	current_script=$(perl -e 'use Cwd "abs_path";print abs_path(shift)' "$0")
else
	current_script=$(readlink -f "$0")
fi

# get directory of the current script
script_directory=$(dirname "$current_script")

# load libbash with GUI functions
source "$script_directory"/libbash/libbash.sh --gui > /dev/null
if [ $? != 0 ] ; then
	echo >&2 "Error: cannot load libbash. Please add it to the '$script_directory/libbash/' directory."
	exit 1
fi

# change current script name
lb_current_script_name=myscript


#
#  Main program
#

# INSERT YOUR CODE HERE


# exit with exitcode
lb_exit
