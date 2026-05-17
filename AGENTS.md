# sanctuary agent guide

## working style

- keep the main command flow easy to read
- split platform-specific behavior only where the operating systems differ
- prefer minimal mvp implementations over broad abstractions
- make output readable for operators first
- design changes so they can later support automated checks and record output

## shell compatibility

- keep shell code compatible with the default macOS `bash 3.2`
- avoid bash 4+ features such as `mapfile`, associative arrays, and `readarray`
- prefer simple loops and explicit data collection over version-specific shell helpers
- treat macOS compatibility as a default requirement, not a later cleanup

## shell format

- use `#!/usr/bin/env bash` for executable bash entrypoints
- keep executable entrypoints in this order: shebang, `set -euo pipefail`, startup variables such as `ROOT_DIR` and `OS`, one blank line, then helpers or sourcing
- prefer `source_modules \` with one module path per continued line
- declare `local` variables at the top of a function before assignments
- keep function bodies compact with no extra blank lines between adjacent statements
- keep exactly one blank line between top-level function definitions
- use continuation indentation for long pipelines, command substitutions, and argument lists
- keep inline `shellcheck` suppressions immediately above the affected `source` line or command

## file ownership

- do not modify `README.md` unless the user explicitly asks
- do not commit `README.md` unless the user explicitly asks

## naming and output

- keep user-facing log messages in lowercase unless the term is a standard acronym such as `OS`, `IP`, or `MAC`
- readability matters more than clever formatting
- prefer keeping lines within 88 characters when practical
- prefer short names when the meaning is already clear
- prefer measured values over boolean status when they help diagnostics more directly

## commit rules

- make commits in small, meaningful units
- prefer one logical change per commit
- follow google-style commit titles in lowercase
- prefer a title only, without a body, unless more detail is necessary
- use a prefix form such as `add: ...`, `fix: ...`, `refactor: ...`
- if a commit title feels broad, split the work into smaller commits or rewrite the title to focus on the main action
- amending the last commit is acceptable before push when the message needs correction

## decision rule

when choosing between abstraction and momentum, prefer the version that keeps today's command flow readable with the fewest moving parts.
