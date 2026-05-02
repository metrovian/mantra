# sanctuary agent guide

## mission

This repository is for building command-line tools that can inspect a network with one-touch execution and leave usable records behind.

The long-term goal is:

- bring up a network
- run a small set of commands
- complete validation quickly
- preserve the results as operational records

Every change should support that direction. Prefer simple commands, clear output, and structures that can grow into automated checks and report generation.

## working style

- keep the main command flow easy to read
- split platform-specific behavior only where the operating systems differ
- prefer minimal MVP implementations over broad abstractions
- make output readable for operators first
- design commands so they can later write records without major rewrites

## current command direction

- `run` is the user-facing entry point
- common flow should stay in `run`
- platform-specific helper functions belong in abstract files
- macOS and Linux are the primary targets

## abstract layers

- `inspect` is for current state, configured values, and reachability
- `lookup` is for local table or data lookups such as `MAC` and vendor
- `resolve` is for name and address resolution such as `PTR` and `A` records
- keep these boundaries explicit when adding new helper functions

## file ownership

- do not modify `README.md` unless the user explicitly asks
- do not commit `README.md` unless the user explicitly asks

## naming and output

- keep user-facing log messages in lowercase unless the term is a standard acronym such as `OS`, `IP`, or `MAC`
- readability matters more than clever formatting
- prefer keeping lines within 88 characters when practical

## output formatters

- use `pair` for titled key-value blocks such as `LOCAL` and `DNS`
- use `table` for row-based outputs with shared columns such as neighbor inventories
- do not hand-write spacing for these outputs inside check files
- let `pair` and `table` calculate spacing and separator width automatically
- keep check files focused on values and order, not on presentation details

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
- if a commit title feels broad, split the work into smaller commits or rewrite the title to focus on the main action
- amending the last commit is acceptable before push when the message needs correction

## decision rule

When choosing between abstraction and momentum, prefer the version that keeps today's command usable while leaving a clear path for tomorrow's checks and record output.
