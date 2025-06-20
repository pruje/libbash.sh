# libbash.sh tests: filesystem

source libbash.sh -


#
# lb_df_fstype
#

@test "lb_df_fstype" {
	run lb_df_fstype
	[ "$status" = 1 ]
}

@test "lb_df_fstype notAfile" {
	run lb_df_fstype notAfile
	[ "$status" = 2 ]
}

@test "lb_df_fstype ." {
	run lb_df_fstype .
	[ -n "$output" ]
	[ "$status" = 0 ]
}


#
# lb_df_space_left
#

@test "lb_df_space_left" {
	run lb_df_space_left
	[ "$status" = 1 ]
}

@test "lb_df_space_left notAfile" {
	run lb_df_space_left notAfile
	[ "$status" = 2 ]
}

@test "lb_df_space_left ." {
	run lb_df_space_left .
	[ -n "$output" ]
	[ "$status" = 0 ]
}


#
# lb_df_uuid
#

@test "lb_df_uuid" {
	run lb_df_uuid
	[ "$status" = 1 ]
}

@test "lb_df_uuid notAfile" {
	run lb_df_uuid notAfile
	[ "$status" = 2 ]
}

@test "lb_df_uuid ." {
	# skip test if in container (will fail with error 32)
	if [ "$(df --output=source . | tail -n 1)" = overlay ] ; then
		skip "running inside a container"
	fi

	run lb_df_uuid .
	[ -n "$output" ]
	[ "$status" = 0 ]
}
