# Projects registry

One JSON file per project, filename = slug. This is a **provisional** format:
`docs/ARCHITECTURE.md` §7 open item 5 ("Registry format") is still unresolved
— Typst metadata in `.typ`, or TOML beside each `.typ` — and no Typst
write-ups exist yet. This JSON shape carries only the fields the landing page
needs and is expected to be superseded once that item is ruled on.

| Field | Meaning |
|---|---|
| `code` | Two-letter prefix + two-digit ordinal, e.g. `GP-01`. Fixes board order. |
| `title`, `summary` | Identity. `summary` is at most 90 characters (enforced by the site's content schema). |
| `status` | `idea · planned · active · paused · shipped · archived`. Curated — see AGENTS.md ground rules. `archived` entries are left off the board. |
| `repo` | e.g. `gignsky/gigpkgs`. Optional. |
| `visibility` | `public` or `private`. Private repos show only this curated text; their readout never shows live data. |
