# Self-hosting Maker Tracker

Maker Tracker runs on your own machine with Docker: one container for the app, one for backups, and all its data in a single folder. It is meant to live on a private network. This guide uses [Tailscale](https://tailscale.com) so you can reach it from your devices, over HTTPS, without opening any port.

> [!WARNING]
> **Maker Tracker has no login.** Anyone who can reach it can read and change everything in it. **Never expose it to the internet**: run it only on your LAN or on a Tailscale tailnet. No port forwarding on your router, no public reverse proxy, no Tailscale Funnel.

## Requirements

- A Linux machine that stays on (a home server, a mini PC, a VPS on your tailnet). macOS with Docker Desktop works for trying it out.
- Docker Engine with Compose 2.24 or newer: `docker compose version`.
- Git.
- About 2 GB of disk for the image, plus your data (small: a few MB).
- Optional but recommended: Tailscale on the server and on the devices you will use it from.

## 1. Prepare Docker

Skip this if `docker ps` already works without `sudo`.

```bash
sudo systemctl enable --now docker   # start Docker now and on every boot
sudo usermod -aG docker "$USER"      # use docker without sudo
```

Log out and back in (or open a new SSH session) so the group applies. Note that being in the `docker` group is equivalent to having root on that machine.

## 2. Install

```bash
git clone https://github.com/franwer-ranger/maker_tracker.git
cd maker_tracker
docker compose up -d --build
```

The first build takes a minute or two (86 seconds on a 9th-gen Intel i7). When it finishes:

```bash
docker compose ps   # app should say "healthy", backup "running"
```

What you get:

- The app on `http://127.0.0.1:3002`, **only reachable from that machine**. Docker does not respect firewalls like `ufw` for published ports, which is why it binds to `127.0.0.1` and nothing else.
- All the data in `./data/`: `data/storage/` (the SQLite databases and the generated secret) and `data/backups/`.
- No configuration needed. To change the port, the data folder or the backup schedule, copy `.env.example` to `.env` and edit it (see [Settings](#settings)).

## 3. Reach it from your devices with Tailscale

`tailscale serve` publishes the app to your tailnet only, with a valid HTTPS certificate.

1. In the [Tailscale admin console](https://login.tailscale.com/admin/dns), enable **MagicDNS** and **HTTPS Certificates**.
2. On the server, let your user manage `serve` without `sudo` (once), then publish the app:

   ```bash
   sudo tailscale set --operator="$USER"
   tailscale serve --bg 3002
   tailscale serve status   # shows the URL
   ```

3. Open `https://<machine-name>.<your-tailnet>.ts.net` from any device on your tailnet.

The setting persists across reboots. To stop publishing it: `tailscale serve --https=443 off`.

Not using Tailscale? Put a reverse proxy with HTTPS (Caddy, nginx) in front of `127.0.0.1:3002` that **only listens on your LAN**, never one reachable from the internet. The app assumes it is served over HTTPS.

### Check that it is not reachable from outside

From another device on the same LAN, **without** Tailscale, this must fail to connect:

```bash
curl -m 5 http://<server-lan-ip>:3002
```

And from a phone on mobile data with Tailscale turned off, the `ts.net` URL must not load. On the server, `tailscale serve status` must say `(tailnet only)`: if it mentions Funnel, the app is on the internet.

## Updating

```bash
cd maker_tracker
git pull && docker compose up -d --build
```

Database migrations run on start. Your data in `./data/` is untouched.

## Backups

The `backup` container takes a consistent copy of the database on start and then every 24 hours, checks it with SQLite's `integrity_check` and keeps the newest 14. Each backup is a folder `data/backups/<UTC date-time>/` with `production.sqlite3` and the app secret.

```bash
docker compose exec backup bin/backup    # take one now
docker compose exec backup bin/restore   # list them
docker compose logs backup               # see what it did
```

These backups live on the same disk as the app. To survive a dead disk, copy `data/backups/` to another machine or drive regularly (for example with `rsync` from cron).

## Restoring

```bash
docker compose stop app
docker compose run --rm --no-deps backup bin/restore 20261016-093753   # a name from the list
docker compose start app
```

`--no-deps` keeps the app stopped while the database is replaced. The database you had is kept next to it as `production.sqlite3.before-restore-<date>` in `data/storage/`, so a restore can be undone.

## Settings

All optional, in `.env` (start from `.env.example`):

| Variable | Default | What it does |
|---|---|---|
| `MAKER_TRACKER_PORT` | `3002` | Port on the machine, always bound to `127.0.0.1` |
| `MAKER_TRACKER_DATA` | `./data` | Folder for the databases, the secret and the backups |
| `BACKUP_INTERVAL_HOURS` | `24` | Hours between backups |
| `BACKUP_KEEP` | `14` | Backups kept |
| `SECRET_KEY_BASE` | generated | The app secret. If empty, one is generated on first boot into `data/storage/secret_key_base` |

After changing `.env`: `docker compose up -d`.

## Day to day

```bash
docker compose ps                                  # status
docker compose logs -f app                         # logs
docker compose exec -u rails app bin/rails console # Rails console (as the app user)
docker compose down                                # stop everything (data stays)
```

To uninstall, run `docker compose down --rmi local` and delete the folder. Docker creates `data/` itself as root, so removing it needs `sudo rm -rf data`. **`data/` is your data**: back it up first.

## Agent tokens

Coming soon: agents will authenticate with one token each. This section will explain how to create them.
