# marionette agent guide

## working style

- keep the main command flow easy to read
- split platform-specific behavior only where operating systems differ
- prefer minimal mvp implementations over broad abstractions
- make output readable for operators first
- design changes so they can later support automated checks and record output

## shell compatibility

- keep shell code compatible with the default macOS `bash 3.2`
- avoid bash 4+ features such as `mapfile`, associative arrays, and `readarray`
- prefer simple loops and explicit data collection over version-specific
  helpers
- treat macOS compatibility as a default requirement, not a later cleanup

## shell format

- use `#!/usr/bin/env bash` for executable bash entrypoints
- keep executable command files in this order: shebang, `set -euo pipefail`,
  `ROOT_DIR`, one blank line, then sourcing
- use `ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"` in top-level command files
- prefer `source_modules \` with one module path per continued line
- declare `local` variables at the top of a function before assignments
- keep function bodies compact with no extra blank lines between adjacent
  statements
- keep exactly one blank line between top-level function definitions
- keep one blank line between the sourcing block and the first function
- keep one blank line before the final `main "$@"` call
- wrap long commands with continuation indentation instead of adding temporary
  variables only for formatting

## file ownership

- do not modify `README.md` unless the user explicitly asks
- do not commit `README.md` unless the user explicitly asks

## naming and output

- keep user-facing log messages in lowercase unless the term is a standard
  acronym such as `OS`, `IP`, `SSH`, or `MAC`
- readability matters more than clever formatting
- prefer keeping lines within 88 characters when practical
- prefer short names when the meaning is already clear
- prefer measured or concrete values over boolean status when they help
  diagnostics more directly

## commit rules

- make commits in small, meaningful units
- prefer one logical change per commit
- follow google-style commit titles in lowercase
- prefer a title only, without a body, unless more detail is necessary
- use a prefix form such as `add: ...`, `fix: ...`, `refactor: ...`
- avoid `and` in commit titles when possible
- if a commit title feels broad, split the work into smaller commits or rewrite
  the title to focus on the main action
- amending the last commit is acceptable before push when the message needs
  correction

## decision rule

when choosing between abstraction and momentum, prefer the version that keeps
today's command flow readable with the fewest moving parts.
