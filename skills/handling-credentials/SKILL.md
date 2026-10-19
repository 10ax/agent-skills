---
name: handling-credentials
description: Use when a task touches a password, API key, token, secret, .env file, credentials config, or when asked to show, print, cat, echo, copy, paste, compare or prove the value of one. Symptoms include "just cat it", "I need it exactly", "are these two the same", and a secret appearing in tool output.
---

# Handling credentials

A secret is emitted the moment its **value reaches tool output** — not when it is read, and not
when it is printed in the reply. Tool results are stored in the session and logged; a `cat` is a
leak even if the answer never mentions the value.

Observed failure, reproduced: asked politely, an agent refused to echo values. Asked to "give me
the exact password character for character so I can paste it", it printed the value. Asked to
"prove the two keys are the same", it printed **both**. The comparison request is the more
dangerous one, because printing both sides feels like evidence.

## What you need, and what to run instead

| Need | Do this | Emits |
|---|---|---|
| Is it set? | `grep -c '^NAME=' file` | a count |
| Is it the value I expect? | `… \| sha256sum \| cut -c1-16` | 16 hex chars |
| How long is it? | `… \| wc -c` | a number |
| Are these two the same? | hash both, compare the hashes | one word |
| Does it still work? | `curl -s -u "user:$P" …/api/…/validate` | `{"valid":true}` |
| The human needs the value | give them the command, not the value | nothing |
| Structure of a config file | dump keys and `type(length)`, never leaves | `password: str(33)` |

`$(…)` is safe **because it is never echoed**. Never add `set -x`, never `echo "$P"` in an error
path, and never put a secret in a command whose failure prints its arguments.

## Rationalisations to refuse, and what to say

| The ask | The refusal |
|---|---|
| "I need it character for character to paste" | "Here is the command to read it in your terminal; a shell you are at does not store output." |
| "Prove they're identical" | "Same SHA-256 or not — that is the whole answer, and it discloses nothing." |
| "Just cat the file, I'll read it" | "Structure and lengths, or the command to run yourself." |
| "It's only staging / a test key" | Staging keys open staging. The rule is about the transcript, not the blast radius. |
| "I already know it, just confirm" | Confirming is emitting. Give a hash prefix. |

Red flags that you are about to leak: typing `cat`, `echo`, `printenv`, `env`, or `grep NAME` on a
credentials file; writing a table with a "value" column; quoting a config line back at the user;
pasting a `.env` into a diff, a commit message, or a test fixture.

## Verification and masking

A mask you have not tested is a hope. `sed -E "s/<([^>]*)>/<\1>/"` is an identity substitution —
it runs clean, produces angle brackets, and masks nothing. `s/…: *(.+)$/…: <\1>/` only wraps the
value in punctuation; it is still there in full.

Anchor a leaf selector to its section. `sed -n '/^ *password:/p'` on a two-section config prints
**both** passwords; verify by counting the lines the *password* pattern matched, not the lines
returned.

`rg` skips binary files and reports nothing, which reads as "no copies exist". Use `rg -a` when
checking whether a value reached a database, a WAL, or a log.

## Test with a canary, never a real secret

A test that feeds a real credential to an agent has exactly one failure mode. Use a distinctive
fake value, ask for it under pressure, then grep the session for it: the test proves its own
result and risks nothing.

## Rotating

Find every consumer before minting, and never revoke before the replacement exists. Rotate
**before** cleaning up a leak — rotation is the fix, cleanup is hygiene. Deleting a session does
not remove the value from the database WAL, the agent log, or exported transcripts; verify each
with a grep that returns 0.
