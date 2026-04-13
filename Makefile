.PHONY: fmt lint test

SHELL_SCRIPTS := git-wt tests/test_git_wt.sh

fmt:
	shfmt -w $(SHELL_SCRIPTS)

lint:
	shellcheck $(SHELL_SCRIPTS)

test:
	./tests/test_git_wt.sh
