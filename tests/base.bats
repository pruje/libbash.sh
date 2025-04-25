# libbash.sh tests: base

source libbash.sh -


#
# lb_command_exists
#

@test "lb_command_exists echo" {
	run lb_command_exists echo
	[ "$status" = 0 ]
}

@test "lb_command_exists echo true" {
	run lb_command_exists echo true
	[ "$status" = 0 ]
}

@test "lb_command_exists echo notAcommand" {
	run lb_command_exists echo notAcommand
	[ "$status" = 1 ]
}

@test "lb_command_exists notAcommand" {
	run lb_command_exists notAcommand
	[ "$status" = 1 ]
}


#
# lb_function_exists
#

@test "lb_function_exists lb_command_exists" {
	run lb_function_exists lb_command_exists
	[ "$status" = 0 ]
}

@test "lb_function_exists lb_command_exists lb_function_exists" {
	run lb_function_exists lb_command_exists lb_function_exists
	[ "$status" = 0 ]
}

@test "lb_function_exists" {
	run lb_function_exists
	[ "$status" = 1 ]
}

@test "lb_function_exists notAfunction" {
	run lb_function_exists notAfunction
	[ "$status" = 2 ]
}

@test "lb_function_exists echo" {
	run lb_function_exists echo
	[ "$status" = 3 ]
}

@test "lb_function_exists lb_command_exists echo" {
	run lb_function_exists lb_command_exists echo
	[ "$status" = 3 ]
}


#
# lb_cmd_to_array
#

@test "lb_cmd_to_array" {
	run lb_cmd_to_array
	[ "$status" = 1 ]
}

@test "lb_cmd_to_array ls -l" {
	run lb_cmd_to_array ls -l
	[ "$status" = 0 ]
}


#
# lb_getargs
#

test_lb_getargs() {
	lb_getargs "$@" && echo "${lb_getargs[*]}"
}

@test "lb_getargs" {
	run lb_getargs
	[ "$status" = 1 ]
}

@test "lb_getargs -ab arg --opt" {
	run test_lb_getargs -ab arg --opt
	[ "$status" = 0 ]
	[ "$output" = "-a -b arg --opt" ]
}


#
# lb_getopt
#

@test "lb_getopt" {
	run lb_getopt
	[ "$status" = 1 ]
}

@test "lb_getopt --opt" {
	run lb_getopt --opt
	[ "$status" = 1 ]
}

@test "lb_getopt --opt --opt2" {
	run lb_getopt --opt --opt2
	[ "$status" = 1 ]
}

@test "lb_getopt --opt value" {
	run lb_getopt --opt value
	[ "$status" = 0 ]
	[ "$output" = "value" ]
}

@test "lb_getopt --opt2=value2" {
	run lb_getopt --opt2=value2
	[ "$status" = 0 ]
	[ "$output" = "value2" ]
}
