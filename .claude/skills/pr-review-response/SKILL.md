---
name: pr-review-response
description: >-
  Read the open review feedback on a pull request, take a position on every thread, then — once that
  plan is approved — make the code changes, commit them, reply on GitHub and resolve the threads
  actually dealt with. Use when asked to respond to review comments, address PR feedback, deal with
  the Copilot review, reply to the reviewer, or "what did the reviewer say".
argument-hint: '[PR number]'
---

Nothing is committed or pushed in this repository unless the user asks. Approving the plan this skill
produces **is** that ask — for the commits the plan names, and nothing else. It does not authorise
creating a branch, force-pushing, or committing work the plan did not name.

## 1. Find the pull request

```bash
gh pr view --json number,url,state,isDraft,baseRefName   # or the argument, if given
```

Not `OPEN`? Stop and say so. No pull request on this branch? Stop — do not open one.

## 2. Gather the feedback

```bash
python3 .claude/skills/pr-review-response/fetch-threads.py [PR] [--all]
```

Inline threads are the only feedback with a resolvable state. Review summaries and issue comments
have none, so they are answered in the report to the user, never by resolving something.

## 3. Triage — one verdict per thread

| Verdict            | Means                                                                 | Reply | Resolve | Commit |
| ------------------ | --------------------------------------------------------------------- | ----- | ------- | ------ |
| **Fix**            | the comment is right                                                  | yes   | yes     | yes    |
| **Push back**      | wrong, conflicts with a house convention, or out of scope for this PR | yes   | yes     | no     |
| **Already done**   | a later commit on the branch addresses it                             | yes   | yes     | no     |
| **Needs the user** | a product or requirements decision, or genuine ambiguity              | no    | no      | no     |

Gather the evidence before choosing, not after. Read the file at the **current** line — an
`OUTDATED` thread is anchored to a line that has since moved, and its concern may already be void.
The script prints any branch commits that touched the file after the comment was written; that, not
a guess, is what supports "already done". A push-back cites something checkable **in the plan** — a
[CONTRIBUTING.md](../../../CONTRIBUTING.md) section, [.commit-config.js](../../../.commit-config.js),
an existing pattern elsewhere in the repository (`path:line`), or Terraform or provider
documentation. One with no citation is a preference, and gets dropped.

**Then ask of every thread: does it generalise beyond this diff?** "We don't do it that way here",
"always/never X", a corrected command, a missed step. If so the doc edit ships in the **same commit**
as the code. This is the check the skill exists to stop anyone dropping. Route it:

| The lesson is about                              | Edit                                                                                              |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------- |
| dev process, tooling, testing, releasing         | [CONTRIBUTING.md](../../../CONTRIBUTING.md)                                                       |
| a module's inputs, outputs or behaviour          | the variable or output `description` in the module, then regenerate — module READMEs are generated |
| how Claude should work in this repository        | this skill, or another file under `.claude/`                                                      |

Bot reviewers get the same treatment as people. Being a bot is not itself grounds for a push-back.

## 4. Write the plan, then stop

Per thread: `path:line`, what the comment says, the verdict, the reasoning, and **the exact reply
text that will be posted**. Then the commit subjects, as they will be written. Then `ExitPlanMode`.

**A posted reply never mentions the agent tooling.** No `.claude/` path, no skill name, no agent
memory. Reviewers do not read those, so a reply leaning on one explains nothing and reads as an
appeal to a private rulebook. Give the reason itself, in the reply's own words. Anything the reviewer
can open is fair game: `CONTRIBUTING.md`, a source file or line in the diff
(`azure/scalable-github-ci/variables.tf:21-24`), Terraform or provider docs. The exception is a
thread whose own subject is a `.claude/` file: there, name the file the comment is on and nothing
else.

**Nothing is edited, committed or posted before that plan is approved.** A PR number in the arguments
is a request, not consent.

## 5. Execute, in this order

