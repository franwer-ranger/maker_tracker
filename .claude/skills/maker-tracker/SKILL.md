---
name: maker-tracker
description: How to work with Maker Tracker using the mt CLI. Use it when asked "what's next?", when picking up, building or closing a story, when leaving a question or a decision, when writing or reordering the backlog (stories, milestones, brief), and when asked to bring a project to Maker Tracker ("lleva este proyecto a Maker Tracker", "onboard this repo").
---

# Maker Tracker with `mt`

Maker Tracker holds the product definition of this repo: brief, decisions, roadmap (milestones in order) and stories. The code lives here; the what and the why, there. `mt` talks to its API. The project comes from `.mt` at the root of the repo, and stories are named `PG-49` or just `49`.

In a repo that is already in Maker Tracker (it has `.mt`), the session starts with the output of `mt context` (brief, decisions in force, current milestone and what is in progress). If it is missing, run it before recommending anything: the decisions and the principles in the brief come first. If the repo has no `.mt` and you are asked to bring it in, follow "Onboard an existing project".

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

- **`mt ask` when you doubt between options someone has to choose**: `mt ask PG-49 "What if a variable has no value?" --context "…" --option "Drop it" --option "Warn first" --recommend 2 --reversible`. Always give your options (at least 2) and say which one you recommend. The person sees it on the story and in `mt questions` with the options and the command to answer, so they decide at a glance, and you don't have to explain it again in a comment.
  - By default it **blocks**: if the story was yours it lets it go (back to ready) and the story is blocked by the person until they answer. `mt next` skips it. Carry on with another one with `mt next`; don't wait.
  - If you can carry on without the answer, use `--no-bloqueante` (then `--recommend` is required): you keep the story, go on with the recommended option and, if the person answers otherwise, you change it.
  - Say `--reversible` only if the decision can be undone; without it the question doesn't say anything about it (don't assume it is irreversible).
  - A story can have several open questions. See the open ones of every project with `mt questions`. Only a person answers (`mt answer` is refused to agents: `FORBIDDEN`). The answer comes back in the story: `mt show PG-49` has it in `## Questions`.
- **`mt comment` for the rest**: progress, a note, something that is not a choice between options (markdown; `-` reads from stdin). That's where whoever defines the product sees it, not in the chat.
- If you are blocked by something that is not a question (a missing decision of the product, a story that is not ready), let the story go and carry on with another one: `mt release PG-49 --reason "Still to decide …"` and `mt next`.
- Don't invent scope to unblock yourself.

## Decisions

Record a decision when you choose between options someone will want to know about later (a library, a format, a limit, something left out): `mt decide "Templates as JSON" --why "…" --story PG-49`. If it replaces another one, `--supersedes D-9`. Decisions are not edited: to change one, write another that supersedes it. Implementation details that don't change the product go in the closing comment, not here.

## Autonomy

The brief's `## Autonomía` section (or its equivalent in the project's language) says what agents may decide on their own. Read it before writing the product:

- **What it allows, do it.** If it is a choice someone would want to know about later, record it with `mt decide … --story PG-49`.
- **Everything else, ask** in the story (`mt comment`) and wait for the answer, even if `mt` would let you do it.
- If the brief has no such section, ask before marking a story as ready, editing the brief, or creating, reordering or closing milestones.

## Writing the product

Agents also write the backlog, directly and on the record (every change is logged in your name):

