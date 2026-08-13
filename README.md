# renovate-config

Studio-wide shared [Renovate](https://docs.renovatebot.com/) preset for the
[igonzalezespi](https://github.com/igonzalezespi) studio. **Single source of truth** for the
dependency-update policy across all the studio's repos.

It lives in its **own** repo — deliberately not inside the private company repo — so the
Renovate app never gets read access to the company runbooks/infra just to read one config file
(least-privilege). The repo is **public** because the policy itself is not secret (no tokens, IPs,
or anything sensitive), and a public preset resolves everywhere with **zero** app-access setup.

> **`main` is production.** Consumers extend this preset **unpinned** from the default branch, so
> every merge to `main` is immediately live for all of them.

## The single-writer model

**GitHub detects. Renovate writes. Nothing else opens a dependency PR.**

| Piece | Role | State | Where it is set |
|---|---|---|---|
| Dependency graph + Dependabot **alerts** | Detect and notify. Never open PRs | **ON** | `PUT /repos/{owner}/{repo}/vulnerability-alerts` |
| Dependabot **security updates** (`automated-security-fixes`) | Would open PRs | **OFF** | repo setting — leave it off |
| Dependabot **version updates** (`.github/dependabot.yml`) | Would open PRs | **ABSENT** | no repo has this file |
| Renovate (`renovate.json` → this preset) | The only writer | **ON** | this repo |

### Why the Dependabot updater stays off

This is not a verdict on Dependabot's quality — it has supported pnpm catalogs since February
2025 and it is a fine tool. The point is that **exactly one bot may write to the manifests.**
Two writers on the same files produce duplicate PRs for the same CVE, lockfile conflicts between
their branches, competing automerges, and double the Actions minutes.

Renovate is the writer that stays because it adds ecosystem grouping, a configurable cooldown,
and the Dependency Dashboard.

### Why the alerts must stay ON

Renovate's `vulnerabilityAlerts` has nothing to act on without them — **it consumes GitHub's
Dependabot alerts and opens the PRs itself.** Turning the alerts off does not make the setup
"more Renovate"; it silently kills the security path while the config still claims it is enabled.

`osvVulnerabilityAlerts` is a second, independent feed, and it covers **direct dependencies
only** — it is a complement to the GitHub alerts, never a replacement. Both legs are needed.

> ⚠️ **The toggle that breaks this model.** When you enable the alerts in *Settings →
> Advanced Security*, GitHub offers **"Dependabot security updates"** one click away. That switch
> turns Dependabot into a second writer. Leave it off. If you find it on, turn it off rather than
> disabling Renovate.

Verify any repo in four commands:

```bash
gh api repos/{owner}/{repo}/vulnerability-alerts -i | head -1   # want: 204
gh api repos/{owner}/{repo}/automated-security-fixes            # want: {"enabled": false}
gh api repos/{owner}/{repo}/contents/.github/dependabot.yml     # want: 404
gh api repos/{owner}/{repo}/contents/renovate.json              # want: 200
```

## How repos consume it

Each consumer repo's `renovate.json`:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>igonzalezespi-apps/renovate-config"]
}
```

Repo-specific rules (a Flutter project's version-holds, a public app's Expo-SDK group, a repo
that disallows squash merges) are **added in that repo's own `renovate.json`** alongside the
`extends`, never here. The repo's own file is merged on top of this one, so it always wins.

## Policy (`default.json`)

| Knob | Value | Why |
|---|---|---|
| Base | `config:recommended` + `:dependencyDashboard` + `:semanticCommits` + `group:monorepos` | `config:recommended` already pulls in the dashboard and monorepo grouping; they are listed explicitly so the policy is readable without expanding presets |
| Timezone | `Europe/Madrid` | |
| Schedule | cron `* * * * 1` — all of Monday | A narrow window risks the bot run never landing inside it, and a PR that is never created cannot automerge |
| Cooldown | `minimumReleaseAge: 7 days` + `internalChecksFilter: strict` | `strict` withholds the PR until the cooldown is met instead of opening it pending |
| Security updates | **not** delayed | `vulnerabilityAlerts` sets `minimumReleaseAge: null` explicitly (it is also the default, but stated so nobody tidies it away), plus `prCreation: immediate` and a rate-limit bypass. Delaying a fix for a known CVE would invert the cooldown into a brake on the one update that must land fastest — do not relax the global cooldown believing security needs it |
| Dependency PRs target | **`develop`** | `main` is the reviewed/released line. Trunk→main repos override `baseBranchPatterns` in their own file |
| Range strategy | `bump` | With `replace`, an in-range update never opens a PR, so a `^1.2.0` manifest silently stops moving and only `lockFileMaintenance` keeps it fresh |
| Commits | Conventional `chore(deps): …` | |
| Automerge | `patch` · `pin` · `digest` · `lockFileMaintenance`, `squash` strategy | Bot PRs land squashed per the studio merge policy |
| Dashboard approval | `major`, and `minor` of `0.x` packages | Pre-1.0, a minor is a breaking change |
| Review required | `minor` (1.0+) | |
| Transitive deps | `lockFileMaintenance`, weekly, `prPriority: 10` | Ordinary PRs bump **direct** deps only. Without the relock, the tree accumulates advisories against versions the lockfile has frozen |
| GitHub Actions | grouped, pinned to SHA | |
| npm | non-major updates grouped | |
| Standing holds | `pnpm` majors, `typescript` majors | Coordinated studio-wide rollouts, never an automatic PR |

One knob is easy to get wrong and worth naming: **`prPriority` belongs in `packageRules`, never
inside `lockFileMaintenance`.** Renovate rejects it there. The validator catches it — nothing else
will, and a config Renovate rejects is ignored **silently**.

## Validating a change

CI does validate this repo: the `Validate Renovate preset` job runs
`renovate-config-validator --strict` over **both** `default.json` and `renovate.json`, against a
pinned `renovate@43.209.4`. That gate exists **only here** — the nine consumer repos do *not*
validate their own `renovate.json` in CI, so a broken one there fails silently.

Two things worth knowing before trusting a green run:

- **Passing a path validates in *global-config* mode, which is more permissive** — with or without
  `--strict`. To check `default.json` the way a consumer will actually see it, validate it in
  **repo** mode: copy it to a scratch directory as `renovate.json` and run the validator with **no
  argument**.
- **A missing file exits 0**, with only `WARN: No files to perform configuration validation
  against`. Absence is not failure here, so a check wired over a renamed or deleted file goes
  green. An *invalid* file does exit 1.

```bash
# what CI does (global mode)
npx --yes --package renovate -- renovate-config-validator --strict default.json

# what a consumer actually gets (repo mode)
mkdir -p /tmp/rv && cp default.json /tmp/rv/renovate.json
cd /tmp/rv && npx --yes --package renovate -- renovate-config-validator
```

Both must print `Config validated successfully`.

## Prerequisites

- The Renovate (Mend) GitHub App must be installed on each **consuming** repo. It does **not**
  need access to this preset repo — it's public.
- Dependabot **alerts** must be on in each consuming repo (see the single-writer model above).
  This preset cannot enable them; it is a per-repo API/settings switch.

## License

[MIT](./LICENSE) © igonzalezespi
