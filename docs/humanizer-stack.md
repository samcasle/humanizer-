# The two-pass humanizer pipeline

This repo now runs the humanizer as a **two-pass pipeline**, following
[NulightJens/humanizer-stack](https://github.com/NulightJens/humanizer-stack).

| Pass | Skill | Fixes | Source |
|---|---|---|---|
| 1 (surface) | `humanizer` | words, phrasing, punctuation: "delve", em dashes, rule of three, negative parallelism, promotional language | this repo's root `SKILL.md` (v2.9.1) |
| 2 (structural) | `structural-humanizer` | discourse shape: stated lessons, tidy single-track arcs, embodied-emotion performance, vague reference, shape convergence | vendored from humanizer-stack |

Surface pass first, structural pass second. They are different jobs.

## Why two passes

The structural pass is the one that matters, and it is the one everybody skips.

In the StoryScope study (Russell et al. 2026, arXiv:2604.03136), discourse-level
features alone identified AI text at 93.2% F1 with all style features withheld.
The authors then ran AI text through a professional span-level rewriting framework,
which is functionally a surface humanizer. Detection dropped **1.6 points**.

So a piece can pass every vocabulary check and still read as machine-written,
because the tell is the shape: the lesson gets stated four times, the arc resolves
cleanly, the emotion is performed through the body, and nothing is ever named.

## A note on versions

humanizer-stack bundles its own copy of the surface `humanizer` skill at **v2.1.1**,
forked from an older state of this repository. This repo is at **v2.9.1**, which is
newer and includes the no-fabrication rule and invocation modes. So the vendored
copy is deliberately **not** installed. Pass 1 uses this repo's own `SKILL.md`;
`.claude/skills/humanizer/SKILL.md` is a symlink to it, so there is one source of truth.

Only the genuinely new material from humanizer-stack is vendored here:
`structural-humanizer` and the two scanners.

## Install

Both skills are already present as project skills in `.claude/skills/`, so any agent
session opened in this repo picks them up automatically.

To install them globally, for every project:

```bash
./install.sh              # symlink, so git pull updates them
./install.sh --copy       # independent copies
./install.sh --force      # replace an existing install (backs it up first)
```

On Windows, in PowerShell:

```powershell
.\install.ps1             # copies into %USERPROFILE%\.claude\skills
.\install.ps1 -Force      # replace an existing install (backs it up first)
.\install.ps1 -Project    # install into .\.claude\skills instead
```

Start a new agent session afterward so the skills load.

### A Windows caveat

`.claude/skills/humanizer/SKILL.md` is a symlink to the repo root `SKILL.md`. Git on
Windows checks symlinks out as plain text stubs containing the target path, unless
Developer Mode is enabled or `core.symlinks=true`. So in a Windows working tree that
file may be a 17-byte stub rather than the skill.

`install.ps1` sidesteps this by always copying the real root `SKILL.md`, and warns if
the result looks too small. The stub only affects using this repo as a *project*
skill directory on Windows; the installed copy is fine.

Note also that Windows PowerShell 5.1 does not support `&&` as a command separator.
Use separate lines or `;`. PowerShell 7+ supports `&&`.

## Use

Invoke by asking, in plain language:

```
humanize this post
de-slop this lesson
run the structural pass on draft.md
deep humanize draft.md
```

Pass 1 rewrites words. Pass 2 rewrites shape. Run them in that order; asking for a
"deep humanize" or "full humanize" should get you both.

## Scanners

Deterministic greps that catch the mechanical subset. They are not a substitute for
the skills, and they do not read for judgment.

```bash
python3 scripts/copy_scan.py draft.md
python3 .claude/skills/structural-humanizer/scripts/structural_scan.py draft.md
```

Both accept:

- `--json` for machine-readable output
- `--strict` to exit 1 when tells are found, for hooks and CI

The structural scanner also reports metrics: word count, reader-address rate,
numbers per 100 words, and paragraph-length coefficient of variation. Low numbers
per 100 words usually means the piece names nothing real, which is audit 4.

Two cautions. The scanners match on substrings, so they flag your own editorial
notes and placeholders too. And a clean scan means only that the grep-able tells are
gone: theme explicitness, structural tidiness, and shape convergence are judgment
calls that require the skill, and `structural_scan.py` says so in its own output.

## The trap

The study's deepest finding is convergence: all five AI models it tested occupied one
tight region of structural space, while human writing was dispersed. Rarity is the
human signal.

That means the fix cannot become a new default. If every piece now opens mid-scene,
names its feelings plainly, and ends unresolved, that is just a new detectable
cluster. Pick one or two interventions per piece, vary them across pieces, and be
able to say why this piece got this shape. The intervention menu is in
`.claude/skills/structural-humanizer/SKILL.md`.

## Attribution

See [ATTRIBUTION-humanizer-stack.md](../ATTRIBUTION-humanizer-stack.md). Everything
vendored here is MIT. The surface pattern catalog traces back to
[Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)
under CC BY-SA 4.0.
