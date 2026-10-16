---
name: maker-tracker
description: How to work with Maker Tracker from this repo using the mt CLI. Use it when asked "what's next?", when picking up, building or closing a story, when leaving a question or a decision, and when writing or reordering the backlog (stories, milestones, brief).
---

# Maker Tracker with `mt`

Maker Tracker holds the product definition of this repo: brief, decisions, roadmap (milestones in order) and stories. The code lives here; the what and the why, there. `mt` talks to its API. The project comes from `.mt` at the root of the repo, and stories are named `PG-49` or just `49`.

When the session starts you already have the output of `mt context` (brief, decisions in force, current milestone and what is in progress). If it is missing, run it before recommending anything: the decisions and the principles in the brief come first.

`mt` speaks English; the content (titles, story bodies, brief, decisions) comes in the language it was written in. Keep writing content in that language.

## Reading the output

- Every command ends with **`Next:`**: the commands that make sense to run afterwards. Use them instead of guessing.
- **`Warning:`** lines don't block, but read them: a story without context, blocked, without criteria, without commits… If a warning changes what you are going to do, say so.
- Errors go to stderr in two lines, `Error: …` and `Hint: …`. Follow the hint before trying something else. Exit code 1, or 2 if the command itself is wrong.
- References are always complete (`PG-49`, `D-14`, `M2`) and dates absolute (`2026-10-15 22:40`, or just the time if it is today), so you can copy them into a commit and compare them with `git log`.
- `--json` prints the API envelope as is, if you need structured data.

## The development loop

1. **"What's next?"** → `mt next`. It gives you the first ready, unblocked story in the roadmap, whole, with why it is that one. Don't pick another one on your own unless asked.
2. `mt start PG-49`: claims it in your name and moves it to in progress. If someone else has it (`CLAIMED_BY_OTHER`), take another one.
3. Read the whole story (`mt show PG-49`): context, acceptance criteria, out of scope, notes and the mockup if it has one. Build it in this repo, meeting every criterion.
4. `mt done PG-49 --commit <sha> [--commit <sha>…] [--pr <url>]`: closes it, linking the code. Without commits or PR nobody will know where it is.

A story is done whole or not closed. If something is left out when you finish, say it in a comment before `mt done`.

## Questions and blockers

- Ask in the story: `mt comment PG-49 "…"` (markdown; `-` reads from stdin). That's where whoever defines the product sees it, not in the chat.
- If the question blocks you, let the story go and carry on with another one: `mt release PG-49 --reason "Still to decide …"` and `mt next`.
- Don't invent scope to unblock yourself.

## Decisions

Record a decision when you choose between options someone will want to know about later (a library, a format, a limit, something left out): `mt decide "Templates as JSON" --why "…" --story PG-49`. If it replaces another one, `--supersedes D-9`. Decisions are not edited: to change one, write another that supersedes it. Implementation details that don't change the product go in the closing comment, not here.

## Writing the product

Agents also write the backlog, directly and on the record (every change is logged in your name):

- **Create**: `mt create "Title" [--milestone M2] [--state defining]`, or from a file: `mt create --file f.md`. Without a milestone it goes to the inbox; without a state, it is an idea.
- **Edit**: `mt show PG-49 > f.md`, change the file and `mt edit PG-49 --file f.md`. Everything below the `<!-- mt: read-only … -->` mark (related, comments, history) is ignored. Editing doesn't change the state or the milestone.
- **Body template** (in the project's language; in Spanish: `## Contexto` · `## Historia` · `## Criterios de aceptación` · `## Fuera de alcance` · `## Notas para quien lo construya` · `## Preguntas abiertas`): why and what exists already · As a…, I want…, so that… · checkable criteria as `- [ ] …` · out of scope · notes for whoever builds it · open questions.
- **State**: `mt move PG-49 ready` only if it has no open questions and, if it is UI work (label `ui`), it has a mockup. If `mt` warns that it doesn't meet the rule, move it back to defining or fix it.
- **Order**: order is priority. `mt reorder PG-49 --position 1 [--milestone M3] --reason "…"` and `mt milestone reorder M3 --position 2 --reason "…"`. **Always with a reason**: it's what gets read later. If the change matters, also record it with `mt decide`.
- **Milestones and brief**: `mt milestone create|edit|close|reopen`, `mt brief` to read it and `mt brief --file f.md` to replace it.

## Commands

- Read: `mt context` · `mt next` · `mt roadmap [--closed]` · `mt show PG-49` · `mt list [--state …] [--milestone …] [--label …] [--mine]` · `mt decisions`
- Work: `mt start` · `mt done --commit` · `mt release --reason` · `mt comment` · `mt decide --why`
- Define: `mt create` · `mt edit --file` · `mt move` · `mt reorder --reason` · `mt brief` · `mt milestone …`

`mt help` and `mt <command> --help` have the details and an example of each.
