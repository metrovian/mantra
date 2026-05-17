# mantra agent guide

## mission

- collect distributed tools in one place
- initialize submodules and third-party dependencies with one command
- keep each module's own `run` entrypoint intact
- keep the root flow simple and readable

## working style

- keep the main command flow easy to read
- prefer minimal mvp implementations over broad abstractions
- make output readable for operators first
- design changes so they can later support automated checks and record output

## shell compatibility

- keep shell code compatible with `bash`
- keep shell code compatible with the default macOS `bash 3.2` unless a file already targets a narrower environment
- avoid bash 4+ features such as `mapfile`, associative arrays, and `readarray`
- prefer simple loops and explicit data collection over version-specific helpers

## shell format

- use `#!/usr/bin/env bash` for executable bash entrypoints
- keep executable command files in this order: shebang, `set -euo pipefail`, startup variables such as `ROOT_DIR` and `OS`, one blank line, then helpers or sourcing
- use `ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` in top-level command files that need a repository root
- prefer `source_modules \` with one module path per continued line when loading multiple shell modules
- declare `local` variables at the top of a function; simple declaration with assignment is acceptable when it keeps the function shorter
- keep function bodies compact with no extra blank lines between adjacent statements
- keep exactly one blank line between top-level function definitions
- keep one blank line before the final `main "$@"` call in entrypoint scripts
- use continuation indentation for long pipelines, command substitutions, and argument lists
- keep inline `shellcheck` suppressions immediately above the affected `source` line or command

## current command direction

- the root bootstrap script lives in `./setup`
- root-level submodule management scripts live in `./add` and `./remove`
- the bootstrap flow should stay obvious: update submodules, scan modules, run module setup

## file ownership

- keep development context in this `AGENTS.md` file
- do not use a `docs/` directory for project documentation
- do not modify `README.md` unless the user explicitly asks
- do not commit `README.md` unless the user explicitly asks

## naming and output

- keep user-facing log messages in lowercase unless the term is a standard acronym such as `OS`, `IP`, `SSH`, or `MAC`
- readability matters more than clever formatting
- prefer keeping lines within 88 characters when practical
- prefer short names when the meaning is already clear
- prefer measured or concrete values over boolean status when they help diagnostics more directly

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
