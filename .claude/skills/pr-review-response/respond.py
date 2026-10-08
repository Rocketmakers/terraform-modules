#!/usr/bin/env python3
"""Post the approved replies to a pull request's review threads, then resolve the ones dealt with.

Takes a decisions file rather than command-line arguments for two reasons. Reply bodies are
multi-line prose full of backticks and quotes — the thing most likely to be mangled in transit — and
the file is a record of what the approved plan actually said.

Replies are not idempotent: GitHub will happily post the same one twice. Before replying to a thread
this re-reads it and skips any whose last comment is this exact reply, so a rerun after a partial
failure is safe. It compares the body rather than the author: on this repository the reviewer and the
person running the script are usually the same GitHub account, so "the last comment is mine" is true
of every thread the user opened themselves and would skip every reply that matters.

Decisions file: [{"thread": "PRRT_...", "reply": "...", "resolve": true}, ...]
  `reply` may be omitted to resolve without commenting. `resolve` defaults to false — never resolve a
  thread you are only asking the user about.

Usage: python3 .claude/skills/pr-review-response/respond.py <decisions.json> --confirm
"""

import json
import subprocess
import sys

THREAD = """
query($id:ID!){
  node(id:$id){
    ... on PullRequestReviewThread{
      isResolved viewerCanReply viewerCanResolve path line
      comments(last:1){nodes{viewerDidAuthor author{login} body}}
    }
  }
}
"""

REPLY = """
mutation($id:ID!,$body:String!){
  addPullRequestReviewThreadReply(input:{pullRequestReviewThreadId:$id,body:$body}){
    comment{url}
  }
}
"""

RESOLVE = """
mutation($id:ID!){
  resolveReviewThread(input:{threadId:$id}){thread{isResolved}}
}
"""


def graphql(query, **variables):
    args = ["gh", "api", "graphql", "-f", "query=" + query]
    for name, value in variables.items():
        args += ["-f", "%s=%s" % (name, value)]
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode != 0:
        return None, result.stderr.strip().splitlines()[0] if result.stderr.strip() else "gh failed"
    payload = json.loads(result.stdout)
    if payload.get("errors"):
        return None, payload["errors"][0].get("message", "unknown GraphQL error")
    return payload["data"], None


def act(decision):
    """Return (messages, ok) for one thread."""
    thread_id = decision["thread"]
    reply = (decision.get("reply") or "").strip()
    resolve = decision.get("resolve", False)
    lines, ok = [], True

    data, error = graphql(THREAD, id=thread_id)
    if error:
        return ["  could not read thread: %s" % error], False
    thread = data["node"]
    if not thread:
        return ["  no such thread on this repository"], False

    label = "%s:%s" % (thread["path"], thread["line"])
    lines.append("  %s" % label)

    if reply:
        last = thread["comments"]["nodes"]
        already_posted = (
            last
            and last[0]["viewerDidAuthor"]
            and last[0].get("body", "").strip() == reply.strip()
        )
        if already_posted:
            lines.append("  reply SKIPPED — this exact reply is already the last comment")
        elif not thread["viewerCanReply"]:
            lines.append("  reply FAILED — you cannot reply to this thread")
            ok = False
        else:
            data, error = graphql(REPLY, id=thread_id, body=reply)
            if error:
                lines.append("  reply FAILED — %s" % error)
                ok = False
            else:
                lines.append("  replied: %s" % data["addPullRequestReviewThreadReply"]["comment"]["url"])

    if resolve:
        if thread["isResolved"]:
            lines.append("  resolve skipped — already resolved")
        elif not thread["viewerCanResolve"]:
            lines.append("  resolve FAILED — you cannot resolve this thread")
            ok = False
        else:
            _, error = graphql(RESOLVE, id=thread_id)
            if error:
                lines.append("  resolve FAILED — %s" % error)
                ok = False
            else:
                lines.append("  resolved")

    return lines, ok


def main():
    arguments = [a for a in sys.argv[1:] if a != "--confirm"]
    if len(arguments) != 1:
        sys.exit(__doc__.strip().splitlines()[-1])
    if "--confirm" not in sys.argv:
        sys.exit("Refusing to post anything without --confirm. This writes to a pull request other\n"
                 "people are reading; run it only once the plan naming these replies is approved.")

    decisions = json.load(open(arguments[0]))
    if not isinstance(decisions, list):
        sys.exit("Decisions file must be a JSON list of {thread, reply, resolve} objects.")

    failures = 0
    for index, decision in enumerate(decisions, 1):
        print("[%d/%d] %s" % (index, len(decisions), decision["thread"]))
        lines, ok = act(decision)
        print("\n".join(lines))
        failures += 0 if ok else 1

    print("\n%d thread(s) handled, %d failed." % (len(decisions), failures))
    if failures:
        print("Rerun with the same file once the cause is fixed — threads already replied to are skipped.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
