---
tags: workflow, ai
summary: Here's how I make the most out of Claude Code: my CLAUDE.md rules and a pre-commit hook for Claude to check its own work.
---

# How I use Claude Code

I've made no secret of my mixed feelings about Claude Code, and AI in general. Yes, it makes me more productive, but [at the cost of pride and joy](/articles/2026/ai-productivity-without-joy/) in the craft of being a software developer.

Still, I do use Claude Code to help me with tricky problems or boring busywork. I keep it very simple on purpose: no skills, no MCP, no subagents or multiple agents running in Git worktrees. I like to keep on top of what Claude is doing, interrupting and changing course whenever it goes off in the wrong direction (which it does all the time). It helps me to stay connected with the codebase, and it's the only way I get the highest-quality results that I would write myself.

Over time I've turned the most common reasons to interrupt Claude into `CLAUDE.md` rules, and that does help to reduce the number of times I have to step in. Here's one from a Django project, which explains the Python specifics.

````markdown title="CLAUDE.md"
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

**Where to record new guidance:** before saving anything to per-agent memory, ask "is this a rule the team should follow?" If yes, add it to this file (CLAUDE.md) — it's in git, visible to everyone, and applies to every agent and contributor. Reserve private agent memory for things that are only about how an individual works with their assistant, not shared conventions.

## Overview

[Short overview of the project.]

## Commands

This project uses uv to run Python and manage dependencies.

- `uv run ./manage.py test`: run all tests
- `uv run ruff check .`: lint
- `uv run ruff format .`: format
- `uv run mypy . --check-untyped-defs`: type check

You are never allowed to start the dev server. The server will already be running, and if not, ask for it to be started.

## Communication style — be direct and honest

When writing something intended for human consumption (a comment, commit message, reply to prompt), use as few words as possible. Pick every word meticulously to reduce the volume to a strict minimum. Be down to the point. Less is more. Avoid superlatives and praise (stop telling the human they are "absolutely right"). Be direct and honest, like a Dutch person would, rather than wrapping everything in layers of politeness.

## Accuracy — never guess or assume

**Never present a guess, assumption, or reverse-engineered explanation as established fact.** If you don't actually know something, say so plainly and label your confidence ("I don't know", "this is a guess", "I'd need to verify"). Do not take a symptom and invent a plausible-sounding mechanism to explain it, then assert it as documented behavior — that fabricated certainty causes real wasted work and destroys trust.

- **Use Google.** Search for more information instead of coming up with something yourself.
- **Get evidence before asserting.** Inspect the real environment, read the source, or test it — don't theorize.
- **When evidence isn't available yet, present an explicit hypothesis to verify, never a settled truth.**

## Don't do more than asked for

When asked for a code review, just review the code without running anything. When asked to work on a feature, don't touch unrelated code. Always do the least amount of work to fulfill the request, and note possible follow-ups.

## Never touch production

**Agents do not run anything against production — not writes, not reads, not "just a quick count".** Production access belongs to a human. When production data is needed to diagnose something, write the code and hand it over for a person to run, then work from the output they paste back.

This holds no matter how safe the command looks or how urgent the bug is. Do not look for a way around it: no ssh access, no production database URL, no admin session, no authenticated API call. Reading the public site's unauthenticated pages and JSON endpoints (the same thing any visitor's browser fetches) is fine and is often enough to narrow a bug a long way before asking for a shell query.

When you hand over code that writes, say so explicitly, keep it in its own command, and stop there — the decision to run it is the human's, and it is not yours to assume, encourage, or treat as agreed because they ran a read-only query earlier.

### Handing over Django shell code

**Never hand over shell code as bare Python to paste into a REPL.** The interactive shell mangles pasted indentation, so any loop or `if` breaks. Always give it as a single runnable command with the code in a quoted heredoc:

```bash
uv run ./manage.py shell <<'PY'
from books.models import Book

for b in Book.objects.filter(published=True):
    print(b.id, b.slug)
PY
```

