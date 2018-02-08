ASM=dasm
TESTER=./test_runner.py

TEST_HARDWARE=serial,clock
RUN_CMD=dcpu -hw $(TEST_HARDWARE) lisp.bin

TESTS=tests/values.bsl tests/builtins.bsl tests/env.bsl tests/if_fn_do.bsl


lisp.bin: *.asm
	$(ASM) main.asm $@

build: lisp.bin

default: build

clean: FORCE
	rm -f lisp.bin test.mal

test1: tests/values.bsl build FORCE
	$(TESTER) $< -- $(RUN_CMD)

test2: tests/builtins.bsl build FORCE
	$(TESTER) $< -- $(RUN_CMD)

test3: tests/env.bsl build FORCE
	$(TESTER) $< -- $(RUN_CMD)

test4a: tests/if_fn_do.bsl build FORCE
	$(TESTER) $< -- $(RUN_CMD)

test4b: tests/strings.bsl build FORCE
	$(TESTER) $< -- $(RUN_CMD)

test4: tests/if_fn_do.bsl tests/strings.bsl build FORCE
	cat tests/if_fn_do.bsl tests/strings.bsl > test.mal
	$(TESTER) test.mal -- $(RUN_CMD)
	rm -rf test.mal

test: $(TESTS) build FORCE
	cat $(TESTS) > test.mal
	$(TESTER) test.mal -- $(RUN_CMD)
	rm -rf test.mal

FORCE:


