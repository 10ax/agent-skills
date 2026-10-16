---
name: setup-pstack
description: Configure which models pstack uses per role and at what reasoning budget. Detects your available models and writes the mapping that overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
---

# Setup pstack

A pstack role runs on an agent, and in OpenCode the model belongs to the agent. So setup writes two things: the `model:` line of each pstack agent under `~/.config/opencode/agents/`, and `~/.config/opencode/pstack-models.md`, the role-to-agent record the pstack skills read.

## Steps

### 1. Detect available models

List the models this session can call, with `opencode models` or the models tool. That is the dependable source. Never write a slug you have not confirmed is available. Record the effort variants each family actually offers (`#low`, `#high`, `#max`, `#xhigh`) rather than assuming a ladder, because they differ per model.

### 2. Load current state

If `~/.config/opencode/pstack-models.md` already exists, read its `# budget` line and its role values and treat them as the current choices. Otherwise start from the defaults in step 4. A role that is not in step 4 has been retired: drop its line.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Prefer the question tool over free text. Offer these four options with these exact labels, and name the current budget when the file records one. With no file, say that `large` matches the skill defaults.

- `unlimited — max reasoning`
- `large — xhigh reasoning`
- `medium — high reasoning`
- `small — medium reasoning`

**(b) Apply it.** The budget sets each role's effort variant. `unlimited`, `large`, `medium`, and `small` target `max`, `xhigh`, `high`, or `medium`. Where a model has no variant at the target, use the highest variant it does have at or below the target and say which role was stepped down. The families in play today are `opencode-go/grok-4.7` (`low`, `medium`, `high`, `xhigh`) and `opencode-go/glm-5.3` (`low`, `high`, `max`), so `unlimited` leaves grok at `xhigh`.

**(c) Show the roles and confirm.** Show every role with its agent and that agent's model, marking any slug not in the detected set as needing a choice. Ask whether to accept as-is or change specific roles, offering the detected models as the options, one entry per panel role. A panel role's value is a list, and one subagent runs per entry, so the list length sets the fan-out.

### 4. Validate

Every real slug written must be in the detected set. If a chosen slug is not available, stop and ask again. Every role must also have an agent file, since a role with no agent cannot run.

### 5. Write

Write `~/.config/opencode/pstack-models.md`: a `# budget` line with the chosen label and its target effort, then one line per role. Overwrite the whole file so re-runs stay idempotent. Shape:

```
# pstack model configuration. One line per role, each naming the agent that
# carries the role's model. A role means an agent; the model itself lives on the
# agent's `model:` line under ~/.config/opencode/agents/. Change one there, then
# re-run /setup-pstack so this record stays true.
# budget: large (xhigh)

feature, refactoring: poteto-agent
bug-fix: poteto-agent
perf-issue: poteto-agent
hillclimb: poteto-agent
judgment and prose: poteto-judge
hardest tasks: poteto-judge
how explorer: poteto-reviewer
how explainer: poteto-judge
why investigators: poteto-agent
why synthesizer: poteto-judge
reflect tooling: poteto-reviewer
reflect judgment, divergent, synthesizer: poteto-judge
arena runners: poteto-judge, poteto-reviewer
arena cross-judge pool: poteto-judge, poteto-reviewer
swarm workers: poteto-agent
architect runners: poteto-judge, poteto-reviewer
interrogate reviewers: poteto-judge, poteto-reviewer
```

Then write each agent's `model:` line under `~/.config/opencode/agents/`. The defaults are `poteto-agent` and `poteto-reviewer` on `opencode-go/grok-4.7#xhigh`, and `poteto-judge` on `opencode-go/glm-5.3#max`. `comment-sicko` carries no model line and inherits the session model, which is deliberate: it reviews prose, so the parent's model is the right one.

### 6. Confirm

Tell the user the file and the agent models were written, and that they apply to new sessions. Re-running this skill updates both.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, invoke `/create-verification-skill`. On no, move on without pushing.
