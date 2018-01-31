ASM=dasm
TESTER=./test_runner.py

TEST_HARDWARE=serial,clock
RUN_CMD=dcpu -hw $(TEST_HARDWARE) lisp.bin

TESTS=tests/step0_repl.mal


lisp.bin: *.asm
	$(ASM) main.asm $@

build: lisp.bin

default: build

clean: FORCE
	rm -f lisp.bin test.mal

test: build FORCE
	cat $(TESTS) > test.mal
	$(TESTER) test.mal -- $(RUN_CMD)
	rm -rf test.mal

FORCE:


