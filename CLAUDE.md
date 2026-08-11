# renovate-config

Shared **Renovate presets** for the maintainer's repos. Public (MIT). Consumed via
`"extends": ["github>igonzalezespi-apps/renovate-config"]` (or `:default`), so `default.json` is a
public API: a change to it affects every consumer's dependency automation.

> Self-contained contract — the studio-wide company layer is enumerated below, and is also
> injected at runtime by the `studio-policy` plugin when it is installed (see
> `.claude/settings.json`). Nothing here inherits from a parent file, so it holds on a fork too.

## Rules

- **Public repo — never name a private project.** Not in the JSON presets, docs, comments,
  commit messages, PR bodies, hooks, or CI. Refer to the maintainer's other repos neutrally.
  A local `pre-commit` guard (`.githooks/pre-commit`) enforces this against a private denylist;
  enable it per clone with `git config core.hooksPath .githooks` (it is a no-op where the
  denylist is absent, e.g. a fork).
- **Agent command guard.** A vendored `scripts/hooks/bash-guard.sh` is cabled as a Claude Code
  PreToolUse Bash hook (`.claude/settings.json`): a best-effort tripwire that denies pushing to
  `main`, force-pushing a shared branch, `--no-verify`, agent merges, `.env` reads and non-local
  network egress. It is **not** a security boundary and it fail-opens. It enforces from its
  committed copy; refresh it from the canonical core via `bootstrap.sh` / `guard-sync` and
  verify with `guard-verify` (parity + wiring + liveness).
- **Nothing is enforced server-side.** The enforcement here is entirely local: the guard above
  (in-session), the `.githooks/` hooks (`pre-commit`, `commit-msg`) once cabled per clone, and
  CI, which **reports without blocking** — with no required status checks a red run does not
  prevent a merge. Branch protection and rulesets are **deliberately not enabled** (verified:
  `gh api repos/<owner>/<repo>/branches/main/protection` → `404`, `.../rulesets` → `[]`) — an
  explicit decision, not an oversight. Enabling them is what would make a push to `main` or a
  merge over a red check technically impossible instead of merely forbidden.
- **Language / Idioma** — Reply to the user (Ivan) in **Spanish**; he reads Spanish and this
  holds in every repo and session. Author the OpenSpec docs the user reads — `proposal.md`,
  `design.md`, `tasks.md` — in **Spanish** too. Everything else stays **English**: source code,
  comments, identifiers, this contract file's own text, skills/SKILL.md, agent prompts, and
  OpenSpec **spec deltas** (`specs/**/spec.md`, which keep their `SHALL` / `WHEN`/`THEN` RFC2119
  keyword format).
- **Conventional Commits** — `type(scope): description` (`feat/fix/chore/docs/ci`).
- **Branch flow: trunk → main, squash-only.** PRs target `main` and land by **squash** (enforced
  by repo settings): every PR becomes ONE conventional commit whose message is the **PR title**,
  which drives the computed changelog/version — so PR titles MUST be valid Conventional Commits.
  The only sanctioned force-push is `--force-with-lease` on your own PR branch.
- **`main` is production.** Consumers extend these presets unpinned from the default branch, so
  every merge to `main` is immediately live for all consumers — merge accordingly.
- **No secrets committed** — placeholders only.
- Treat `default.json` as a stable contract: validate JSON before committing, and prefer
  additive/opt-in changes over ones that silently alter every consumer's behavior.
- **Reserved to the maintainer** (escalate, do not decide): a breaking change to `default.json`'s
  public contract, anything that edits this contract, opening a private repo to the public, and
  spend/scope decisions.

## Setup

- `bash bootstrap.sh` — installs the declared Claude Code plugins (`core-dev`, `studio-policy`)
  and refreshes/verifies the vendored guard. Per-machine plugin install is separate; the vendored
  guard in `scripts/hooks/` enforces regardless.
- `git config core.hooksPath .githooks` — enable the private-reference pre-commit guard.