```bash
# 1 — make the code and doc changes
pnpm turbo validate && pnpm format                        # 2 — what CI's Validate job runs; stop at the first failure
pnpm turbo generate-docs && git status --porcelain        # 3 — what CI's Docs job checks; regenerated READMEs join the same commit
HUSKY=0 git commit -m "fix(azure-github-ci): <subject>"  # 4 — one commit per logical change
git push                                                  # 5
python3 .claude/skills/pr-review-response/respond.py <decisions.json> --confirm   # 6
```

Steps 2 and 3 mirror the `validate` and `docs` jobs in `.github/workflows/pull_request.yml`; a push
that fails either is a red PR the reviewer has to chase. `pnpm format-fix` fixes formatting.

`HUSKY=0` is what the repo's own release script does (`Git.preventHuskyHooks()` in
`_build/run/releaseFinalise.ts`); without it `.husky/prepare-commit-msg` grabs `/dev/tty` and hands
the terminal to commitizen. Write the decisions file to the scratchpad, not the repository.

**Push before replying.** A reply citing a sha that is not on the remote tells the reviewer nothing.
If the push is declined, stop before step 6 and report. Never force-push: it detaches every inline
review comment from its anchor, so review feedback is answered with new commits.

**Read the script's output — a resolve without a reply is a silent half-failure.** Every thread should
print `replied:` before `resolved`. `reply SKIPPED` is only correct when that exact reply is already
posted; anything else resolved with no answer leaves the reviewer a closed thread and no reasoning.
Re-read the threads afterwards and confirm each carries its reply.

## 6. The commit contract

**The subject is the changelog line.** `commit-and-tag-version` copies `type`, `scope` and `subject`
into `CHANGELOG.md` verbatim and discards the body. So: _would this subject make sense in release
notes to someone who never saw the pull request?_ If it contains "review", "comment", "feedback",
"PR" or a reviewer's name, rewrite it.

- Not `fix: Address PR comments`.
  Yes `fix(azure-github-ci): Default the storage account to TLS 1.2`.
- Scope comes from the fixed list in [.commit-config.js](../../../.commit-config.js)
  (`allowCustomScopes: false`): `aws-gitlab-ci`, `azure-gitlab-ci`, `gcp-gitlab-ci`,
  `azure-github-ci`, `gcp-github-ci`, `shared-ci`, `terratest`, `config`, `scripts`. A module with no
  scope of its own (e.g. `azure/scalable-gitlab-ci`) commits unscoped.
- `upperCaseSubject: true`. Capital first letter, no trailing full stop.
- `docs`, `style` and `release` never reach the changelog. `upgrade` **does** (under "Upgrades") —
  use it for provider, tool and dependency bumps. A doc edit driven by section 3 is none of these —
  it rides in the code commit.
- **A commit confined to agent instructions or agent scripts is `docs`** — `.claude/**`,
  `CLAUDE.md` — even when it fixes a real bug in one of the scripts. Nothing there ships, so it does
  not belong in the release notes.
- One commit per logical change. Several comments may collapse into one; unrelated ones do not.

## 7. Report and stop

Threads replied to and resolved, commits made, and anything left for the user. Hand-written changes
the approved plan did not name stay unstaged.

## If it fails

| Symptom                                          | Cause                                                                          |
| ------------------------------------------------ | ------------------------------------------------------------------------------ |
| `gh pr view` exits 1, "no pull requests found"   | the branch has no PR — open one first, or pass a number                        |
| no threads printed, but the PR shows comments    | the feedback is a review summary or an issue comment; both are printed         |
| a thread is flagged `CANNOT RESOLVE`             | the PR is merged or from a fork — reply if you can, report rather than resolve |
| `git commit` hangs                               | `HUSKY=0` was omitted and `prepare-commit-msg` got a terminal                  |
| `Could not resolve to a node with the global id` | the thread id is from another repository, or the thread was deleted            |
| `respond.py` reports `reply SKIPPED`             | that exact reply is already the last comment — a rerun, working as intended    |
| `gh` targets the wrong repository                | two remotes (`origin` on GitHub, `gitlab`) — run `gh repo set-default Rocketmakers/terraform-modules` |
