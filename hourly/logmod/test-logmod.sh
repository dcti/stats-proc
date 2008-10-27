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
    if [ x$3 != x ]; then
        in=$in.$3
        out=$out.$3
        opts="$opts -${3}"
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
run_test ogrp2
run_test ogrng
#run_test rc572 logdb
#run_test ogr logdb
#run_test ogrp2 logdb
run_test ogr pproxy
#run_test ogrp2 pproxy
#run_test ogr logdb pproxy
#run_test ogrp2 logdb pproxy
