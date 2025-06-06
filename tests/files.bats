# libbash.sh tests: files

source libbash.sh -


#
# lb_homepath
#

@test "lb_homepath notAuser" {
	run lb_homepath notAuser
	[ "$status" = 1 ]
}

@test "lb_homepath" {
	run lb_homepath
	[ -n "$output" ]
	[ "$status" = 0 ]
}

@test "lb_homepath $USER" {
	run lb_homepath $USER
	[ -n "$output" ]
	[ "$status" = 0 ]
}


#
# lb_is_dir_empty
#

@test "lb_is_dir_empty" {
	run lb_is_dir_empty
	[ "$status" = 1 ]
}

@test "lb_is_dir_empty notAdirectory" {
	run lb_is_dir_empty notAdirectory
	[ "$status" = 1 ]
}

@test "lb_is_dir_empty ${BASH_SOURCE[0]}" {
	run lb_is_dir_empty ${BASH_SOURCE[0]}
	[ "$status" = 1 ]
}

@test "lb_is_dir_empty ." {
	run lb_is_dir_empty .
	[ "$status" = 3 ]
}


#
# lb_abspath
#

@test "lb_abspath" {
	run lb_abspath
	[ "$status" = 1 ]
}

@test "lb_abspath badDirectory/notAfile" {
	run lb_abspath badDirectory/notAfile
	[ "$status" = 2 ]
}

@test "lb_abspath /badDirectory/notAfile" {
	run lb_abspath /badDirectory/notAfile
	[ "$status" = 2 ]
}

@test "lb_abspath -n /badDirectory/notAfile" {
	run lb_abspath -n /badDirectory/notAfilext
	[ -n "$output" ]
	[ "$status" = 0 ]
}

@test "lb_abspath ." {
	run lb_abspath .
	[ -n "$output" ]
	[ "$status" = 0 ]
}


#
# lb_realpath
#

@test "lb_realpath" {
	run lb_realpath
	[ "$status" = 1 ]
}

@test "lb_realpath notAfile" {
	run lb_realpath notAfile
	[ "$status" = 1 ]
}

@test "lb_realpath ." {
	run lb_realpath .
	[ -n "$output" ]
	[ "${output:0:1}" = / ]
	[ "$status" = 0 ]
}
