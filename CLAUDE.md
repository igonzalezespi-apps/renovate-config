# renovate-config

Shared **Renovate presets** for the maintainer's repos. Public (MIT). Consumers extend them
**unpinned, from `main`**: `github>igonzalezespi-apps/renovate-config` (`default.json`) or
`…:config-repo` (`config-repo.json`). So each preset is a public API, and **`main` is
production**: every merge is live at once for every consumer's dependency automation.

## Rules

- **Public repo: never name a private project** — not in the presets, docs, comments, commit
  messages, PR bodies, hooks or CI. Refer to the maintainer's other repos neutrally. The
  `.githooks/` hooks enforce it against a private denylist (a no-op on a fork).
- **Language:** reply to the maintainer in Spanish; code, comments and this file stay English.
- **Branch flow: trunk → main, squash by convention.** This repo has no integration branch: PRs,
  dependency PRs included (its own `renovate.json` pins `main`), target `main` and land by
  **squash**, so the PR title becomes the commit and MUST be a valid Conventional Commit; every PR
  also needs one `semver:*` label. All three merge methods are enabled and GitHub preselects the
  last one used: choose squash explicitly (`gh pr merge <n> --squash`).
- The guard policy here has `agent_may_merge: false`: an in-session agent cannot merge in this repo.
- **Nothing is enforced server-side** (no branch protection, rulesets or required checks: a
  standing decision). CI reports, it does not block; what stops a mistake is the vendored guard
  in-session and the `.githooks/` hooks per clone. Run `bash bootstrap.sh` after cloning.
- The company-wide rules come from the `studio-policy` plugin; this file keeps only what is
  specific to this repo. Path rules load on demand: `.claude/rules/presets.md` (the presets and
  their validation) and `.claude/rules/guard.md` (`scripts/hooks/`, `.githooks/`, `bootstrap.sh`).

## Reserved to the maintainer (escalate, do not decide)

A breaking change to a preset's public contract · opening a private repo to the public · spend or
scope decisions.
