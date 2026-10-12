# libbash.sh tests: logs

source libbash.sh -

test_logfile=./test_logfile.log

__test_log() {
	lb_set_logfile -a "$test_logfile" && "$@"
}


#
# lb_get_logfile before it was set
#

@test "lb_get_logfile -> empty" {
	run lb_get_logfile
	[ "$status" = 1 ]
}


#
# lb_set_logfile
#

@test "lb_set_logfile $test_logfile" {
	run lb_set_logfile $test_logfile
	[ "$status" = 0 ]
}

@test "lb_get_logfile" {
	run __test_log lb_get_logfile
	[ "$status" = 0 ]
	[ "$output" = "$test_logfile" ]
}


#
# log_run_to_log
#

@test "lb_run_to_log echo 'Hello world'" {
	run __test_log lb_run_to_log echo "Hello world"
	[ "$status" = 0 ]
	[ "$output" = "Hello world" ]
}

@test "Last line of logs: 'Hello world'" {
	run tail -n 1 "$test_logfile"
	[ "$status" = 0 ]
	[ "$output" = "Hello world" ]
}

@test "lb_run_to_log lb_error Error" {
	run __test_log lb_run_to_log lb_error Error
	[ "$status" = 0 ]
	[ "$output" = "Error" ]
}

@test "Last line of logs: 'Error'" {
	run tail -n 1 "$test_logfile"
	[ "$status" = 0 ]
	[ "$output" = "Error" ]
}

@test "Delete log file" {
	run rm -f "$test_logfile"
	[ "$status" = 0 ]
}
