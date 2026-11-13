# renovate-config

Shared **Renovate presets** for the maintainer's repos. Public (MIT). Consumers extend them
**unpinned, from `main`**: `github>igonzalezespi-apps/renovate-config` (`default.json`) or
`…:config-repo` (`config-repo.json`). Each preset is a public API and **`main` is production**:
every merge is live at once for every consumer's dependency automation.

## Public repo

Nothing here (files, commits, PRs, issues, comments) names a private project; refer to the
maintainer's other repos neutrally. After cloning, `git config core.hooksPath .githooks`: the hooks
run gitleaks and the private-reference checker, and fail closed in the owner's clones if the
checker is missing. Code, comments and this file stay English.

## Validate

`npm ci`, then `npx --no-install renovate-config-validator --strict <file>` for each preset (what
CI does). Details and traps in `.claude/rules/presets.md` and `README.md`.

## Flow

- New worktree from `origin/main` (this repo has no `develop`; its own `renovate.json` pins
  `main`); PR to `main`. When its checks are green you merge it yourself:
  `gh pr merge <n> --squash --match-head-commit <sha>` (squash, so the PR title is the commit and
  must be a Conventional Commit). If the change is delicate, first a second read with
  `/code-review` in a clean context.
- Pushing to `main` directly and cutting a version (`v*` tags) are the maintainer's.
- What to ask the maintainer and what you decide comes from the machine's instructions; it is
  not repeated here.
