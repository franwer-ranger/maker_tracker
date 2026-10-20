---
name: daily
description: The daily of a project in Maker Tracker. Use it when asked for "/daily", "la daily", "cómo está el proyecto", "ponme al día" or "¿qué ha pasado?", and at the end of bringing a project to Maker Tracker. It reads mt daily, cross-checks it with git log, tells the person where the project is and proposes up to 3 evolutionaries as ideas.
---

# The project's daily (`/daily`)

The person wants to resume without opening anything: how the project is, what happened, what is waiting and what would make sense to do. Maker Tracker gives the data (`mt daily`); the judgement and the proposals are yours. You need `mt` and a `.mt` at the root of the repo (see the `maker-tracker` skill). `mt` speaks English; **write the daily to the person in their language** (Spanish for Fran).

## Steps

1. **`mt daily`**. It shows, since *your* last daily in this project (another agent's daily doesn't move yours), what happened, what is in progress, what is blocked, what waits for the person and what is next. Running it records your daily: the next one starts here. If you need to look at an older period, `mt daily --since 2026-10-15`. In a project with no history it still works (it shows the last 7 days, or nothing yet).
2. **Cross it with the code**: `git log --since="<the date mt daily printed>" --oneline` (and `git status` if there is something uncommitted). Look for what mt can't know: commits without a story, work done outside the tracker, stories `mt` says are in progress with no commits, TODOs or dead code that point to a gap. Don't go through the whole repo: the point is a daily, not an audit.
3. **Tell it**, short and in this order: where the project is (one or two sentences) · what happened since the last time (what matters, not every event) · what is in progress and blocked · **what waits for the person**, first, with the question or decision it needs · what comes next (`mt next`). Say it with references (`PG-49`, `D-14`) so they can follow them.
4. **Propose evolutionaries** only if you have something concrete, with a reason from the code or from what happened: an idea per evolutionary with `mt daily idea "Title" --why "why, and where you saw it"`. **At most 3 per daily**; `mt` refuses the fourth. They go to the inbox as ideas: they never enter the roadmap and you don't move them, order them or mark them as ready. If nothing is worth proposing, propose nothing.
5. **Say which ideas you created** (reference and title) at the end of the daily, so the person can look at them. Don't create ideas for things that are already stories (check `mt list` and the inbox first).

## Rules

- The daily doesn't change the product: it reads, it summarizes and it leaves ideas. Don't start, move or edit stories because of what you read; if something is urgent, say it and let the person decide.
- Don't invent. If `mt daily` says nothing happened, say so.
- Don't paste `mt daily`'s output: it is your source, not the daily.
- It isn't run on its own or on a schedule; it is run when the person asks for it (or at the end of bringing a project in).
