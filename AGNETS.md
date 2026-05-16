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

- `run` is the user-facing entry point
- common flow should stay in `run`
- platform-specific helper functions belong in `abstracts/<os>.sh`
- macOS and Linux are the primary targets
- load the platform module before common helpers and checks
- keep command flow aligned with profile operations: `current`, `hosts`,
  `profiles`

## abstract layers

- `inspect` is for current state, configured values, and active checks such as
  the active profile and resolved SSH target details
- `lookup` is for local table or data lookups such as host aliases, profile
  entries, and derived target mappings
- `resolve` is for name and address resolution such as SSH host expansion,
  `HostName` lookup, and profile-scoped address selection
- `network` is for shared subnet math, host range iteration, and related
  helpers when those capabilities are required
- keep these boundaries explicit when adding new helper functions
- keep these boundaries as function groups inside each platform module even
  when they share one file
- prefer putting OS-specific SSH config inspection and probe wrappers in
  `inspect` rather than in command files

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

- support profile-scoped SSH host management: add, remove, list, and change
- support active profile switching
- support profile add, remove, list, and change
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
