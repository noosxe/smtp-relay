# smtp-relay

Portable SMTP relay (authenticated upstream, open relay for your own networks only).
Uses [`boky/postfix`](https://github.com/bokysan/docker-postfix) to forward mail through an
SMTP provider (defaults preconfigured for [Resend](https://resend.com)) while exposing a plain
SMTP endpoint on port **25** for the whole machine — host services, scripts, cron jobs and LAN
clients — no per-app credentials needed.

## Quick start

```bash
cp .env.example .env
# edit .env — at minimum set RELAYHOST_PASSWORD (your provider API key)
docker compose up -d

# or with the bundled Makefile:
make setup      # copies .env.example to .env (no-op if it already exists)
# edit .env, then:
make
```

The only hard requirement is `RELAYHOST_PASSWORD`; every other value has a sensible default
(baked into `docker-compose.yml`, overridable from `.env`).

## Sending mail

**From the host machine** (port published on `BIND_IP`, default `0.0.0.0:25`):

```bash
# swaks (recommended): brew/apt install swaks
swaks --server 127.0.0.1:25 --from you@example.com --to dest@example.org

# or raw SMTP
printf 'EHLO test\r\nMAIL FROM:<you@example.com>\r\nRCPT TO:<dest@example.org>\r\nDATA\r\nSubject: hi\r\n\r\nhello\r\n.\r\nQUIT\r\n' | nc 127.0.0.1 25
```

**From other containers**: attach them to the same network and use `smtp-relay:25`
as the SMTP host (no port mapping or credentials needed):

```bash
docker network connect smtp-relay-net <container>     # or set it in the app's compose file
```

**From LAN machines**: use the machine's LAN IP, port 25. Works only if the client's
IP is inside `MYNETWORKS`.

## How access control works

Publishing the port makes the relay *reachable*, but only networks listed in `MYNETWORKS`
are allowed to relay (`mynetworks` in Postfix). Everything else gets
`554 Relay access denied`. The default (`127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16`)
covers localhost, docker bridges (host-originated traffic appears as the bridge gateway IP)
and typical LANs. Tighten or extend it in `.env` to match your deployment.

## Files

| File              | Purpose                                                    |
| ----------------- | ---------------------------------------------------------- |
| `docker-compose.yml` | Stack definition; reads `.env`, carries the defaults     |
| `.env.example`    | Template — copy to `.env`, fill in secrets                 |
| `Makefile`        | Launch control (see targets below)                         |
| `.gitignore`      | Keeps `.env` (API key!) out of version control             |

## Make targets

`make` alone = `make launch`. Convenience targets read `SMTP_PORT`, `MYORIGIN` and
`CONTAINER_NAME` from `.env` when present.

| Command | What it does |
| ------- | ------------ |
| `make` / `make launch`   | `docker compose up -d` |
| `make stop` / `make restart` | `compose down` / down + up |
| `make pull`              | pull the latest image |
| `make logs`              | follow relay logs |
| `make status`            | `docker compose ps` |
| `make setup`             | copy `.env.example` → `.env` (skipped if `.env` exists) |
| `make validate`          | resolve the compose config — fails loudly if `RELAYHOST_PASSWORD` is missing |
| `make health`            | print the container healthcheck status |
| `make send-test TO=you@example.org` | hand a raw test message to the relay on `127.0.0.1:$SMTP_PORT` |

## Operational notes

- **Port 25 conflict**: if the host already runs an MTA (postfix/exim/sendmail), either stop it
  or set `SMTP_PORT` in `.env` to another port.
- **Crash loop with "You need to specify ALLOWED_SENDER_DOMAINS"**: the image requires an
  explicit sender-domain policy before it will run. It defaults to `MYORIGIN`; set
  `ALLOWED_SENDER_DOMAINS` in `.env` (space-separated list) to accept more sender domains.
- **Upstream TLS**: `SMTP_TLS_SECURITY_LEVEL=encrypt` refuses to deliver unless the upstream
  connection uses STARTTLS.
- **Bare addresses**: envelopes like `MAIL FROM:<root>` are completed to `root@MYORIGIN`
  (set `MYORIGIN` to your real sending domain so recipients' spam filters stay happy).
- **Logs**: `docker compose logs -f smtp-relay` (rotated, 3×10 MB).
- **Health**: `docker compose ps` — the container reports `healthy` once it answers on port 25.
- **Different provider**: change `RELAYHOST` / `RELAYHOST_USERNAME` in `.env`, e.g.
  Mailgun → `smtp.mailgun.org:587`, SendGrid → `smtp.sendgrid.net:587`.
