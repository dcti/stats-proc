.PHONY: all
all: logmod

logmod: logmod.cpp
	g++ -O2 -o logmod logmod.cpp

.PHONY: test
test: test-logmod.sh logmod
	sh ./test-logmod.sh
