#!/bin/sh

run_test () {
    ./logmod -$1 < test-input.$1 > test-test
    cmp test-output.$1 test-test
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "FAILED"
        diff test-output.$1 test-test
        exit 1
    fi
    echo "$1 PASSED"
    rm -f test-test
}

run_test rc572
run_test ogr
