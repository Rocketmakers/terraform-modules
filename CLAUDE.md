# Claude Code

The agent instructions for this repository live in [AGENTS.md](AGENTS.md) so that every tool reads
the same file. It is imported here in full.

@AGENTS.md

Two Claude-specific notes:

- Commits and pushes are only made when asked. Approving a plan produced by the
  `pr-review-response` skill counts as asking for the commits that plan names.
- A commit that only touches `AGENTS.md`, `CLAUDE.md` or anything under `.claude/` is type `docs`
  with no scope. It never reaches the changelog.
