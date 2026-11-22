---
name: architect
description: Settle the shape (data structures, types, signatures, module boundaries) before writing code that crosses a function boundary — by sketching competing designs and prototyping open questions, not by writing a long plan.
argument-hint: "<what you're about to build>"
disable-model-invocation: true
---

# Architect

Plan through code. Two common failures: taking the first design, and polishing a plan no code has tested.

1. **Ground**: trace every system `$ARGUMENTS` touches — callers, data flow, state owners, existing helpers. Restate the goal and the caller's view in one paragraph.
2. **Sketch two different shapes**: for each, the call-site usage first, then core types, public signatures, module boundaries, and where each piece of state lives. Real code (stubs with placeholder bodies), not prose. For a large, contested or hard-to-reverse design, get independent sketches (subagents, ideally on different models) and judge them with a reviewer that didn't write any.
3. **Settle open questions by running something**: a layout, a timing, a library's actual behaviour → a throwaway prototype (scratch dir, variants behind one switch, measured or screenshotted). Don't debate what a prototype can answer.
4. **Pick** the shape where each piece of state has one owner, each task has one way to do it, callers need to know least, and illegal states are unrepresentable. Shared code: write the README/tutorial for a caller first and check the shape against it.
5. **Implement against the sketch.** If unexpected parameters or state appear, surface the discrepancy. If the same workaround shows up at unrelated call sites, or the types need `any`/forced casts, the design is wrong — scrap it and redesign rather than patch.
6. A written multi-step plan comes only after the design settles: small independently-landable units, each ending in its own proof (tests alone don't count — the code must have run). Delete the plan when the work lands. Don't adversarially review an abstract plan; review what got built.

**Reply:** the chosen shape (types/signatures), the rejected one and why (table), what prototypes showed (artifacts), open decisions for the user.
