#!/bin/sh

run_test () {
    in=test-input.$1
    out=test-output.$1
    opts=-$1
    if [ x$2 != x ]; then
        in=$in.$2
        out=$out.$2
        opts="$opts -${2}"
    fi

    ./logmod $opts < $in > test-test 2>&1
    cmp $out test-test
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "FAILED"
        diff -u $out test-test
        exit 1
    fi
    echo "$1 PASSED"
    rm -f test-test
}

make
run_test rc572
run_test ogr
run_test ogr pproxy