- **Create**: `mt create "Title" [--milestone M2] [--state defining]`, or from a file: `mt create --file f.md`. Without a milestone it goes to the inbox; without a state, it is an idea.
- **Edit**: `mt show PG-49 > f.md`, change the file and `mt edit PG-49 --file f.md`. Everything below the `<!-- mt: read-only … -->` mark (related, comments, history) is ignored. Editing doesn't change the state or the milestone. The file carries `version: N` in its frontmatter: keep it, it is how `mt` knows what you read.
- **If `mt edit` (or `mt brief --file`, `mt milestone edit --version`) says `CONFLICT`**: someone changed it after you read it and **nothing was saved**. Don't retry the same file and don't force it. Read it again (`mt show PG-49`, `mt brief`, `mt milestone show M2`), see what changed (the `Hint:` says who and when), apply your changes on top of the new text and edit again with the new version. If both changes touch the same lines and you can't tell what is right, leave a comment (`mt comment`) and ask. Moving, reordering and closing don't use versions.
- **Body template** (in the project's language; in Spanish: `## Contexto` · `## Historia` · `## Criterios de aceptación` · `## Fuera de alcance` · `## Notas para quien lo construya` · `## Preguntas abiertas`): why and what exists already · As a…, I want…, so that… · checkable criteria as `- [ ] …` · out of scope · notes for whoever builds it · open questions.
- **State**: `mt move PG-49 ready` only if it has no open questions and, if it is UI work (label `ui`), it has a mockup. If `mt` warns that it doesn't meet the rule, move it back to defining or fix it.
- **Order**: order is priority. `mt reorder PG-49 --position 1 [--milestone M3] --reason "…"` and `mt milestone reorder M3 --position 2 --reason "…"`. **Always with a reason**: it's what gets read later. If the change matters, also record it with `mt decide`.
- **Milestones and brief**: `mt milestone create|edit|close|reopen`, `mt brief` to read it and `mt brief --file f.md` to replace it (keep its `version:` frontmatter), `mt milestone show M2` to read a milestone with its version.

## Onboard an existing project

When asked to bring the current repo to Maker Tracker ("lleva este proyecto a Maker Tracker: la visión, las decisiones y todo"). Whoever defines the product decides; you propose.

1. **Check `mt`**: `mt projects`. If it says `mt` is not configured (or the token is not valid), ask the person to run `mt setup <url> <token>` themselves and stop there: the token never goes through the chat. If the project is already listed, use `mt init <KEY> --claude` and skip to step 5.
2. **Read the repo**: `README`, `AGENTS.md` / `CLAUDE.md`, `docs/` (product, roadmap, decisions, ADRs, backlog) and recent `git log`. Add what the person tells you.
3. **Propose, in the chat and before writing anything** (no `mt` command that writes yet):
   - the **key** (2 to 5 letters, it names every story: `PG-49`) and the **name**;
   - the **brief** in markdown, with its five sections: `## Visión` · `## Principios` · `## Autonomía` · `## Fuera de alcance` · `## Glosario` (headings in the project's language; these are Maker Tracker's template in Spanish). Short: it is read by every agent at the start of every session;
   - the **milestones** in order, each with a one-line goal;
   - the **decisions** already taken, each with its why (one sentence). Only those that someone would want to know later.

   Say where each thing comes from (which file) and what you made up or left out. Then wait for the OK, and apply the changes the person asks for.
4. **With the OK**, write it:
   ```
   mt project create "Postgram" --key PG
   mt init PG --claude                 # at the root of the repo: .mt and the SessionStart hook
   mt brief --file brief.md
   mt milestone create "Publicar sin fricción" --goal "…"   # one per milestone, in order
   mt decide "PDFs con Prawn" --why "…"                     # one per decision, oldest first
   ```
   Write the files in a temporary place, not in the repo. If a command fails, read the `Hint:` and fix it before going on.
5. **Finish with `mt context`**, show it, and offer to start writing stories with the body template (see "Writing the product"). Stories come afterwards, with the person: don't import them from the repo's docs on your own.

## Commands

- Set up: `mt setup` · `mt skill install` · `mt projects` · `mt project create "Name" --key PG` · `mt init PG --claude`
- Read: `mt context` · `mt next` · `mt roadmap [--closed]` · `mt show PG-49` · `mt list [--state …] [--milestone …] [--label …] [--mine]` · `mt decisions` · `mt questions`
- Work: `mt start` · `mt done --commit` · `mt release --reason` · `mt comment` · `mt ask --option … --recommend` · `mt answer` · `mt decide --why`
- Define: `mt create` · `mt edit --file` · `mt move` · `mt reorder --reason` · `mt brief` · `mt milestone …`

`mt help` and `mt <command> --help` have the details and an example of each.
