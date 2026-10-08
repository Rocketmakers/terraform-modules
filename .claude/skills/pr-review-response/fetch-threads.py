#!/usr/bin/env python3
"""Print the open review feedback on a pull request, with the evidence triage needs.

Review feedback does not all arrive as inline threads. `reviewThreads` is the only source with a
resolvable state; a review summary body and an issue-level comment have no resolve concept and are
invisible to any query that looks at threads alone. All three are printed.

Each thread also carries the branch commits that touched its file after the comment was written, so
an "already done" verdict rests on evidence rather than a guess, and viewerCanReply/viewerCanResolve,
so a permission problem surfaces during triage instead of as a 403 halfway through posting.

Usage: python3 .claude/skills/pr-review-response/fetch-threads.py [PR number] [--all]
"""

import json
import subprocess
import sys
from datetime import datetime

QUERY = """
query($owner:String!,$repo:String!,$number:Int!,$cursor:String){
  repository(owner:$owner,name:$repo){
    pullRequest(number:$number){
      reviewThreads(first:50,after:$cursor){
        pageInfo{hasNextPage endCursor}
        nodes{
          id isResolved isOutdated path line originalLine diffSide
          viewerCanReply viewerCanResolve
          comments(first:30){nodes{author{login} body createdAt url viewerDidAuthor}}
        }
      }
      reviews(first:30){nodes{author{login} state submittedAt body url}}
      comments(first:30){nodes{author{login} body createdAt url}}
    }
  }
}
"""


def gh(*args):
    result = subprocess.run(["gh", *args], capture_output=True, text=True)
    if result.returncode != 0:
        sys.exit("gh %s failed:\n%s" % (" ".join(args), result.stderr.strip()))
    return result.stdout


def git(*args):
    result = subprocess.run(["git", *args], capture_output=True, text=True)
    return result.stdout if result.returncode == 0 else ""


def resolve_target(argv):
    owner_repo = json.loads(gh("repo", "view", "--json", "owner,name"))
    owner, repo = owner_repo["owner"]["login"], owner_repo["name"]
    explicit = [a for a in argv if a.isdigit()]
    if explicit:
        pull = json.loads(gh("pr", "view", explicit[0], "--json", "number,state,isDraft,baseRefName,url"))
    else:
        pull = json.loads(gh("pr", "view", "--json", "number,state,isDraft,baseRefName,url"))
    return owner, repo, pull


def fetch(owner, repo, number):
    threads, cursor, pull = [], None, None
    while True:
        args = ["api", "graphql", "-f", "query=" + QUERY, "-F", "owner=" + owner, "-F", "repo=" + repo,
                "-F", "number=%d" % number]
        if cursor:
            args += ["-F", "cursor=" + cursor]
        pull = json.loads(gh(*args))["data"]["repository"]["pullRequest"]
        page = pull["reviewThreads"]
        threads += page["nodes"]
        if not page["pageInfo"]["hasNextPage"]:
            return threads, pull
        cursor = page["pageInfo"]["endCursor"]


def moment(text):
    """Parse an ISO-8601 instant to an aware datetime. Compare these, never the strings: git reports
    a local offset and GitHub reports Z, so `17:36:17+01:00` sorts after `16:46:37Z` while actually
    preceding it by ten minutes."""
    return datetime.fromisoformat(text.replace("Z", "+00:00"))


def commits_after(base, path, when):
    """Branch commits touching `path` that are newer than `when`, as `sha date subject` lines."""
    cutoff = moment(when)
    for ref in ("origin/" + base, base):
        log = git("log", "%s..HEAD" % ref, "--format=%h\t%cI\t%s", "--", path)
        if log:
            return [l for l in log.splitlines() if moment(l.split("\t")[1]) > cutoff]
    return []


def show_thread(index, thread, base):
    head = thread["comments"]["nodes"][0]
    flags = [f for f, on in (("OUTDATED", thread["isOutdated"]), ("RESOLVED", thread["isResolved"]),
                             ("CANNOT REPLY", not thread["viewerCanReply"]),
                             ("CANNOT RESOLVE", not thread["viewerCanResolve"])) if on]
    print("\n[%d] %s:%s%s" % (index, thread["path"], thread["line"] or thread["originalLine"],
                              "  " + " ".join(flags) if flags else ""))
    print("    thread %s" % thread["id"])
    for comment in thread["comments"]["nodes"]:
        who = comment["author"]["login"] if comment["author"] else "(deleted)"
        print("    %s at %s%s" % (who, comment["createdAt"], "  [yours]" if comment["viewerDidAuthor"] else ""))
        print("    %s" % comment["url"])
        for line in comment["body"].strip().splitlines():
            print("      | %s" % line)
    later = commits_after(base, thread["path"], head["createdAt"])
    if later:
        print("    commits on this branch touching %s since the comment:" % thread["path"])
        for line in later:
            print("      %s" % line.replace("\t", "  "))


def show_loose(label, nodes, key):
    bodies = [n for n in nodes if (n.get("body") or "").strip()]
    if not bodies:
        return
    print("\n--- %s (no resolvable state; answer these in the report, not by resolving) ---" % label)
    for node in bodies:
        who = node["author"]["login"] if node["author"] else "(deleted)"
        print("\n  %s %s  %s" % (who, node.get(key, ""), node["url"]))
        for line in node["body"].strip().splitlines():
            print("    | %s" % line)


def main():
    show_all = "--all" in sys.argv
    owner, repo, pull_meta = resolve_target(sys.argv[1:])
    number, base = pull_meta["number"], pull_meta["baseRefName"]

    print("%s/%s PR #%d  %s  base %s%s" % (owner, repo, number, pull_meta["state"], base,
                                           "  DRAFT" if pull_meta["isDraft"] else ""))
    print(pull_meta["url"])
    if pull_meta["state"] != "OPEN":
        print("\nWARNING: this pull request is %s. Reading it is fine; do not reply, resolve or commit\n"
              "against it without saying so first." % pull_meta["state"])

    threads, pull = fetch(owner, repo, number)
    shown = threads if show_all else [t for t in threads if not t["isResolved"]]
    print("\n%d thread(s), %d unresolved. Showing %d.%s"
          % (len(threads), sum(1 for t in threads if not t["isResolved"]), len(shown),
             "" if show_all else "  Pass --all for resolved threads too."))

    for index, thread in enumerate(shown, 1):
        show_thread(index, thread, base)

    show_loose("Review summaries", pull["reviews"]["nodes"], "submittedAt")
    show_loose("Issue comments", pull["comments"]["nodes"], "createdAt")

    if not shown and not any((r.get("body") or "").strip() for r in pull["reviews"]["nodes"]) \
            and not any((c.get("body") or "").strip() for c in pull["comments"]["nodes"]):
        print("\nNo unresolved feedback.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
