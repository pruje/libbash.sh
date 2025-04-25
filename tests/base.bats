# core basic tests

source libbash.sh -

# command exists
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


# function exists
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
