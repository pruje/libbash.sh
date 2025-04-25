# libbash.sh tests: interactions

source libbash.sh --lang en

#
#  lb_yesno
#

@test "lb_yesno" {
	run lb_yesno
	[ "$status" = 1 ]
}

@test "lb_yesno No?" {
	run lb_yesno "No?" << EOF
EOF
	[ "$status" = 2 ]
}

@test "lb_yesno -y Yes?" {
	run lb_yesno -y "Yes?" << EOF
EOF
	[ "$status" = 0 ]
}

@test "lb_yesno --yes-label yes YES? > y" {
	run lb_yesno --yes-label yes "YES?" << EOF
y
EOF
	[ "$status" = 2 ]
}

@test "lb_yesno --yes-label yes YES? > yes" {
	run lb_yesno --yes-label yes "YES?" << EOF
yes
EOF
	[ "$status" = 0 ]
}

@test "lb_yesno -c Cancel? > c" {
	run lb_yesno -c "Cancel?" << EOF
c
EOF
	[ "$status" = 3 ]
}
