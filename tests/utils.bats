# libbash.sh tests: utils

source libbash.sh -


#
# lb_current_os
#

@test "lb_current_os" {
	run lb_current_os
	[ -n "$output" ]
	[ "$status" = 0 ]
}


#
# lb_current_uid
#

@test "lb_current_uid" {
	run lb_current_uid
	[ -n "$output" ]
	[ "$status" = 0 ]
}


#
# lb_generate_password
#

@test "lb_generate_password aaa" {
	run lb_generate_password aaa
	[ "$status" = 1 ]
}

@test "lb_generate_password" {
	run lb_generate_password
	[ -n "$output" ]
	[ "$status" = 0 ]
}

@test "lb_generate_password 8" {
	run lb_generate_password 8
	[ ${#output} = 8 ]
	[ "$status" = 0 ]
}


#
# lb_user_exists
#

@test "lb_user_exists" {
	run lb_user_exists
	[ "$status" = 1 ]
}

@test "lb_user_exists badUserName" {
	run lb_user_exists badUserName
	[ "$status" = 1 ]
}

@test "lb_user_exists badUserName $USER" {
	run lb_user_exists badUserName $USER
	[ "$status" = 1 ]
}

@test "lb_user_exists $USER" {
	run lb_user_exists $USER
	[ "$status" = 0 ]
}
