#!/bin/sh

./logmod -rc572 < test-input.rc572 > test-test
cmp test-output.rc572 test-test
rc=$?
if [ $rc -ne 0 ]; then
    echo "FAILED"
    diff test-output.rc572 test-test
    exit 1
fi
echo "PASSED"
