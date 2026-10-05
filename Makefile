# Launch control for the smtp-relay compose stack (docker compose v2).
# `make` alone = launch.

.DEFAULT_GOAL := launch

COMPOSE_FILE ?= docker-compose.yml
COMPOSE      = docker compose -f $(COMPOSE_FILE)

# Optional: pick up SMTP_PORT / MYORIGIN / CONTAINER_NAME from .env for the
# convenience targets below. Values must not contain spaces or '$'
# (true for provider API keys like Resend's "re_..." keys).
-include .env

SMTP_PORT      ?= 25
CONTAINER_NAME ?= smtp-relay
FROM           ?= relay-test@$(or $(MYORIGIN),example.com)

.PHONY: launch
launch:
	$(COMPOSE) up -d

.PHONY: stop
stop:
	$(COMPOSE) down

.PHONY: restart
restart: stop launch
	@echo "done"

.PHONY: pull
pull:
	$(COMPOSE) pull

.PHONY: logs
logs:
	$(COMPOSE) logs -f

.PHONY: status
status:
	$(COMPOSE) ps

# --- smtp-relay specific ---------------------------------------------------

.PHONY: setup
setup:
	@if [ -f .env ]; then echo ".env already exists - edit it, then run 'make launch'"; else cp .env.example .env; echo "Created .env - set RELAYHOST_PASSWORD (and MYORIGIN), then run 'make launch'"; fi

.PHONY: validate
validate:
	@$(COMPOSE) config --quiet && echo "compose config OK (env resolves, RELAYHOST_PASSWORD present)"

.PHONY: health
health:
	@docker inspect -f '{{.State.Health.Status}}' $(CONTAINER_NAME) 2>/dev/null || echo "container not found / not running"

.PHONY: send-test
send-test:
ifndef TO
	$(error usage: make send-test TO=you@recipient.example)
endif
	@( sleep 2; printf 'EHLO maketest\r\n'; sleep 1; printf 'MAIL FROM:<$(FROM)>\r\n'; sleep 1; printf 'RCPT TO:<$(TO)>\r\n'; sleep 1; printf 'DATA\r\n'; sleep 1; printf 'From: $(FROM)\r\nTo: $(TO)\r\nSubject: smtp-relay make test\r\n\r\nSent via smtp-relay (make send-test).\r\n.\r\n'; sleep 1; printf 'QUIT\r\n' ) | nc -w 15 127.0.0.1 $(SMTP_PORT)
	@echo "Handed to relay on 127.0.0.1:$(SMTP_PORT) - check the inbox / 'make logs'"
