# Handoff spec: landing page, "Annunciator" (direction D)

> Chosen 2026-10-20 from four directions on the **giglab.dev Landing Page**
> canvas (Claude Design). The source of truth for the look is the
> **giglab.dev Design System** artifact; `docs/design/tokens.json` is a copy of
> its tokens taken the same day. `docs/design/reference/Annunciator.dc.html`
> is the canvas artboard's source. Read it for structure, but rebuild it as
> Astro components: never ship that file.

## Overview

The first public page of giglab.dev, live before the board, `/status` and the
write-ups exist. It presents every project as a tile on an **annunciator
panel**: a tile is **lit** when the project is under way and **dark** when it
is only charted. Pressing a tile shows that project's readout. The page's job
is to say "this is what's coming" and to look like nothing else.

**What it is not:** an imitation of any franchise interface. The shapes are
square-cut blocks and tiles (radius 2px). The lettering is Gentium and Plex
Mono. Keep it that way.

## Layout

The whole page is a column of full-width rows, `space-2` (8px) apart, inside a
`space-4` (16px) page inset on `void`. There is no max-width: the panel fills
the window, as a control panel does. Every row is a wrapping flex row, so
nothing needs a hard breakpoint (see Responsive).

| # | Row | Contents |
|---|---|---|
| 1 | **Header** | The **name slab** (`signal` fill, grows, `flex: 999 1 560px`, min-height 220px), and beside it the **counter block** (`flex: 1 1 280px`): a 2-column grid holding *IN FLIGHT* (`beacon` fill), *ON THE BOARD* (`ink` fill) and a tagline cell spanning both columns |
| 2 | **Nav** | Four equal block links (`flex: 1 1 160px`, min-height 48px): `01 · BOARD`, `02 · STATUS`, `03 · WRITE-UPS`, `04 · GITHUB ↗` |
| 3 | **Main** | The **board** (`flex: 999 1 640px`) and the **readout** panel (`flex: 1 1 320px`) side by side |
| 4 | **Fleet ribbon** | A `FLEET` label block (`ink` fill), one cell per host, and a dashed `/STATUS COMES ONLINE NEXT` cell |
| 5 | **Footer** | Two mono lines, `muted`: credit and stack |

## Design tokens used

All colours come from tokens; both themes (`dark` first, `light`) are defined
in `tokens.json`. Never write a hex value in a component.

| Token | Used for |
|---|---|
| `void` | Page ground; text on the `ink` blocks |
| `hull` | Board background; fleet host cells |
| `panel` | Dark (charted) tiles; nav blocks; readout panel; tagline cell |
| `hairline` | Board edge, host-cell edges, readout `<dl>` rule |
| `muted` | Nav-block and readout borders, dark-tile border, secondary text, dashed cell |
| `ink` | Primary text; `ON THE BOARD` and `FLEET` fills; selected-tile ring |
| `signal` | Name slab; **PAUSED** tiles; tagline text; links |
| `on-signal` | All text on `signal` or `beacon` fills |
| `beacon` | IN FLIGHT counter; **IN FLIGHT** tiles; live readout values; focus ring |
| `ok` | DOCKED / shipped tiles (none yet; same treatment as `beacon` tiles) |
| `space-2` 8px · `space-4` 16px · `space-6` 24px | Row gaps and tile gaps · panel padding · readout padding |
| `radius-sm` 2px | **Everything** on this page (slab, blocks, tiles, panels). No `radius-md`, no pills. |

| Type style | Where |
|---|---|
| `display` (Gentium Book Plus 700) at **112px / 0.9**, `letter-spacing: -0.02em` | The name in the slab (see Responsive for its clamp) |
| `heading-2` (Gentium Book Plus 700) 22px/26px | Tile names |
| Gentium Book Plus 700, 40px/44px | Readout project name |
| `accent` (Gentium Book Plus Italic 400) 22px/30px | Tagline cell |
| `body` (Gentium Plus 400) 18px/28px | Readout blurb |
| `body-italic` 15px/22px | The readout's closing note |
| `label` (Plex Mono 600, 11px, 0.12em, uppercase) | Slab kicker, counter labels, nav, tile codes, status words, section labels |
| Plex Mono 600 at 40px | Counter numbers (zero-padded, two digits) |
| `readout` (Plex Mono 500) 13–14px | Host names, `<dl>` values |

Fonts load from Google Fonts: Gentium Book Plus (700, 400 italic), Gentium
Plus (400, 400 italic, 700) and IBM Plex Mono (500, 600). Self-host them in the
Nix build if you want no third-party requests (they are SIL OFL).

## Components

| Component | Props | Notes |
|---|---|---|
| `NameSlab` | `kicker` | Kicker text: `ANNUNCIATOR · PANEL 01 · FIRST LIGHT` |
| `Counter` | `label`, `value`, `fill` (`beacon` or `ink`) | `value` is computed at build from the registry, zero-padded to two digits |
| `NavBlock` | `href`, `index`, `label`, `external?` | `external` appends ` ↗` and keeps the same look |
| `Tile` | `project`, `selected` | A real `<button type="button">` (with JS) or `<a href="#readout-<slug>">` (without JS). See States |
| `Readout` | `project` | Code, name, blurb, status line, a `<dl>` of live readings, closing note |
| `HostCell` | `name`, `state` | `state` is `awaiting` until `/status` exists |

### Tile anatomy (top to bottom, `space-between`, min-height 148px, padding `space-4`)

1. **Code**, `label` style: a two-letter code plus a two-digit ordinal (`GP-01`). It comes from the registry's `code` field, never generated from the name.
2. **Name**, `heading-2`.
3. **Status**: glyph, space, then the word (`◆ IN FLIGHT`), `label` style.

| Status | Glyph · word | Fill | Text | Border |
|---|---|---|---|---|
| active | ◆ IN FLIGHT | `beacon` | `on-signal` | `beacon` |
| paused | ▲ PAUSED | `signal` | `on-signal` | `signal` |
| shipped | ● DOCKED | `ok` | `on-signal` | `ok` |
| planned / idea | ○ CHARTED | `panel` (dark) | `ink` | `muted` |

Board grid: `repeat(auto-fill, minmax(200px, 1fr))`, gap `space-2`. Tiles are
ordered as in the registry (curated, not alphabetical).

## States and interactions

| Element | State | Behaviour |
|---|---|---|
| Tile | Default | As in the table above |
| Tile | Hover | `cursor: pointer`; border becomes `ink` (lit and dark alike). No colour shift on the fill. |
| Tile | Focus-visible | 3px `beacon` outline, 3px offset |
| Tile | Selected | 3px `ink` outline, 3px offset, plus `aria-pressed="true"` (others `false`). Exactly one tile is selected; the first is on load. |
| Tile | Press | Selects the tile and swaps the readout's contents. No navigation, no page reload. |
| Nav block | Hover | Border becomes `signal`, text stays `ink` |
| Nav block | Focus-visible | As tiles |
| Links (`a`) | Default / hover | `signal` / `ink` |
| Readout `<dl>` values | Before live data | The literal text `—` in `beacon`, with the note "Live readings arrive when the board comes online." (The canvas shows `[live]` as a placeholder; ship `—`.) |
| Host cell | Awaiting | `○ AWAITING SIGNAL` in `muted`. When `/status` lands, it shows the host's status word, glyph and colour per the design system's status table. |

**Without JavaScript** (a ground rule in AGENTS.md): every project's readout is
rendered into the page, each as `<section id="readout-<slug>">`. Tiles are
`<a href="#readout-<slug>">`, styled identically. With JS, a small island
replaces the anchors with buttons, hides all readouts but the selected one, and
wires `aria-pressed`. The page must read correctly in both modes.

