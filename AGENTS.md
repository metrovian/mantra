# mantra agent guide

## mission

this repository is for managing scattered script repositories as root-level
`git submodule`s and giving operators a simple way to initialize them.

the long-term goal is:

- collect distributed tools in one place
- initialize submodules and third-party dependencies with one command
- keep each module's own `run` entrypoint intact
- keep the root flow simple and readable

every change should support that direction. prefer simple commands, clear
output, and minimal structure.

## working style

- keep the main command flow easy to read
- prefer minimal mvp implementations over broad abstractions
- make output readable for operators first
- design commands so they can later write records without major rewrites
- keep blank lines minimal inside functions
- keep a single blank line between top-level functions

## shell compatibility

- keep shell code compatible with `bash`
- avoid shell features that complicate portability without a clear need
- prefer simple loops and explicit data collection over version-specific shell helpers
- uppercase global variables are allowed for file-wide constants such as `ROOT_DIR`

## current command direction

- the root bootstrap script lives in `./3rdparty/setup-debian.sh`
- the bootstrap script should update submodules before invoking module-level setup scripts
- each module exposes its third-party setup script at `./<module>/3rdparty/setup-debian.sh`
- modules live at the repository root, not inside a grouping directory
- `./<module>/run` is the module's primary runtime entrypoint
- keep the setup flow obvious: update, scan modules, run module setup

## file ownership

- keep development context in this `agents.md` file
- do not use a `docs/` directory for project documentation
- do not modify `README.md` unless the user explicitly asks
- do not commit `README.md` unless the user explicitly asks

## naming and output

- keep user-facing log messages in lowercase unless the term is a standard acronym
- readability matters more than clever formatting
- prefer keeping lines within 88 characters when practical
- prefer short names when the meaning is already clear
- use uppercase names for file-wide constants and lowercase names for local variables
- make run and skip messages explicit so operators can see what the bootstrap did

## commit rules

- make commits in small, meaningful units
- prefer one logical change per commit
- follow google-style commit titles in lowercase
- prefer a title only, without a body, unless more detail is necessary
- use a prefix form such as `add: ...`, `fix: ...`, `refactor: ...`
- avoid `and` in commit titles when possible
- if a commit title feels broad, split the work into smaller commits or rewrite the title to focus on the main action
- amending the last commit is acceptable before push when the message needs correction

## decision rule

when choosing between abstraction and momentum, prefer the version that keeps
today's bootstrap flow readable with the fewest moving parts.
