Feature: git wt
  `git wt` wraps `git worktree` and adds automatic copying of ignored files
  that match `.worktreeinclude` when creating a new worktree.

  Background:
    Given a Linux environment with bash and git

  Scenario: Show built-in help
    When the user runs `git wt help`
    Then usage information is shown
    And the help mentions `.worktreeinclude`

  Scenario: Pass through non-add subcommands
    Given an existing Git repository
    When the user runs `git wt list --porcelain`
    Then the command behaves like `git worktree list --porcelain`

  Scenario: Copy an ignored file after adding a worktree
    Given an existing Git repository
    And `.gitignore` contains `.env.local`
    And `.worktreeinclude` contains `.env.local`
    And the source worktree contains ignored file `.env.local`
    When the user runs `git wt add ../feature-worktree`
    Then a new worktree is created
    And `.env.local` is copied to the new worktree

  Scenario: Copy only ignored paths that also match `.worktreeinclude`
    Given an existing Git repository
    And `.gitignore` contains `ignored.local`
    And `.worktreeinclude` contains `*`
    And the source worktree contains ignored file `ignored.local`
    And the source worktree contains unignored file `unignored.local`
    When the user runs `git wt add ../filtered-worktree`
    Then `ignored.local` is copied to the new worktree
    And `unignored.local` is not copied to the new worktree

  Scenario: Copy symlinks and ignored directories
    Given an existing Git repository
    And `.gitignore` contains:
      """
      cache/
      link.local
      """
    And `.worktreeinclude` contains:
      """
      cache/
      link.local
      """
    And the source worktree contains empty directory `cache`
    And the source worktree contains symlink `link.local` -> `README.md`
    When the user runs `git wt add ../assets-worktree`
    Then directory `cache` exists in the new worktree
    And symlink `link.local` points to `README.md` in the new worktree

  Scenario: Do nothing when `.worktreeinclude` is missing
    Given an existing Git repository
    And `.gitignore` contains `.env.local`
    And the source worktree contains ignored file `.env.local`
    When the user runs `git wt add ../plain-worktree`
    Then a new worktree is created
    And `.env.local` is not copied to the new worktree

  Scenario: Fail if copying ignored files fails after worktree creation
    Given an existing Git repository
    And `.gitignore` contains `.env.local`
    And `.worktreeinclude` contains `.env.local`
    And the source worktree contains ignored file `.env.local`
    And copying `.env.local` will fail
    When the user runs `git wt add ../broken-worktree`
    Then the command exits with a non-zero status
    And the new worktree still exists
    And `.env.local` is not copied to the new worktree
