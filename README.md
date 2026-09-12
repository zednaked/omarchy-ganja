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

**Requirements:** Omarchy with `omarchy-shell` (plugin schemaVersion 1) and a
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
omarchy-shell ganja lang en         # or pt, or empty to toggle
omarchy-shell ganja window medium   # or empty to cycle
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

**This is persisted**, unlike turbo and demo. Those two turn themselves off,
because left running they burn through the plant with nobody watching; stopping
is the opposite — it spends nothing and loses nothing, and whoever switched the
clock off wants to find it off tomorrow. Turning on either fast mode restarts
the clock first, because 130000x behind a stopped clock would do nothing at all,
and "nothing happened" reads as a broken feature.

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

## The clock

The TUI runs at 130000x — the whole 90-day cycle in 60 seconds. That is right
for something you open, watch grow and close; in a bar it would mean a harvest
per minute and an icon blinking forever.

Here the default is **`timeScale` 40**: a full cycle in ~54 hours of session, or
**about a week** of normal use. Opening the bar on Wednesday shows a different
plant from Monday's, which is the entire point of following a plant.

| cycle lasts | `timeScale` |
|---|---|
| 60 s (the TUI) | 130000 |
| 1 day of session | 90 |
| ~1 week of use (default) | 40 |
| ~1 month of use | 10 |

`timeScale`, `turboScale` and `careScale` live in `manifest.json`.

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

What is not lost is the history. `Tab` opens the list: strain, day, weight,
quality, THC/CBD and how many scares the plant took. It is what separates a
pretty plant from something that accumulates — the tenth harvest has ten
stories behind it. The file keeps the last 100.

---

## The save, and the TUI

Same fields as Ganja-TUI's serde serialization of `App` (`src/app.rs`), in the
plugin's own file. Moving a plant between the two is a file copy:

```sh
cp ~/.local/share/zed.ganja/save.json ~/.local/share/ganjatui/save.json
```

Writes are always atomic (`.tmp` in the same directory, then `mv`), and the
`.tmp` carries the PID so two shell instances cannot stitch two JSONs into one
file. Opening the overlay re-reads the save: if the one on disk is newer, it
wins. Last write wins, no locks — and that is also why there is no "reload" key:
the only case a key would cover is the file changing while the room is already
open, and closing and opening does the same thing.

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
make glyphs    # the eight bar icons against the installed font
```

- **Verified:** the hand-rolled 64-bit arithmetic matches `BigInt` over 14 seeds
  × 4000 steps; the QML engine reproduces the 64 reference frames character for
  character; the eight bar glyphs are the right drawings in the installed font;
  and the real `Grow.qml` passes 28 state checks, including that a binding
  calling `Grow.t()` re-evaluates when the language changes — without that the
  screen would sit in two languages and nothing would show up in the log.
- **Not verified:** the `diff` against the **actual Ganja-TUI**. That needs a
  machine with `cargo`, running the TUI with the same 8 seeds and 8 days and
  comparing against `test/frames/`. Until that happens, fidelity here is
  **declared, not proven**. See `test/README.md`.

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
| every 10 min, or when the stage turns | 1 atomic JSON write |

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
