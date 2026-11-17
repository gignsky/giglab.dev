# Backlink Campaign -- Homeward Banners to giglab.dev

**Goal.** Every website in Lord Gig's dominion flies a single, consistent
link home to <https://giglab.dev>, so the Realm's sites form one acknowledged
constellation and giglab.dev gathers the inbound links that prove it the hub.

This is a plan, not yet a deed. Work each site in the rollout order below; tick
its row when the banner is live and verified.

## The banner (one spec, every site)

A discreet footer credit, not a nav item. Canonical markup:

```html
<a class="realm-backlink" href="https://giglab.dev"
   rel="noopener" title="Part of Lord Gig's Realm">
  Built in the Realm &middot; giglab.dev
</a>
```

Rules:

- **Dofollow.** No `rel="nofollow"` -- these links are meant to pass weight to
  the hub. `rel="noopener"` only.
- **Footer, every page.** Place it in each site's shared footer component so it
  appears site-wide, never page-by-page.
- **Each site keeps its own skin.** The banner inherits the host site's footer
  styling; it does **not** import giglab.dev's tokens. One line, muted, legible.
- **Exact href** `https://giglab.dev` (apex, https, no trailing path) so every
  inbound link counts as one target.
- Wording may shorten to `giglab.dev` alone on space-starved footers; the href
  and `title` stay as specified.

## The fleet

| Site | Purpose | Stack / host | Where the banner goes | Status |
|---|---|---|---|---|
| **avecmoi.app** | "Ask an Appraiser" realtor presentations | *stack TBC* | shared footer / template once confirmed | [ ] |
| **christinasceramics.com** | Christina's Ceramics | Astro frontend | `Footer.astro` (shared layout) | [ ] |
| **Kottonmouth** *(domain TBD)* | band site | Astro static on Cloudflare Pages | shared Astro footer; static site only -- skip spacedock interactive layer | [ ] |
| **cashconsults.com** | CashDesk remote support | static site on Cloudflare (wrangler) | `site/` shared footer partial | [ ] |
| **The Listing Lady** | realtor client site | WordPress (MCP-managed) | footer widget / block, or theme `footer.php` | [ ] |

*(Add new builds to this table as they land. giglab.dev itself is the
destination and carries no self-link.)*

## Rollout order

1. **Own sites first** -- avecmoi.app, then Kottonmouth, so the pattern is
   proven on builds fully under your hand before client sites.
2. **christinasceramics.com and cashconsults.com** -- Astro/Cloudflare, same
   footer-component change; batch them.
3. **The Listing Lady** -- WordPress, a different mechanism (widget/block or
   `footer.php`); do last and verify separately.

## Per-stack recipe

- **Astro sites** (Christina, Kottonmouth): add the anchor to the shared
  `Footer.astro`; one edit covers every page. `npm run build`, confirm it
  renders site-wide.
- **Cloudflare static** (cashconsults, Kottonmouth Pages): same footer edit in
  `site/`; verify the deployed `dist/` carries it.
- **WordPress** (The Listing Lady): prefer a footer **widget/block** over
  editing the theme, so a theme update cannot wipe it. If the theme has no
  footer widget area, add to a child theme's `footer.php` -- never the parent.

## Verification (per site, close the row only after)

1. Banner visible in the rendered footer of the live site, every page type
   (home + one interior).
2. Link resolves to `https://giglab.dev` (200, no redirect chain).
3. No `nofollow` on the rendered anchor.
4. *(optional, later)* once giglab.dev's Phase 2 server lands, cross-check
   inbound links against this table so none silently dropped.

---
*#FERREN -- plan drafted; awaiting Lord G.'s order to execute site by site.*
