#!/usr/bin/env bash

declare -i tests_run=0

function testcase {
	local descr=$1
	local input=$2
	local expected=$3

	#echo "descr='$descr'"
	#echo "input='$input'"	
	#echo "expected='$expected'"

	_get_completions "$input"
	#echo "COMPREPLY=$COMPREPLY"
	local actual="${COMPREPLY[@]}"

	[ "$actual" = "$expected" ] && { echo -n "."; let tests_run+=1; return; }
	 printf "\nFAIL: $descr\n'actual: $actual' != 'expected: $expected'\n"; exit 1
}

# https://brbsix.github.io/2015/11/29/accessing-tab-completion-programmatically-in-bash/
function _get_completions() {
	#echo "_get_completions: \$1='$1'"

	COMPREPLY=()
	local completion COMP_CWORD COMP_LINE COMP_POINT COMP_WORDS

	# load bash-completion if necessary
	declare -F _completion_loader &>/dev/null || {
		source /usr/share/bash-completion/bash_completion
	}

	COMP_LINE=$*
	COMP_POINT=${#COMP_LINE}

	eval set -- "$@"

	COMP_WORDS=("$@")

	# add '' to COMP_WORDS if the last character of the command line is a space
	[[ ${COMP_LINE[@]: -1} = ' ' ]] && COMP_WORDS+=('')

	# index of the last word
	COMP_CWORD=$(( ${#COMP_WORDS[@]} - 1 ))

	# determine completion function
	completion=$(complete -p "$1" 2>/dev/null | awk '{print $(NF-1)}')

	# run _completion_loader only if necessary
	[[ -n $completion ]] || {

		# load completion
		_completion_loader "$1"

		# detect completion
		completion=$(complete -p "$1" 2>/dev/null | awk '{print $(NF-1)}')

	}

	# ensure completion was detected
	[[ -n $completion ]] || return 1

	# execute completion function
	"$completion"

	# print completions to stdout
	# printf '%s\n' "${COMPREPLY[@]}" | LC_ALL=C sort
}

#_get_completions 'kudu '

# root kudu complitions 
testcase 'root opts' 'kudu --' '--help --version'
testcase 'commands' 'kudu ' 'cluster fs local_replica master pbc remote_replica table tablet test tserver wal'
testcase 'commands complition' 'kudu tabl' 'table tablet'

# kudu cluster
testcase 'cluster subcommands' 'kudu cluster ' 'ksck'
testcase 'cluster opts' 'kudu cluster --' '--help'

testcase 'cluster ksck master' 'kudu cluster ksck localh' 'localhost'
testcase 'cluster ksck opts' 'kudu cluster ksck --' '--help --checksum_cache_blocks --checksum_scan --checksum_scan_concurrency --nochecksum_snapshot --color --tables --tablets'
testcase 'cluster ksck opts after master' 'kudu cluster ksck localhost --he' '--help'
testcase 'cluster ksck master after opts' 'kudu cluster ksck --checksum_scan localh' 'localhost'

# todo opts with args

testcase 'cluster no complition after unknown subcommand' 'kudu cluster xyz ' ''


echo; echo "PASS: $tests_run tests run"
