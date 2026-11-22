---
name: sharpen
description: Rewrite a task prompt the way an expert would ask for it — without doing the task.
argument-hint: "<the task you're about to ask for>"
disable-model-invocation: true
---

# Sharpen

Do NOT do the task in `$ARGUMENTS`. Improve the request.

1. **What an expert would add** that the user didn't ask for: edge cases, non-goals, compatibility, rollout, observability, the audience of the output.
2. **Raw material** they'd start from: which files, docs, data, logs, prior art in this repo (look — name real paths).
3. **Method and tools**: the playbook (investigation / bug fix / feature / refactor / perf / UI), the commands and levers in this repo (`vibe verify`, scripts, QA flags).
4. **Outside check**: how we'll know the result is right — a falsifiable done-criterion and the evidence to collect.
5. **Open questions** only if the answer changes the work materially (max 3).

Then output the rewritten prompt in a fenced block, ready to send, in the user's language. Keep it tight — a sharper prompt, not a longer one.
