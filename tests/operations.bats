# libbash.sh tests: operations

source libbash.sh -


#
# lb_istrue
#

@test "lb_istrue" {
	run lb_istrue
	[ "$status" = 1 ]
}

@test "lb_istrue false" {
	run lb_istrue false
	[ "$status" = 1 ]
}

@test "lb_istrue 1" {
	run lb_istrue 1
	[ "$status" = 1 ]
}

@test "lb_istrue true" {
	run lb_istrue true
	[ "$status" = 0 ]
}


#
# lb_is_number
#

@test "lb_is_number" {
	run lb_is_number
	[ "$status" = 1 ]
}

@test "lb_is_number TEST" {
	run lb_is_number TEST
	[ "$status" = 1 ]
}

@test "lb_is_number 1 TEST" {
	run lb_is_number 1 TEST
	[ "$status" = 1 ]
}

@test "lb_is_number ' 123.45 '" {
	run lb_is_number ' 123.45 '
	[ "$status" = 1 ]
}

@test "lb_is_number 2" {
	run lb_is_number 2
	[ "$status" = 0 ]
}

@test "lb_is_number -99" {
	run lb_is_number -99
	[ "$status" = 0 ]
}

@test "lb_is_number 20.16" {
	run lb_is_number 20.16
	[ "$status" = 0 ]
}

@test "lb_is_number -0.9" {
	run lb_is_number -0.9
	[ "$status" = 0 ]
}


#
# lb_is_integer
#

@test "lb_is_integer" {
	run lb_is_integer
	[ "$status" = 1 ]
}

@test "lb_is_integer TEST" {
	run lb_is_integer TEST
	[ "$status" = 1 ]
}

@test "lb_is_integer ' 123 '" {
	run lb_is_integer ' 123 '
	[ "$status" = 1 ]
}

@test "lb_is_integer 0" {
	run lb_is_integer 0
	[ "$status" = 0 ]
}

@test "lb_is_integer 123" {
	run lb_is_integer 123
	[ "$status" = 0 ]
}

@test "lb_is_integer -1" {
	run lb_is_integer -1
	[ "$status" = 0 ]
}

@test "lb_is_integer -99" {
	run lb_is_integer -99
	[ "$status" = 0 ]
}


#
# lb_is_boolean
#

@test "lb_is_boolean" {
	run lb_is_boolean
	[ "$status" = 1 ]
}

@test "lb_is_boolean TEST" {
	run lb_is_boolean TEST
	[ "$status" = 1 ]
}

@test "lb_is_boolean 1" {
	run lb_is_boolean 1
	[ "$status" = 1 ]
}

@test "lb_is_boolean true" {
	run lb_is_boolean true
	[ "$status" = 0 ]
}

@test "lb_is_boolean false" {
	run lb_is_boolean false
	[ "$status" = 0 ]
}


#
# lb_is_email
#

@test "lb_is_email" {
	run lb_is_email
	[ "$status" = 1 ]
}

@test "lb_is_email domain.com" {
	run lb_is_email domain.com
	[ "$status" = 1 ]
}

@test "lb_is_email blah@blah" {
	run lb_is_email blah@blah
	[ "$status" = 1 ]
}

@test "lb_is_email me@domain.com" {
	run lb_is_email me@domain.com
	[ "$status" = 0 ]
}

@test "lb_is_email me_at-my.domain@my.domain.com" {
	run lb_is_email me_at-my.domain@my.domain.com
	[ "$status" = 0 ]
}


#
# lb_trim
#

@test "lb_trim" {
	run lb_trim
	[ "$status" = 0 ]
}

@test "lb_trim '    abc   '" {
	run lb_trim '    abc   '
	[ "$status" = 0 ]
	[ "$output" = "abc" ]
}

@test "echo '   abc   ' | lb_trim" {
	output=$(echo '   abc   ' | lb_trim)
	[ $? = 0 ]
	[ "$output" = "abc" ]
}

@test "lb_trim ' a  b    c    '" {
	run lb_trim ' a  b    c    '
	[ "$status" = 0 ]
	[ "$output" = "a  b    c" ]
}


#
# lb_split
#

test_lb_split() {
	lb_split "$@" && echo "${lb_split[*]}"
}

@test "lb_split" {
	run lb_split
	[ "$status" = 1 ]
}

@test "lb_split ," {
	run test_lb_split ,
	[ "$status" = 0 ]
	[ "$output" = "" ]
}

@test "lb_split , '1,2,3,4'" {
	run test_lb_split , "1,2,3,4"
	[ "$status" = 0 ]
	[ "$output" = "1 2 3 4" ]
}


#
# lb_join
#

@test "lb_join" {
	run lb_join
	[ "$status" = 1 ]
}

@test "lb_join ," {
	run lb_join ,
	[ "$status" = 0 ]
	[ "$output" = "" ]
}

@test "lb_join , 1 2 3" {
	run lb_join , 1 2 3
	[ "$status" = 0 ]
	[ "$output" = "1,2,3" ]
}


#
# lb_in_array
#

@test "lb_in_array" {
	run lb_in_array
	[ "$status" = 1 ]
}

@test "lb_in_array x" {
	run lb_in_array x
	[ "$status" = 2 ]
}

@test "lb_in_array z a b c" {
	run lb_in_array z a b c
	[ "$status" = 2 ]
}

