---
paths:
  - 'default.json'
  - 'config-repo.json'
  - 'renovate.json'
  - 'package.json'
  - 'package-lock.json'
  - 'README.md'
---

# The presets and their validation

- `default.json` is the company preset and sets the consumers' base branch, `develop`.
  `config-repo.json` extends it for the config and tooling repos and overrides only the automerge
  posture: it inherits `develop` and must not re-pin a base branch.
- `renovate.json` governs this repo only: it extends `default.json` (not `config-repo`), pins
  `main`, keeps every bump for human review, and none of its managers touches the presets.
- Prefer additive, opt-in changes: a rule that silently alters every consumer's automation is a
  breaking change and belongs to the maintainer.
- Validate before pushing, as CI does, with the `renovate` pinned in `package.json`
  (`npm ci`, then `npx --no-install renovate-config-validator --strict <file>` for each preset).
  Path mode is permissive: to see what a consumer gets, copy the preset as `renovate.json` into a
  scratch directory and run the validator there with no argument (see `README.md`).
