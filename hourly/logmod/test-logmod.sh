#!/bin/sh

run_test () {
    ./logmod -$1 < test-input.$1 > test-test 2>&1
    cmp test-output.$1 test-test
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "FAILED"
        diff -u test-output.$1 test-test
        exit 1
    fi
    echo "$1 PASSED"
    rm -f test-test
}

make
run_test rc572
run_test ogr
