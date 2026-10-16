# Maker Tracker

Where you define and organize products together with AI agents. Agents are first-class users: everything you can do in the UI they can do through a CLI and MCP, and the UI is for you to define the product and see what they are up to.

Self-hosted, lightweight, Rails + SQLite. MIT licensed.

> **Status:** this is still v1, a Pivotal Tracker–style tool (projects, sprints, items, comments). v2, agent-first, is being designed in [`docs/`](docs/PRODUCT.md).

## Self-host it

On a machine with Docker:

```bash
git clone https://github.com/franwer-ranger/maker_tracker.git
cd maker_tracker
docker compose up -d --build
```

It listens on `127.0.0.1:3002` only, keeps everything in `./data/` and backs itself up daily. To reach it from your devices over HTTPS, without opening ports, publish it with `tailscale serve --bg 3002`.

Full guide (Tailscale, updates, backups, restore): [`docs/SELF_HOSTING.md`](docs/SELF_HOSTING.md).

## Develop

Ruby 3.4.8 (rbenv) and nothing else: SQLite, no Docker needed.

```bash
bin/setup   # gems, database with seeds, and starts the server
bin/dev     # http://localhost:3002 (user fran@gmail.com / 12345678)
bin/ci      # lint, security audits and seeds; must pass before every commit
```

Product vision, roadmap and architecture live in [`docs/`](docs/). Agents working on this repo start at [`AGENTS.md`](AGENTS.md).

## License

[MIT](LICENSE)
