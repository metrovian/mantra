# marionette agent guide

## mission

This repository is for managing SSH hosts by router profile with one-touch
profile switching and usable records of the configured targets.

The long-term goal is:

- manage SSH hosts by profile
- switch the active profile quickly
- keep profile changes easy to inspect
- preserve the resulting configuration as operational records

Every change should support that direction. Prefer simple commands, clear
output, and structures that can grow into automated checks and record
generation.

## working style

- keep the main command flow easy to read
- split platform-specific behavior only where the operating systems differ
- prefer minimal MVP implementations over broad abstractions
- make output readable for operators first
- design commands so they can later write records without major rewrites
- keep blank lines minimal inside functions
- keep a single blank line between top-level functions

## shell compatibility

- keep shell code compatible with the default macOS `bash 3.2`
- avoid bash 4+ features such as `mapfile`, associative arrays, and `readarray`
- prefer simple loops and explicit data collection over version-specific shell
  helpers
- treat macOS compatibility as a default requirement, not a later cleanup

## current command direction

- keep the top-level command files easy to read
- use top-level commands such as `status`, `profile`, `host`, `create`,
  `delete`, `use`, `attach`, `detach`, and `run`
- keep `run` focused on ssh execution for the current profile
- keep `profile` and `host` focused on list output
- keep shared helpers in `utils/`, `profiles/common.sh`, and `hosts/common.sh`
- macOS and Linux are the primary targets
- keep command flow aligned with profile operations: `status`, `profile`,
  `host`

## abstract layers

- `utils/` is for global helpers such as paths, validation, output, and module
  sourcing
- `profiles/common.sh` is for shared profile operations such as current
  profile lookup, profile creation, removal, and listing
- `hosts/common.sh` is for shared host operations such as host lookup,
  attachment, detachment, listing, and generated ssh config output
- keep command-specific behavior in the top-level command file when it is used
  by only one command
- move a helper out of a command file only when another command actually shares
  it

## file ownership

- do not modify `README.md` unless the user explicitly asks
- do not commit `README.md` unless the user explicitly asks

## naming and output

- keep user-facing log messages in lowercase unless the term is a standard
  acronym such as `OS`, `IP`, `SSH`, or `MAC`
- readability matters more than clever formatting
- prefer keeping lines within 88 characters when practical
- prefer short names such as `profile` and `host` when the meaning is already
  clear
- prefer measured or concrete values over boolean status when they help
  diagnostics more directly, such as the selected profile path over a changed
  flag

## domain model

- call each router-specific environment a profile
- profiles represent stable places such as company, home, or a lab
- hosts belong to profiles rather than to one global flat list
- the active profile determines which SSH host definitions are materialized for
  use
- the project exists to avoid repeated unknown hosts friction caused by reused
  IP space across different places while keeping target control convenient

## profile operations

- support profile-scoped SSH host management: attach, detach, and list
- support active profile switching
- support profile create, delete, list, and change
- keep profile data easy to inspect and rewrite
- prefer changes that can later emit records of what profile was active and
  what hosts were installed

## output formatters

- use `pair` for titled key-value blocks such as `current`
- use `table` for row-based outputs with shared columns such as host
  inventories
- do not hand-write spacing for these outputs inside command files
- let `pair` and `table` calculate spacing and separator width automatically
- keep command files focused on values and order, not on presentation details
- keep pair blocks ordered from the most diagnostic field to the most
  identifying field when practical

### pair usage

- call `pair_reset`
- call `pair_set_title` once
- call `pair_add` for each key-value line
- call `pair_print` at the end

### table usage

- call `table_reset`
- call `table_set_headers` once
- call `table_add_row` for each row
- call `table_print` at the end

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

When choosing between abstraction and momentum, prefer the version that keeps
today's profile command usable while leaving a clear path for tomorrow's
profile-aware checks and record output.