## Responsive behaviour

No hard breakpoints: the wrapping flex rows and `auto-fill` grid do the work.
The resulting widths:

| Width | What happens |
|---|---|
| ≥ ~1000px | Header slab and counters side by side; board and readout side by side; nav in one row |
| ~700–1000px | Counter block wraps under the slab; readout wraps under the board; nav may go to two rows |
| < ~700px (phone) | Everything stacks. Nav is 2×2 or 1×4. Tiles take one or two columns. |

- **Name size:** `font-size: clamp(56px, 11vw, 112px)`. "giglab.dev" must never wrap or clip at 320px wide.
- **Phone readout:** when the readout is below the board (it wrapped), pressing
  a tile scrolls the readout into view (`scrollIntoView({block: "start"})`,
  smooth only when `prefers-reduced-motion: no-preference`). It does not move
  focus.
- Touch targets: tiles ≥148px tall, nav blocks ≥48px.

## Edge cases

- **Long project names:** they wrap inside the tile, which may grow taller (no
  truncation). Use `overflow-wrap: anywhere` so a long single word cannot
  overflow a 200px tile.
- **Blurb length:** at most 90 characters, enforced by the registry schema at
  build time.
- **Many projects:** the grid just grows; no paging. Counters stay two digits
  until 99.
- **No projects** (an empty registry): the board shows one dashed cell,
  `○ NOTHING CHARTED YET`, and both counters read `00`. The build must not
  fail.
- **Private repos:** the tile shows only curated registry text, and its
  readout's live readings are always `—`. Never fetch them (ground rule).
- **Theme:** follow `prefers-color-scheme`, defaulting to `dark`. Set
  `data-theme` on `<html>`. A manual toggle is out of scope for this page.

## Motion

None. Tiles do not animate, nothing fades, and there are no scanlines or
glows. The scroll on a phone is the only movement, and it honours
`prefers-reduced-motion`.

## Accessibility

- **Landmarks:** `header`, `nav aria-label="Primary"`, `main`, `footer`. The
  board and readout are `<section>`s with headings; the board's heading is
  the `label`-style line "THE BOARD · PRESS A TILE FOR ITS READOUT".
- **Heading order:** `h1` is the name in the slab; `h2` for board, readout and
  fleet; tile names are not headings (they live inside buttons).
- **Focus order:** nav blocks, then tiles in grid order, then the readout,
  then the fleet ribbon.
- **Readout:** `aria-live="polite"` on the readout container, so a tile press
  announces the new project.
- **Status is never colour alone:** every tile and host carries a glyph and a
  word.
- **Contrast** (checked against tokens): `on-signal` on `signal` 10.6:1 dark /
  5.7:1 light; `on-signal` on `beacon` at least 6:1 in both themes; `muted` on
  `panel` at least 6.6:1. The `hairline` token is decorative only (1.4:1), so
  it is never the only edge of a tile or nav block: those use `muted`.

## Content (first light)

Replace with the real registry. These are the canvas's curated guesses, for
Lord Gig to correct:

| Code | Project | Blurb | Status |
|---|---|---|---|
| GP-01 | gigpkgs | A Nix package set, and inputMan to feed it. | active |
| RF-02 | roll-flow | A gated branch workflow, as a Rust TUI. | active |
| GV-03 | gigvim | Neovim, configured through nvf. | active |
| SC-04 | ScribbyDaScribe | Discord voice calls into per-speaker transcripts. | active |
| GL-05 | giglab.dev | This board, served from a container on spacedock. | active |
| PA-06 | Playarr | One house for the media stack. | paused |
| RZ-07 | A rasterizer from scratch | Rust, a CPU, and first principles. | planned |

Fixed copy: tagline "Projects in flight, the fleet on watch." · footer
"giglab.dev · Maxwell Rupp · served from spacedock" / "Nix · Astro · Rust ·
Typst".