The quoted delimiter (`<<'PY'`, not `<<PY`) stops the shell expanding `$`, and indentation survives because Django `exec`s stdin instead of running a REPL.

Keep read-only queries and anything that writes in **separate** commands, and say plainly which is which — never bury an `update()` or `save()` at the end of a block that looks like a diagnostic.

## Gating incomplete work (feature flags)

Unfinished features are sometimes merged to `staging` so they can be tested before they're done. That is only acceptable if the unfinished work is **fully gated so production keeps behaving exactly as it did before**. `staging` must stay deployable to production at all times. When you gate something, follow these rules:

1. **Gate the whole feature, not just one layer.** A flag on the template/UI is meaningless if the data, queries, or shared helpers that feed it still run in production. Trace every path the feature touches — template, view, context/data functions, model methods, shared utilities — and put each one behind the _same_ flag. A half-gated feature still ships to production through the shared code.

2. **Flag OFF must reproduce current production behavior exactly.** A flag is _additive_: with it off, nothing changes. When you modify a shared function for a new variant, keep the existing behavior as the default branch and add the new behavior under `if flag:`. Never rewrite an existing code path in place — that changes production even when the flag is off.

3. **A gate must not alter or remove behavior that already exists in production.** Don't make an existing option, route, or default behave differently than it does today. Instead, **add a new, separate variant** (e.g. an extra template option) that is only exposed outside production, and leave existing options pinned to their current behavior.

## Code comments

Keep comments short and about the code _as it is now_. A comment must explain what the current code does or why, for someone reading it fresh.

- **If the code is obvious, don't comment it.** A comment that just restates what the code plainly says is noise. Only add one when it earns its place.
- **Plain language a junior can follow.** Describe the situation in everyday terms; avoid framework-internals jargon. Comments are read by the whole team.
- **Never narrate history.** Don't describe what the code used to do, what a previous attempt was, what changed, or why the old approach was abandoned. Git already records this. Such notes are stale the moment they're written and add noise.
- **No changelogs, dates, names, or PR/review references in code.** That context belongs in the commit message or PR description.
- **Prefer one or two plain sentences** over multi-line paragraphs. If a comment needs a paragraph to justify the code, the code usually needs rework, not the essay.
- Comment the non-obvious _why_ (a workaround for a specific client bug, an ordering constraint), not the obvious _what_.

## Code style

- **Imports go at the top of the file.** Never put imports inside functions or fixtures to dodge ordering/lint warnings. The only acceptable inline import is to break a genuine circular import.
- **Never put a real email address (or other real user PII) in code, comments, or tests.** Real members' data must not leak into our code. Use the reserved example domains for placeholders — `john@example.com`, `name@example.org`.

## Testing

- **Write the failing test first, then fix.** When fixing a bug or a performance regression, add the test against the unfixed code and watch it fail, then apply the fix and watch it pass. Don't write the test after the fix and then temporarily undo the fix to prove the test works — that is slower and risks leaving a partly-reverted file behind.
- **N+1 regression tests must vary the row count and assert the _total_ query count is constant — not a single-table count on one row.** A one-row test cannot detect an N+1: a per-row query is indistinguishable from a constant when there is only one row. Build the page with ≥2 rows, capture queries with `CaptureQueriesContext`, then build it again with more rows and assert the query count did not grow. Counting only one table hides per-row queries on _other_ relations. Make rows heterogeneous so optional relations are actually hit, and run the check across each filter/sort path, since each builds the queryset differently.

## Lint and format before committing

**Always run both `uv run ruff format .` and `uv run ruff check .`** before finishing or committing. `format` only reformats; `check` is what catches lint errors like unused imports, and CI runs it — so `format` alone is not enough.

## Self-review before committing

**Read your own diff against the rules in this file before every commit.** Not the code you remember writing — the actual `git diff --cached`. Comments in particular get written mid-fix, while the reasoning is still fresh and the old code is still in mind, and they read very differently once that context is gone. Reviewing at commit time is the only point where you see them the way the next person will.

Walk the diff and check each rule that the change touches:

- **Comments** — does each one describe the code as it is now? Delete anything that contrasts with a previous approach, restates what the code plainly says, or justifies the change rather than explaining the code.
- **Imports** at the top of the file, not inside functions.
- **No real email addresses or user PII** anywhere in code, comments, or tests.
- **Backticks** around code references in the commit message, and keep the "why" to a few plain sentences.

Fix what you find.

## Commit messages and PR descriptions

- **Wrap code references in backticks** — function/variable/class names, symbols, file paths, regex/string literals, and hex character codes (e.g. `clean_cell_value`, `ILLEGAL_FOR_EXCEL_RE`, `0x80-0x9f`, `U+0094`). Plain prose stays unformatted.
- **Keep the "why" short — a few plain sentences stating what changed and why.** Don't pad it with legacy-system asides, hedging parentheticals ("the old Django table did X, now shadowed…"), or every edge case surfaced during investigation. Those conflate the change with everything adjacent to it and make it harder to review. Put mechanical/technical detail in the diff or a "Changes" section, and edge cases in a table or the code — not the intro.
- **No per-file "Changes" table.** Walking the reader file by file repeats what the diff already shows. Describe the change in plain English instead.
````

During long coding sessions, Claude still seems to forget some of these rules. For example, I see Claude suddenly adding very long code comments that literally describe what the code is doing. This is not useful, as we can simply read the code itself. To combat this, there's one more piece to the puzzle: a self-review hook. It reads the "Self-review before committing" section straight out of `CLAUDE.md` and injects it into Claude's context before every `git commit`, so the diff gets checked against the rules before it's committed.

```bash title=".claude/hooks/claude-md-self-review.sh"
#!/usr/bin/env bash
# Fires before every Bash tool call. When the command is a git commit, injects the
# "Self-review before committing" section of CLAUDE.md so the diff gets read before
# it is committed. The section is read at runtime, so CLAUDE.md stays the only copy.
set -uo pipefail

# Emit the checklist (or, when it cannot be found, a warning plus a fallback
# instruction so the commit is still reviewed against CLAUDE.md by hand).
emit() {
  jq -n --arg context "$1" --arg warning "${2:-}" '
    {hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $context}}
    + (if $warning == "" then {} else {systemMessage: $warning} end)
  '
  exit 0
}

FALLBACK="Self-review before committing: this hook could not read the checklist out of
CLAUDE.md, so read the file's \"Self-review before committing\" section yourself and check
\`git diff --cached\` against it before committing."

command=$(jq -r '.tool_input.command // ""' 2>/dev/null || echo "")

case "$command" in
*"git commit"*) ;;
*) exit 0 ;;
esac

claude_md="${CLAUDE_PROJECT_DIR:-.}/CLAUDE.md"
[ -r "$claude_md" ] || emit "$FALLBACK" "Self-review hook: cannot read $claude_md, so it is falling back to a generic reminder instead of the checklist."

# Print the section from its heading up to the next one.
checklist=$(awk '
  /^## / {
    if (inside) exit
    if ($0 == "## Self-review before committing") inside = 1
  }
  inside { print }
' "$claude_md")

# Nothing but the heading means the section was renamed or removed.
if [ "$(printf '%s\n' "$checklist" | wc -l)" -le 1 ]; then
  emit "$FALLBACK" "Self-review hook: no '## Self-review before committing' section in CLAUDE.md — it was renamed or removed, so the hook is falling back to a generic reminder instead of the real checklist. Fix the heading or update .claude/hooks/claude-md-self-review.sh."
fi

emit "$checklist"
```

To enable the hook, add it to Claude's settings file:

```json title=".claude/settings.json"
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/claude-md-self-review.sh\"",
            "statusMessage": "Checking the diff against CLAUDE.md",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

> [!NOTE]
> Yes, this means I commit the `.claude` folder to Git. Only `.claude/settings.local.json` is gitignored.

In my experience this helps a lot, especially when it comes to overly verbose comments which kept creeping back in.

Do you have any rules which should be added to every project's `CLAUDE.md` file? Let me know!