@test "lb_in_array 2 1 2 3" {
	run lb_in_array 2 1 2 3
	[ "$status" = 0 ]
}

@test "lb_in_array 'test 1' 'test 1' 'test 2'" {
	run lb_in_array 'test 1' 'test 1' 'test 2'
	[ "$status" = 0 ]
}


#
# lb_date2timestamp
#

@test "lb_date2timestamp" {
	run lb_date2timestamp
	[ "$status" = 1 ]
}

@test "lb_date2timestamp badDate" {
	run lb_date2timestamp badDate
	[ "$status" = 2 ]
}

@test "lb_date2timestamp --utc '2017-12-31 23:59:59'" {
	run lb_date2timestamp --utc '2017-12-31 23:59:59'
	[ "$status" = 0 ]
	[ "$output" = 1514764799 ]
}


#
# lb_timestamp2date
#

@test "lb_timestamp2date" {
	run lb_timestamp2date
	[ "$status" = 1 ]
}

@test "lb_timestamp2date badTimestamp" {
	run lb_timestamp2date badTimestamp
	[ "$status" = 1 ]
}

@test "-r 20171231235959 lb_timestamp2date -f '%Y%m%d%H%M%S' --utc 1514764799" {
	run lb_timestamp2date -f '%Y%m%d%H%M%S' --utc 1514764799
	[ "$status" = 0 ]
	[ "$output" = 20171231235959 ]
}


#
# lb_compare_versions
#

@test "lb_compare_versions" {
	run lb_compare_versions
	[ "$status" = 1 ]
}

@test "lb_compare_versions a b c" {
	run lb_compare_versions a b c
	[ "$status" = 1 ]
}

@test "lb_compare_versions a.b -gt c.d" {
	run lb_compare_versions a.b -gt c.d
	[ "$status" = 1 ]
}

@test "lb_compare_versions a -eq b" {
	run lb_compare_versions a -eq b
	[ "$status" = 1 ]
}

@test "lb_compare_versions a -eq a" {
	run lb_compare_versions a -eq a
	[ "$status" = 0 ]
}

@test "lb_compare_versions 0.1 -eq 0.1.0" {
	run lb_compare_versions 0.1 -eq 0.1.0
	[ "$status" = 0 ]
}

@test "lb_compare_versions 0.0.1 -lt 0.0.2" {
	run lb_compare_versions 0.0.1 -lt 0.0.2
	[ "$status" = 0 ]
}

@test "lb_compare_versions 1 -eq 1.0.0" {
	run lb_compare_versions 1 -eq 1.0.0
	[ "$status" = 0 ]
}

@test "lb_compare_versions 1 -ge 1.0.0" {
	run lb_compare_versions 1 -ge 1.0.0
	[ "$status" = 0 ]
}

@test "lb_compare_versions 1 -le 1.0.0" {
	run lb_compare_versions 1 -le 1.0.0
	[ "$status" = 0 ]
}

@test "lb_compare_versions 1 -gt 0.9.9" {
	run lb_compare_versions 1 -gt 0.9.9
	[ "$status" = 0 ]
}

@test "lb_compare_versions 1 -lt 2.0.0" {
	run lb_compare_versions 1 -lt 2.0.0
	[ "$status" = 0 ]
}

@test "lb_compare_versions 1.0-beta -eq 1.0.0-beta" {
	run lb_compare_versions 1.0-beta -eq 1.0.0-beta
	[ "$status" = 0 ]
}

@test "lb_compare_versions 1.0-beta -gt 1.0.0-alpha" {
	run lb_compare_versions 1.0-beta -gt 1.0.0-alpha
	[ "$status" = 0 ]
}

@test "lb_compare_versions 1.0-beta -le 1.0.0-beta.0" {
	run lb_compare_versions 1.0-beta -le 1.0.0-beta.0
	[ "$status" = 0 ]
}

@test "lb_compare_versions 1.0-beta -lt 1.0.0-rc" {
	run lb_compare_versions 1.0-beta -lt 1.0.0-rc
	[ "$status" = 0 ]
}

@test "lb_compare_versions 1.0-beta -le 1.0.0-beta" {
	run lb_compare_versions 1.0-beta -le 1.0.0-beta
	[ "$status" = 0 ]
}


#
# lb_is_comment
#

@test "lb_is_comment -s" {
	run lb_is_comment -s
	[ "$status" = 1 ]
}

@test "lb_is_comment -n" {
	run lb_is_comment -n
	[ "$status" = 3 ]
}

@test "lb_is_comment Hello" {
	run lb_is_comment Hello
	[ "$status" = 2 ]
}

@test "lb_is_comment -s '//' '# Not a comment'" {
	run lb_is_comment -s '//' '# Not a comment'
	[ "$status" = 2 ]
}

@test "lb_is_comment '# Comment'" {
	run lb_is_comment '# Comment'
	[ "$status" = 0 ]
}

@test "echo '# Comment' | lb_is_comment" {
	output=$(echo '# Comment' | lb_is_comment; echo $?)
	[ "$output" = 0 ]
}

@test "lb_is_comment '    # Comment'" {
	run lb_is_comment '    # Comment'
	[ "$status" = 0 ]
}

@test "lb_is_comment -s '//' '//Comment'" {
	run lb_is_comment -s '//' '//Comment'
	[ "$status" = 0 ]
}
