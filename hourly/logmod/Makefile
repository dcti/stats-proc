.PHONY: all
all: logmod

logmod: logmod.cpp
	c++ -g -O2 -o logmod logmod.cpp

.PHONY: test
test: test-logmod.sh logmod
	sh ./test-logmod.sh

.PHONY: clean
clean:
	rm -f logmod logmod.core test-test
