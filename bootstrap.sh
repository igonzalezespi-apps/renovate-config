#!/usr/bin/env bash
# ============================================================================
# bootstrap.sh — one-time / re-runnable setup for a fresh clone or worktree.
# ============================================================================
# 1. Installs the Claude Code plugins this repo declares in .claude/settings.json
#    (core-dev + studio-policy) from the maintainer's marketplace, scoped to the
#    project. Idempotent — safe to re-run.
# 2. Refreshes the vendored guard from core-dev (guard-sync) and verifies it
#    (guard-verify) when those are available from the installed plugin. The guard
#    ENFORCES from its committed copy in scripts/hooks/ regardless; this only
#    keeps that copy in sync with the canonical core.
# 3. Arms the private-reference git hooks (core.hooksPath -> .githooks).
# ============================================================================
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# --- 1. Plugins -------------------------------------------------------------
if command -v claude >/dev/null 2>&1; then
  for p in core-dev studio-policy; do
    claude plugin install "${p}@ivan" --scope project \
      || echo "bootstrap: 'claude plugin install ${p}@ivan' failed (continuing)" >&2
  done
else
  echo "bootstrap: 'claude' CLI not found — skipping plugin install (the vendored guard in scripts/hooks/ still enforces)." >&2
fi

# --- 2. Private-reference git hooks -----------------------------------------
# Until 2026-07-21 this step existed only as a comment telling the reader to run it
# by hand. Nobody does. The result was a guard that was committed, reviewed and
# audited as present, yet inert in every fresh clone — the hooks simply never ran.
# The three sibling config repos already armed it here; this one did not.
if [ -d "$ROOT/.githooks" ]; then
  git config core.hooksPath .githooks
  echo "bootstrap: core.hooksPath -> .githooks (private-reference guard active where the denylist exists)"
fi

# --- 3. Vendored guard: refresh + verify ------------------------------------
find_tool() {
  # $1 = script basename under core-dev/scripts; echoes a path or "".
  #
  # The plugin cache keys every plugin by VERSION —
  # <cache>/<marketplace>/core-dev/<version>/scripts/<name> — so the version-less
  # path this used to probe matched nothing: both tools were reported missing and
  # the whole step no-oped even with the plugin installed. Locate the script
  # itself instead: maintainer's marketplace first, newest version wins, so the
  # pick stays deterministic when several versions or marketplaces coexist.
  local root hit
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/$1" ]; then
    printf '%s' "${CLAUDE_PLUGIN_ROOT}/scripts/$1"
    return 0
  fi
  for root in \
    "$HOME/.claude/plugins/cache/ivan/core-dev" \
    "$HOME/.claude/plugins/cache" \
    "$HOME/.claude/plugins/marketplaces"; do
    [ -d "$root" ] || continue
    hit="$(find "$root" -type f -name "$1" -path '*core-dev*' 2>/dev/null | sort -V | tail -1)"
    [ -n "$hit" ] && { printf '%s' "$hit"; return 0; }
  done
  printf ''
}

SYNC="$(find_tool guard-sync.sh)"
if [ -n "$SYNC" ]; then
  bash "$SYNC" --repo "$ROOT"
else
  echo "bootstrap: core-dev/guard-sync not found (plugin not installed yet) — the vendored guard in scripts/hooks/ still enforces; run /guard-sync after installing core-dev to refresh it." >&2
fi

VERIFY="$(find_tool guard-verify.sh)"
if [ -n "$VERIFY" ]; then
  bash "$VERIFY" --repo "$ROOT"
fi
