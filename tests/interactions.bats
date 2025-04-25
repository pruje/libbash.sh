# libbash.sh tests: interactions

source libbash.sh --lang en


#
# lb_yesno
#

@test "lb_yesno" {
	run lb_yesno
	[ "$status" = 1 ]
}

@test "lb_yesno 'No?'" {
	run lb_yesno 'No?' << EOF
EOF
	[ "$status" = 2 ]
}

@test "lb_yesno -y 'Yes?'" {
	run lb_yesno -y 'Yes?' << EOF
EOF
	[ "$status" = 0 ]
}

@test "lb_yesno --yes-label yes 'YES?' > y" {
	run lb_yesno --yes-label yes 'YES?' << EOF
y
EOF
	[ "$status" = 2 ]
}

@test "lb_yesno --yes-label yes 'YES?' > yes" {
	run lb_yesno --yes-label yes 'YES?' << EOF
yes
EOF
	[ "$status" = 0 ]
}

@test "lb_yesno -c 'Cancel?' > c" {
	run lb_yesno -c 'Cancel?' << EOF
c
EOF
	[ "$status" = 3 ]
}


#
# lb_choose_option
#

# Usage: test_lb_choose_option INPUT [ARGS]
test_lb_choose_option() {
	local input=$1 result=0
	shift
	lb_choose_option "$@" &> /dev/null << EOF
$input
EOF
	result=$?
	[ $result = 0 ] || return $result
	echo "${lb_choose_option[*]}"
}

@test "lb_choose_option" {
	run lb_choose_option
	[ "$status" = 1 ]
}

@test "lb_choose_option cancel" {
	run test_lb_choose_option '' cancel
	[ "$status" = 2 ]
}

@test "lb_choose_option -l 'Type cancel:' -c cancel a b c > cancel" {
	run test_lb_choose_option cancel -l 'Type cancel:' -c cancel a b c
	[ "$status" = 2 ]
}

@test "lb_choose_option choose a bad option > 9999" {
	run test_lb_choose_option 9999 choose a bad option
	[ "$status" = 3 ]
}

@test "lb_choose_option a b c > 1,2" {
	run test_lb_choose_option 1,2 a b c
	[ "$status" = 3 ]
}

@test "lb_choose_option -d 1 -l 'TypeEnter:' ok" {
	run test_lb_choose_option '' -d 1 -l 'TypeEnter:' ok
	[ "$output" = 1 ]
	[ "$status" = 0 ]
}

@test "lb_choose_option one two three > 2" {
	run test_lb_choose_option 2 one two three
	[ "$output" = 2 ]
	[ "$status" = 0 ]
}

@test "lb_choose_option -m a b c > 1,3,3,1" {
	run test_lb_choose_option 1,3,3,1 -m a b c
	[ "$output" = "1 3" ]
	[ "$status" = 0 ]
}


#
# lb_input_text
#

# Usage: test_lb_input_text INPUT [ARGS]
test_lb_input_text() {
	local input=$1 result=0
	shift
	lb_input_text "$@" &> /dev/null << EOF
$input
EOF
	result=$?
	[ $result = 0 ] || return $result
	echo "$lb_input_text"
}

@test "lb_input_text" {
	run lb_input_text
	[ "$status" = 1 ]
}

@test "lb_input_text -n 'Please enter x':' > x" {
	run test_lb_input_text x -n 'Please enter x:'
	[ "$output" = x ]
	[ "$status" = 0 ]
}

@test "lb_input_text -d 'zzz' 'Please enter nothing:'" {
	run test_lb_input_text "" -d 'zzz' 'Please enter nothing:'
	[ "$output" = zzz ]
	[ "$status" = 0 ]
}


#
# lb_input_password
#

# Usage: test_lb_input_password INPUT1 INPUT2 [ARGS]
test_lb_input_password() {
	local input1=$1 input2=$2 result=0
	shift 2
	lb_input_password "$@" &> /dev/null << EOF
$input1
$input2
EOF
	result=$?
	[ $result = 0 ] || return $result
	echo "$lb_input_password"
}

@test "lb_input_password -l" {
	run lb_input_password -l
	[ "$status" = 1 ]
}

@test "lb_input_password" {
	run test_lb_input_password
	[ "$status" = 2 ]
}

@test "lb_input_password -c > xxx,yyy" {
	run test_lb_input_password xxx yyy -c
	[ "$status" = 3 ]
}

@test "lb_input_password -m 4 > xxx" {
	run test_lb_input_password xxx '' -m 4
	[ "$status" = 4 ]
}

@test "lb_input_password -m 3 > xxx" {
	run test_lb_input_password xxx '' -m 3
	[ "$output" = xxx ]
	[ "$status" = 0 ]
}

@test "lb_input_password -c --confirm-label 'Confirm xxx:' 'Please enter xxx:'" {
	run test_lb_input_password xxx xxx -c --confirm-label 'Confirm xxx:' 'Please enter xxx:'
	[ "$output" = xxx ]
	[ "$status" = 0 ]
}
