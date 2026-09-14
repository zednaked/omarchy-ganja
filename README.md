# zed.ganja

A cannabis plant that grows in your Omarchy bar.

The same grow as [Ganja-TUI](https://github.com/zednaked/Ganja-TUI) — the 35
strains with real genetics, the same procedural 70×28 ASCII art, the same save
format — inside the Omarchy shell, in pure QML. No binary, no resident process,
no Rust required. Closed, the whole plant costs **one 60-second timer** doing
arithmetic on numbers already in memory. Stopped, it costs nothing at all.

In the bar: one glyph per stage, and a dot that lights up when there is
something to do. Left click opens the growing room, **right click stops and
restarts the simulation**, middle click waters.

Interface in **English or Portuguese** (`l`), defaulting to the machine's
locale.

> 🇧🇷 A versão em português deste documento, mais longa e com os porquês, está em
> [README.pt-BR.md](README.pt-BR.md).

---

## Install

From the marketplace listing, or straight from git:

```sh
omarchy plugin add https://github.com/zednaked/omarchy-ganja --enable
omarchy-restart-shell
```

The restart is not ceremony: Omarchy starts Quickshell with
`QS_DISABLE_FILE_WATCHER=1` on purpose, so a freshly copied plugin is not
picked up until the shell comes back. Nothing fails visibly in the meantime,
which is worse.

The plant is born on first load. The save lives in
`~/.local/share/zed.ganja/save.json`.

Coming from the version that shipped inside `omarchy-guest`? The old save
(`~/.local/share/omarchy-guest/ganja/save.json`) is read once on first load and
migrated to the new path. The old file is left untouched, so going back is also
just going back.

To place the bar widget by hand, one line in `~/.config/omarchy/shell.json`
under `bar.layout.left`, `center` or `right`:

```jsonc
{ "id": "zed.ganja" }
```

## Remove

```sh
omarchy plugin remove zed.ganja
omarchy-restart-shell
```

That takes the plugin out of `~/.config/omarchy/plugins/` and its id out of the
bar layout in `shell.json`. Nothing else of yours is touched.

The plant is **not** removed with it, on purpose: a save is the one thing here
that took time to make, and uninstalling a plugin is not the same as saying
"throw away the plant". To delete it too:

```sh
rm -rf ~/.local/share/zed.ganja
```

**Requirements:** Omarchy with `omarchy-shell` (plugin schemaVersion 1),
`python3` (for `save.py`, the disk helper — see *The save, and the TUI*), and a
Nerd Font in the bar — the stage glyphs come from the Material Design set
(`md-sprout`, `md-cannabis`, …). `make glyphs` checks the eight glyphs against
the font actually installed on the machine.

---

## Keys

Inside the overlay:

| key | what it does |
|---|---|
| `w` | water (+40, stopping at the top of the optimal band) |
| `n` | feed, NPK (+40, same) |
| `a` | **automatic mode**: the plant looks after itself |
| `p` | **stop/restart the simulation** — stopped, the plugin costs zero |
| `l` | language: English ⇄ Portuguese |
| `t` | window size: full → large → medium → small → window |
| `h` | harvest, if it is ready |
| `v` | cycle colors: Normal → Zen → Rainbow → Matrix |
| `f` | toggle the **demo**: 130000x on a copy |
| `Shift+F` | toggle **turbo**: 130000x on the real plant |
| `Tab` | harvest history |
| `q` / `Esc` | close |

In the bar, three buttons: left opens the room, **right stops and restarts**,
middle waters. All three flash the icon, because an action with no visible
response looks like it did not happen.

Over IPC, for scripts and agents:

```sh
omarchy-shell ganja toggle
omarchy-shell ganja water
omarchy-shell ganja feed
omarchy-shell ganja harvest
omarchy-shell ganja auto
omarchy-shell ganja mode
omarchy-shell ganja turbo
omarchy-shell ganja pause           # toggles; stop and start force one side
omarchy-shell ganja lang en         # or pt, or "" to toggle
omarchy-shell ganja scale 400       # rhythm, or "" to read it back
omarchy-shell ganja window medium   # or "" to cycle
omarchy-shell ganja status
```

What IPC **returns** follows the chosen language; what it **accepts** does not.
`ganja window medium` is the same command in either language — a command that
renamed itself along with a reading preference would be a script that breaks
when someone presses `l`.

---

## Stopping the simulation

`p`, or right click on the bar icon. Stopped:

- the 60-second `Timer` **does not run** — not a cheap timer, no timer;
- the overlay asks for no frames: open, it is a photograph, and says so;
- the alert dot does not pulse (nothing is getting worse, so nothing is urgent);
- the bar icon swaps the stage glyph for `󰒲` and **dims** to 40%.

Dimming is not a color change, and that is deliberate: the bar's rule is that
icons follow the theme, and a red icon in a row of same-toned symbols reads as a
system error rather than as "the user turned this off". The glyph is `md-sleep`
and not `md-pause` because the shell's own media widget already uses the pause
glyph to mean something else in the same bar.

**This is persisted**, like every other setting here — see *What the save
keeps* below. Turning on either fast mode restarts the clock first, because
130000x behind a stopped clock would do nothing at all, and "nothing happened"
reads as a broken feature.

The clock here is session time, not wall time (machine off, plant paused), so
stopping costs nothing later: the plant does not wake up thirsty or dead, it
wakes up exactly where it was left.

---

## Language

`l` switches English and Portuguese, and the **whole** interface follows:
footer, strain panel, meters, harvest history, bar tooltip, messages, IPC
returns, the date format, even the decimal separator (`18.5%` / `18,5%`).

The strain data switches too — `difficulty Easy` becomes `dificuldade fácil`,
`Earthy, Sweet, Grape` becomes `terroso, doce, uva`. Translation is **per
field**, not per word: "Medium" is *média* as a difficulty and *médio* as a
yield, and a flat word-to-word dictionary would get the gender wrong half the
time.

The first language comes from the locale (`LANG=pt_BR…` → Portuguese); after
that the choice wins, and it goes to the save. What the save stores is always
the **id** and never the label — `"window_mode": "medium"`, `"visual_mode":
"Zen"` — otherwise the file would change shape along with the language and a
save written in Portuguese would not open in English.

Strain names are never translated: Purple Kush is Purple Kush.

Adding a third language is one object in `I18n.js` (108 keys) plus a vocabulary
table for the strain data (8 terpenes, 30 aromas, 11 effects, 12 enum terms).

---

## What the save keeps

Everything you change, except one thing that cannot be kept and one that should
not be. A setting that goes back to its default on the next boot is not a
setting, it is a question asked again.

| you change | kept |
|---|---|
| language (`l`) | yes |
| colors / visual mode (`v`) | yes |
| window size and kind (`t`) | yes |
| automatic care (`a`) | yes |
| **stopped** (`p`, right click) | yes |
| **turbo** (`Shift+F`) | yes — it survives closing the room and restarting the shell |
| **the rhythm** (`ganja scale`) | yes, and it wins over the manifest |
| the plant, the harvests, the hours | yes, that is the point |
| demo (`f`) | **no**, and it cannot be |
| the harvests tab (`Tab`) | no, on purpose |

**The demo cannot be kept** because of what it is: it simulates on a *copy* and
nothing it does counts, so switching it off throws that copy away. Saving it
would save the intention of simulating a throwaway on the next boot, which is
not a state anything could restore.

**The harvests tab is not a setting**, it is where you were looking. The plant
is the reason the window exists, so opening the room shows the plant — always,
including right after you closed it on the list. If you want it to reopen where
you left it, say so and it is one line.

Turbo used to be in the "not kept" column, and that was the wrong call: it is
the rhythm someone chooses, not a mode they watch, and re-enabling it every
session was a question asked over and over. What it costs is now documented
rather than prevented — with the room closed, turbo harvests the plant about
once a minute, so the 100-harvest history turns over in under two hours. The
red `·· TURBO 130000x ··` in the header says it is on, every time.

---

## The clock

The TUI runs at 130000x — the whole 90-day cycle in 60 seconds. That is right
for something you open, watch grow and close; in a bar it would mean a harvest
per minute and an icon blinking forever.

The **shipped default is `timeScale` 40**: a full cycle in ~57 hours of session,
or **about a week** of normal use. Opening the bar on Wednesday shows a
different plant from Monday's, which is the entire point of following a plant.

**The rhythm is yours, though, and it is saved:**

```sh
omarchy-shell ganja scale 400     # a cycle per working day
omarchy-shell ganja scale ""      # what is it now?
```

| cycle lasts | scale |
|---|---|
| 64 s | 130000 — this is turbo, and it says so in red |
| ~1.2 h of session | 2000 |
| ~5.8 h ≈ a working day | 400 |
| ~57 h ≈ a week (shipped default) | 40 |
| ~9 days of session | 10 |

Your choice wins over the manifest and lives in the save, so the plugin's
default stays what it is for everyone else: a plant you follow, not a plant you
watch. `timeScale` (the default), `turboScale` and `careScale` live in
`manifest.json`.

**Time only moves while the shell runs.** Machine off, plant paused. You come
back on Monday and it is where you left it on Friday, not dead of thirst. The
save's `last_tick` exists only to detect a newer save — never to advance the
clock.

Water and NPK drain at `careScale` (0.2) of the TUI's rate: a full pot lasts
about a day of session. They exist to give abandonment consequences, not to
become a daily chore.

---

## The cycle does not end

Harvested, another one is planted, automatically — ten days after it is ready,
like the TUI's `auto_harvest`, except here it is the behavior and not an option.
`h` harvests early.

What is not lost is the history. `Tab` opens it, and it is two things:

- **the running totals, which never expire** — how many harvests, grams in
  total, average quality and cannabinoids, your record harvest and your best
  quality (with the strain that did it), and the date of the first one;
- **the last 100 harvests in detail** — strain, day, weight, quality, THC/CBD
  and how many scares the plant took.

The file keeps 100 records because a save that grows forever is a leak with
another name. The totals are separate, six numbers updated at each harvest, and
that is what makes a fast rhythm safe: at turbo, the 100 records turn over in
under two hours, and none of what they added up to is lost. It is what separates
a pretty plant from something that accumulates — the tenth harvest has ten
stories behind it, and the hundredth still knows about the first.

---

## The save, and the TUI

Same fields as Ganja-TUI's serde serialization of `App` (`src/app.rs`), in the
plugin's own file. Moving a plant between the two is a file copy:

```sh
cp ~/.local/share/zed.ganja/save.json ~/.local/share/ganjatui/save.json
```

Every read and write goes through `save.py`, the one place in this plugin that
touches the disk, invoked as `/usr/bin/python3 -I save.py <mode> <paths>` with a
cleared environment. Paths arrive as **arguments** and are **relative to
`$HOME`** — the helper never accepts an absolute path.

What it guarantees, and how:

- **the path is descriptors, not a name.** Starting from a validated fd on
  `$HOME`, it walks one component at a time with `openat(O_DIRECTORY |
  O_NOFOLLOW)`. A symlink swapped in anywhere along the chain makes the open
  fail rather than follow. That fd is then held through the read, the write, the
  fsync, the rename and the cleanup, so nothing is re-resolved from the root
  afterwards;
- **no directory on that path may be writable by group or others.** Identity and
  ownership are not enough: whoever can write to a directory replaces the file
  inside it without owning anything, and the descriptor would then be the right
  fd of the right directory holding someone else's save. Every component is
  checked for the mode in the same `fstat` that checks the owner. The plugin's
  own state directory — the only one it creates — is tightened to 700 instead of
  refused, because refusing to read it would start the plant from zero and the
  next write would erase the good save;
- **the file is validated on the fd it will be read from** — `fstat` says
  regular file (which rules out FIFOs, sockets and devices), owned by us,
  exactly one link (so a hardlink to someone else's file is refused), and within
  a 1 MiB cap. There is no window between checking and using: it is the same
  descriptor;
- **the write publishes without re-resolving the parent.** The temp file is a
  random name created `O_CREAT | O_EXCL | O_NOFOLLOW` relative to that fd,
  mode 600; then `fsync`, then `renameat` on the *same* fd for both source and
  destination, then `fsync` of the directory;
- **bounded and deadlined:** 1 MiB on reads and writes, `SIGALRM` after five
  seconds, and `-I` so the interpreter ignores `PYTHON*`, user site-packages and
  the script's own directory;
- **a refusal is visible.** The helper's exit code and stderr are read on every
  launch: a refused write lights a red line in the room ("not saving to disk")
  until a write succeeds, and every refusal is logged. This exists because the
  checks above can refuse — a `~/.local/share` writable by others now stops the
  save, and a stop nobody is told about costs the plant in silence;
- **a closed environment, on every path there is.** All three `Process` objects
  use `clearEnvironment` with `PATH` and `HOME` and nothing else. There is no
  fourth path: the plugin makes no detached launches at all (see below), so
  nothing runs outside that rule.

That shape came out of the marketplace security review
([#6530](https://github.com/omacom/omarchy-plugin-marketplace/issues/6530)),
in two rounds. The first version interpolated paths into shell source and read
without limits — a huge file, or a FIFO in place of the save, could exhaust or
hang the process the whole bar lives in — and used a predictable
`save.json.$$.tmp` that a pre-positioned symlink could redirect. The second was
a hardened shell helper, and the reviewer was right to block it too: in shell
every command re-resolves the path, so `[ -f ]` followed by `head`/`mv` is two
resolutions with a window between them, and `sh` cannot reach `openat`,
`renameat` or `O_NOFOLLOW`. Python can. `make hostile` throws all of it back:
FIFO, symlink at the leaf, symlink mid-path, hardlink, oversized save, planted
temp file, a group- or world-writable directory mid-path, and a loose mode on
our own directory.

**This is why the plugin needs `python3`** — the only runtime dependency beyond
Omarchy itself, and one Omarchy's own scripts already have.

**There is no write on shutdown, and there used to be a line here claiming
otherwise.** `Component.onDestruction` built a snapshot and wrote it with a
detached launch — and it never ran. Measured two ways, with the save deleted
immediately before: process exit via `Qt.exit`, and `Quickshell.reload()`. The
file was not recreated in either. So the promise was false from the first day,
and the code was an execution path nobody could review or test — and the only
detached launch in the plugin, which the security review flagged for inheriting
the environment. It was removed rather than hardened.

What guarantees the save is what always actually guaranteed it: a write on every
user action, on each stage change, **when the room closes**, and at most every
ten minutes. The worst case after an abrupt shutdown is the minutes since the
last of those four.

Opening the overlay re-reads the save: if the one on disk is newer, it wins.
Last write wins, no locks — and that is also why there is no "reload" key: the
only case a key would cover is the file changing while the room is already open,
and closing and opening does the same thing.

**Careful, and this is behavior and not a bug:** opening `ganjatui` for a minute
with the save copied over burns a whole cycle of the plant. The TUI runs at
130000x and does not know its plant lives in a bar.

---

## Fidelity

The art is a port of `src/ascii/art.rs`, line by line, with the same magic
numbers — including the ones that look wrong (the foliage block only paints the
upper-left quadrant because it is left over from the 35×14 version of the art;
it is ported as-is, on purpose).

Two things needed care, and they are the part of this project that could have
gone silently wrong:

**The random number generator.** `SimpleRng` is a 64-bit LCG, and the QML JS
engine (V4, Qt 6.11) **has no BigInt** — not the `1n` literal, which is a syntax
error that takes down the whole file, nor the `BigInt()` function, which is a
`ReferenceError`. The 64-bit state is kept in four 16-bit limbs with the
multiplication done by hand. `Number` alone will not do: `lo * 1103515245`
exceeds 2^53 and silently loses low bits.

**Precision.** Rust computes in `f32` and JS in `f64`. Where the result becomes
an integer (`as u32`, `.ceil()`) or crosses a threshold (`> 0.5`), one bit
changes one character. Every step that was f32 there goes through `Math.fround`
here.

### What is verified, and what is not

```sh
make test      # everything
make check     # the LCG and 64-bit division against Node's BigInt
make diff      # today's output against the fixtures in test/frames/
make verify    # the fixtures against the QML JS engine
make state     # the real Grow.qml: stopping, language, what the save carries
make refused   # a refused write lights the warning instead of vanishing
make hostile   # FIFO, symlink, mid-path symlink, hardlink, loose modes, big save
make glyphs    # the eight bar icons against the installed font
```

- **Verified:** the hand-rolled 64-bit arithmetic matches `BigInt` over 14 seeds
  × 4000 steps; the QML engine reproduces the 64 reference frames character for
  character; the eight bar glyphs are the right drawings in the installed font;
  and the real `Grow.qml` passes 55 state checks, including that a binding
  calling `Grow.t()` re-evaluates when the language changes — without that the
  screen would sit in two languages and nothing would show up in the log.
- **Verified (14/09/2026):** the `diff` against the **actual Ganja-TUI**. The Rust
  side now ships `examples/dump_frames.rs`, which dumps
  `get_plant_ascii(stage, day, seed, 0)` for the same 8 seeds and 8 days into the
  format of `test/frames/`. All **64 of 64 frames are identical, character for
  character**. Fidelity is no longer declared: it is diffed against the reference
  implementation. See `test/README.md`.

The QML tests run on a temporary copy of the plugin folder with a temporary
`$HOME` (`test/stage.sh`): a test that ran against the real `$HOME` would write
to the tester's own plant, and symlinks — the other way to give a test file
access to the singleton — are refused by `omarchy plugin validate`.

---

## Cost

| state | cost |
|---|---|
| shell loaded, overlay closed | 1 timer at 60 s, pure arithmetic, 0 IO |
| **stopped** (`p`, or right click) | **nothing**: no timer, no animation, no IO |
| overlay open | 10 frames/s: 70×28 cells plus the animation |
| overlay open and stopped | one repaint per action, and nothing else |
| user action | 1 atomic JSON write |
| shell boot | 1 `cat` of the save |
| every 10 min, when the stage turns, or when the room closes | 1 atomic JSON write |

Measured with the overlay open: 22–40% of one core at 10 frames per second, or
~30 ms of CPU per frame. That is expensive by an order of magnitude for drawing
70×28 characters, and the cause is known — the character matrix is regenerated
every frame when all that changes between frames is the trunk character, the
color and the breathing. Caching it is the pending optimization; the 64-frame
fidelity test is what guarantees the optimization does not change the plant.

Closed — which is how it spends most of its life — the overlay costs nothing at
all, and now `p` takes the other half to zero too.

---

## Files

```
manifest.json    schemaVersion 1, kinds bar-widget + overlay, timeScale, careScale
qmldir           singleton Grow + Room (once a qmldir exists, it is the list)
Grow.qml         state, save, clock, simulation  (the half that stays awake)
BarWidget.qml    the glyph, the alert, the tooltip
Ganja.qml        the windows, the keys, the IPC
Room.qml         what you see inside, identical in both windows
Art.js           port of ascii/art.rs - SimpleRng, PlantStructure, render
Palette.js       port of ui/colors.rs - the four palettes
I18n.js          every screen string, in both languages, plus the strain vocabulary
save.py          the only code that touches the disk - fd-pinned, bounded, atomic
Strains.js       generated from strains.json by `make strains`
test/            frame fixtures, the Node harness, the QML ones, the state one
SPEC.md          the decisions and why they are what they are (Portuguese)
PUBLISHING.md    what publishing to the marketplace requires
```

`Strains.js` is generated, not hand-edited:

```sh
make strains GANJA_TUI=~/Projetos/Ganja-TUI
```

---

MIT, like Ganja-TUI. The plant is ZeD's; the bar is Omarchy's.
