# Commit and PR message dependency-loading eval

Measure how often a model loads `documentation-principles` when asked to use `commit-and-pr-messages` to draft a PR message. Each trial starts a fresh OpenCode session in a new checkout of a pinned commit from [rspec-capturing-formatter](https://github.com/FooBarWidget/rspec-capturing-formatter). The production skills are copied unchanged; this eval does not fix or strengthen their dependency instructions.

The default is **20 trials per commit per target**: 40 model calls for one model with the two commits in [suite.json](suite.json). This is a useful initial regression screen, not a precise estimate of a rare failure rate. A 20/20 result still has a roughly 84% lower bound on its 95% Wilson interval. Neither commit has yet been shown to trigger the problem more reliably.

## Run it

Authenticate with OpenCode first, or supply provider credentials through environment variables. The eval does not inherit your global OpenCode configuration or plugins.

Run these commands from this directory. Set `MODEL` to the actual provider/model ID reported by `opencode models`; do not assume that a display name such as GPT Luna is its provider ID.

```sh
export MODEL=provider/model-id
ruby run.rb --model "$MODEL" --prepare-only
ruby run.rb --model "$MODEL" --variant high --out results/luna-high-baseline
```

The first command verifies the commits and skill discovery without drafting messages. The second makes 40 model calls. Omit `--variant` to use the provider default, or set it to a reasoning variant supported by that model. The output directory must not already exist.

For an initial pilot and an explicit-dependency control:

```sh
ruby run.rb --model "$MODEL" --repetitions 2 --out results/pilot
ruby run.rb --model "$MODEL" --repetitions 2 --mode control --out results/control
```

[The baseline prompt](prompts/baseline.md) explicitly names only the parent skill. [The control prompt](prompts/control.md) names both skills. If the control fails, investigate availability, permissions, model tool use, and trace compatibility before interpreting a baseline failure as a dependency-following problem.

Use `--repo /path/to/clone` to avoid another GitHub download. It must contain both commits and their parents. Use `--skills-root /path/to/skills` to compare revised skill instructions against the baseline. The escalation policy always comes from this repository and is supplied as an always-on instruction; it is not part of the load-rate measurement.

For custom provider endpoints or model definitions, `--provider-config /path/to/providers.json` accepts an OpenCode JSON object containing only `provider` and/or `enabled_providers`. Keep credentials outside this eval directory. The runner copies the existing OpenCode authentication file to temporary homes, never to the result directory. Environment-based provider credentials remain available to OpenCode. Ordinary OpenCode provider routing, authentication, and background title generation may still make their own requests.

## Compare models and reasoning efforts

Pass `--matrix /path/to/targets.json` instead of `--model` and `--variant`. The file is a JSON array:

```json
[
  { "harness": "opencode", "model": "provider/luna-model-id", "variant": "high" },
  { "harness": "opencode", "model": "provider/luna-model-id", "variant": "low" },
  { "harness": "opencode", "model": "provider/other-model-id" }
]
```

Replace the placeholder IDs with real ones. Trials are sequential and interleaved by repetition, commit, and target. Results are grouped by commit and target; do not pool models, efforts, control prompts, or different skill versions into a single rate.

Only OpenCode is implemented. [lib/opencode.rb](lib/opencode.rb) owns configuration, execution, and conversion of raw traces into tool, text, finish, and error events. [lib/trace_scorer.rb](lib/trace_scorer.rb) scores those normalized events independently of the harness. Another harness would need an adapter and runner/CLI wiring, not a new statistical scoring scheme. Keep the task and skill snapshots equivalent when comparing harnesses; their surrounding prompts and skill discovery mechanisms will still differ.

## Read the results

The primary load evidence is a **completed native `skill` call** with the exact skill name and an output containing OpenCode's corresponding `skill_content` marker, before the last nonempty assistant response. A prose claim, a filename mention, a failed call, or an empty tool output does not count. Duplicate tool events count once. Loads before the parent skill also count: this measures whether the required skills were loaded, not which instruction caused the load.

Each valid trial has one status:

- `pass`: both skills were loaded.
- `dependency-missing`: the parent was loaded, but the dependency was not.
- `parent-missing`: the parent was not loaded, whether or not the dependency was.

An `invalid` trial has a harness failure, timeout, API error, malformed/unknown trace event, unexpected session count, missing response, or abnormal completion. Invalid trials are reported but excluded from rate denominators. Errors setting up checkouts, launching the executable, or writing artifacts stop the run and are recorded separately rather than silently discarded. There are no automatic retries.

The summary reports counts, rates, and 95% Wilson intervals per commit and target. Start with `dependency_given_parent`, and check `parent_loading` and the invalid count alongside it. `dependency_loading` reports dependency loading across all valid trials; `both_loading` reports end-to-end success. A zero denominator produces `null`, not a misleading zero rate.

`dependency_content_delivered` is a secondary diagnostic: any completed tool output containing the entire snapshotted dependency body counts, including a line-numbered file read. It does not change the native-load verdict. The eval does not judge PR prose, whether principles were applied correctly, or the dependency's instruction to reload itself before finalizing.

Results include:

- A manifest with the suite, targets, effective trial counts, Ruby version, and hashes of the implementation, skills, prompt, and provider configuration.
- Exact skill, prompt, and escalation-policy snapshots, plus commit metadata and patches.
- OpenCode's version and discovered skill paths from preflight.
- Each trial's prompt, invocation, raw JSONL trace, stderr, normalized events, proposed message, and scored result.
- A summary updated after each completed trial.

Temporary checkouts, isolated homes, authentication copies, and OpenCode session data are removed afterward. Raw traces remain in the output directory; treat them as potentially sensitive. Interrupting with Ctrl-C retains completed results and any current trace. Exit status is 0 for a completed run, 2 if any scored trial was invalid, 1 for a setup/runtime exception, and 130 for interruption. Behavioral failures are data, not a nonzero process exit.

## Interpretation and isolation

The task asks the model to compare the selected commit against its first parent. The checkout contains the committed change and history, including the original commit message; that is intentional context, not a gold-standard PR body. The eval cannot tell whether a skill description independently triggered the dependency load, and it does not establish general performance across repositories or task types. Fix the cases before comparing skill variants rather than selecting whichever commit produces the desired result afterward.

Each trial receives only the two local skills, the escalation policy, and OpenCode's built-in build-agent behavior. User home and XDG paths are isolated, inherited OpenCode overrides are cleared, and external plugins are disabled. Preflight rejects unexpected skill discovery or configured instructions/plugins. Checkouts containing root agent configuration are rejected rather than silently altered. Editing, network tools, and delegation are denied; local reads, skills, and a small set of Git inspection commands are allowed. These are harness permissions, not an operating-system security sandbox. Managed configuration and provider-side defaults can still affect runs; record their use when comparing results.

The prompts target GPT Luna but leave the same drafting task usable with other models. They deliberately do not coach the baseline through dependency loading. This follows the general recommendation to pin inputs and evaluate nondeterministic behavior in [OpenAI's prompting guidance](https://developers.openai.com/api/docs/guides/prompt-engineering); no Luna-specific guidance was consulted and no reliability improvement is claimed. OpenCode's [CLI](https://opencode.ai/docs/cli/), [skill](https://opencode.ai/docs/skills/), and [configuration](https://opencode.ai/docs/config/) docs describe the adapter's interfaces.

## Tests

The Minitest suite uses synthetic traces and local Ruby subprocesses, not model calls or GitHub. Install Minitest if your Ruby distribution does not include it, then run:

```sh
ruby test/eval_test.rb
```

The Ruby rewrite has not been executed or integration-tested. Run the tests and `--prepare-only` first, then inspect a small pilot's raw traces and scores before spending on the full sample.
