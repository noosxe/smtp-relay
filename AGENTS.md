# AGENTS.md

Ground rules for AI coding agents working in this repository.
Humans should follow the same workflow; agents must follow it exactly.

The repo: a portable SMTP relay compose stack (boky/postfix) configured via `.env`,
preconfigured for Resend. No secrets ever belong in version control.

## Git workflow (mandatory)

- `main` is protected: **no direct commits and no direct pushes to `main` — ever.**
  There are no exceptions, including "small" or "obvious" changes.
- All changes go through a **pull request targeting `main`**, created from a short-lived
  feature branch.
- The only enabled merge method is **rebase merge**. Keep branch history linear and
  rebased on the latest `main`.
- **Agents never review, approve, or merge PRs.** Review and merge to `main` are
  manual, owner-only actions. An agent's work ends at "PR opened, ready for review".

### Branches

- Branch off the latest `main`:
  `git switch main && git pull --ff-only && git switch -c <type>/<short-slug>`
- Name branches by conventional-commit type: `feat/...`, `fix/...`, `docs/...`,
  `chore/...`, `refactor/...`.
- One branch = one focused change. Keep PRs small and single-purpose; split unrelated
  work into separate PRs.

### Commits

- **Conventional Commits, strictly**: `type(scope): imperative subject` with types
  `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `style`, `perf`, `build`,
  `revert`.
- Subject ≤ 72 chars, lowercase, no trailing period. Use the body for the *why*.
- Because merges are rebase merges, **every commit in a PR lands on `main` as-is**:
  each commit must follow conventional commits and leave the repo in a valid state.
- Never commit secrets, credentials, or machine-specific identifiers (usernames, home
  paths, real hostnames/IPs). `.env` and `.pi/` are gitignored — keep them that way.
  New config belongs in `.env.example` with empty or placeholder values.

### Pull requests

- PR title follows conventional commits (it is what reviewers see first).
- Focused scope only: one purpose per PR. Unrelated changes get their own PR.
- Before opening:
  1. Rebase onto latest `main`: `git fetch origin && git rebase origin/main`.
     No merge commits inside the branch.
  2. Run local checks: `make validate` (compose config resolves, required env vars
     present); `make -n` for Makefile changes.
  3. Scan the diff for accidental secrets or identifying strings.
- Open the PR with `gh pr create --base main ...` when the `gh` CLI is available;
  otherwise push the branch and hand the owner the compare URL.
- **Then stop.** Do not merge, do not self-approve, do not force-push after review has
  started (post a comment instead).

## What agents must never do

- Commit or push directly to `main`
- Review, approve, or merge pull requests (owner-only)
- Force-push branches shared with others or any branch under review
- Bypass, weaken, or work around branch protection, hooks, or CI
- Commit `.env`, API keys (e.g. `re_...`), or identifying machine data

## Owner-only actions (agents: do not attempt)

- Reviewing and approving PRs
- Merging PRs (rebase merge)
- Changing branch protection or repository settings

## Quick reference

```bash
git switch main && git pull --ff-only
git switch -c feat/my-change
# ...edit, verify...
make validate
git add <files>
git commit -m "feat: my change"
git fetch origin && git rebase origin/main
git push -u origin feat/my-change
gh pr create --base main --title "feat: my change" --body "..."
# stop here — the owner reviews and merges
```

## Meta

Changes to this file follow the same workflow: branch, PR, owner review.
