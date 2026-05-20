# CLAUDE.md — NextDS for Liferay

Project context for AI assistants working on this Liferay site initializer.

## What this project is

A Liferay site initializer plus `themeCSS` client extension that implements
the [SERPRO / Estaleiro Next Design System](https://next-ds.estaleiro.serpro.gov.br/)
(built on `gov.br/ds`) inside a Liferay DXP site. Targets `dxp-2024.q4.0` /
`7.4.13`. The single source of truth lives under `site-initializer/` — edit
there; the build copies it verbatim into an OSGi JAR.

Build / deploy / validation steps are documented in `README.md`.

## Source of truth and what the build does

- `site-initializer/` is copied 1:1 into the JAR (with `META-INF/` as a
  sibling so the thumbnail is served from the bundle context).
- `client-extensions/nextds-theme/` is packaged manually into a deploy-ready
  ZIP that includes the wrapper config Liferay reads at boot
  (`*.client-extension-config.json`, `WEB-INF/liferay-plugin-package.properties`,
  `Dockerfile`, `LCP.json`, `static/index.css`). A bare `zip -r src/` is
  **not enough** — the wrapper files are mandatory for the CX to register.
- `tokens.css` in the repo root is the OFFICIAL Next-DS / gov.br token
  catalogue, kept here for reference. Its content is embedded verbatim into
  `client-extensions/nextds-theme/src/index.css` as Layer 1 primitives.

## Pages / master page

- Master page is `Main` (auto-key `main`) — header + DropZone + footer.
- The master uses the **dynamic** header (`nextds-site-header-dynamic`)
  which embeds `<lfr-widget-nav>` so the menu reflects the actual Liferay
  page tree. The static `nextds-site-header` is kept as an alternative for
  pages that need a hard-coded nav.
- Page-definition `settings.masterPage.key` must match the auto-derived
  master key — `"Main"` → `"main"`.
- Pages live under `site-initializer/layouts/` and use a numeric prefix
  (`1_home`, …) to control nav ordering.

## Tokens

Three-layer architecture (validated by `scripts/validate.sh`):

- **Layer 1 — Primitives** (private to the theme). Full official tokens.css
  embedded verbatim: `--blue-warm-vivid-70`, `--gold-vivid-40`,
  `--color-primary-default`, `--color-secondary-01..09`, `--color-highlight`,
  `--success`, `--danger`, `--surface-width-*`, `--surface-rounder-*`,
  `--spacing-scale-*`, `--font-size-scale-*`, `--focus-color`, etc.
- **Layer 2 — Semantics** (public to fragments). `--color-bg`, `--color-text`,
  `--color-link`, `--color-brand`, `--color-border`, `--space-s/m/l/xl`,
  `--nextds-max-width`, `--nextds-radius`, `--nextds-radius-pill`,
  `--nextds-font-family-base`, `--nextds-focus-color`, etc.
- **Layer 3 — gov.br dot-notation aliases**. `--br-color-primary-default`,
  `--br-form-border-width-default`, `--br-focus-color`, `--br-spacing-half`,
  etc. — so downstream gov.br snippets paste in cleanly.

Fragments **must not** reference primitive `--blue-*`, `--gray-*`, `--color-primary-darken-*`
etc. (Layer 1) directly. The validator scans `site-initializer/fragments/**`
and fails the build on any direct primitive reference; consume Layer 2 / 3
aliases instead.

## Focus signature

Next-DS uses a **dashed, gold, high-contrast** outline — distinct from a W3C
yellow-background swap. Defined in `client-extensions/nextds-theme/src/index.css`:

- `--focus-color`  = `var(--gold-vivid-40)` = `#c2850c`
- `--focus-style`  = `dashed`
- `--focus-width`  = `var(--surface-width-lg)` = `4px`
- `--focus-offset` = `var(--spacing-scale-half)` = `4px`

Interactive controls (button, link, tab, input, summary, hamburger trigger,
search trigger) all use this signature. The dashed pattern is the canonical
Next-DS focus marker — do not swap it for a solid outline or background.

## Header pattern

The site header is icon-only:

- **Hamburger** — round icon button, no visible "Menu" label. Tooltip via
  Liferay's Clay pattern: `data-title="Menu" data-tooltip-align="bottom"`.
  Lines morph into an X on `aria-expanded="true"`.
- **Search trigger** — round icon button. Clicking it opens a **floating
  blue overlay** absolutely positioned below the bar with a white pill input.
- **Account** — sign in / sign out anchor with user icon. In the dynamic
  header, it inspects `themeDisplay.isSignedIn()` and swaps URL accordingly.

The menu drawer and search overlay both float (`position: absolute; top: 100%;
z-index >= 50; box-shadow: lg`) — they do NOT push page content down. JS
coordinates them so opening one closes the other; Escape and click-outside
also dismiss.

### Liferay React SearchBar — CSS flattening

The dynamic header wraps `<lfr-widget-search-bar>` in a white pill. Liferay's
React `ReactSearchBar` mounts a tree of wrappers (`.portlet`, `.portlet-body`,
`.form-group-autofit`, `.form-group-item`, …) around the actual `<input>` and
`<button>`. Out of the box the input shrink-wraps to the placeholder text and
the submit button lands in the middle of the pill.

The fix lives in `nextds-site-header-dynamic/index.css`: every Liferay /
Clay wrapper between the pill and the real `<input>`/`<button>` gets
`display: contents !important` (also stripped of background/border/padding).
That removes the wrappers from the box tree so the input and button become
effective flex children of the pill. The input then gets `flex: 1 1 auto;
order: 1`; the button gets `flex: 0 0 auto; order: 2; margin-left: auto` so
it pins to the right edge.

Do **not** use `position: absolute` on the submit button — Liferay's React
component rebuilds the DOM on hydration and the offset parent isn't reliable.

## EU / brand assets

- `site-initializer/fragments/group/nextds/resources/logo-nextds.svg` — primary
  brand mark (for white surfaces). Used in the header.
- `site-initializer/fragments/group/nextds/resources/logo-nextds-dark.svg` —
  inverted variant for dark surfaces. Used in the footer.
- `bg-hero-diretrizes.png` — official Next-DS hero background, downloaded
  from `next-ds.estaleiro.serpro.gov.br/static/media/`.

Reference resources from fragment HTML with `[resources:<name>]` — never inline
or import from outside `resources/`.

## Style Book preview workaround — duplicated utility classes

Liferay's Style Book → fragment preview iframe loads only the fragment's own
`index.css`. The theme client-extension stylesheet is **not** injected into
that preview, so a fragment that relies on theme-level helpers renders
unstyled in the editor preview.

To keep the preview readable, the affected fragments duplicate the small
subset of utility classes they need at the top of their own `index.css`,
fenced by:

```css
/* === preview-workaround: duplicated from theme === */
.nextds-container { … }
.nextds-clean-list { … }
.nextds-sr-only { … }
/* === end preview-workaround === */
```

Affected fragments today include `nextds-site-header`, `nextds-site-header-dynamic`,
`nextds-site-footer`, `nextds-hero`, `nextds-card`, `nextds-tile`,
`nextds-content-block`, `nextds-styles-showcase`, `nextds-components-showcase`,
and the form fragments.

**Remove the duplication once Liferay loads theme CSS into the Style Book
preview iframe.** Until then, every new fragment that relies on theme utility
classes should duplicate the minimum it needs at the top of its `index.css`
between the preview-workaround markers.

## Liferay 7.4.13 / 2024.Q4 gotchas

- Fragment FreeMarker uses **bracket** syntax: `[#if]…[/#if]`. AntiSamy
  filters `<#if>` silently. Avoid `[#elseif]` — use multiple `[#if]` blocks
  with `[#assign]` instead.
- Checkbox config fields: **no `dataType`**; `defaultValue` is the *string*
  `"true"`/`"false"`. Anything else and the field becomes inert.
- Style books always use `"themeId": "classic_WAR_classictheme"` — there is
  no themeId for a CX bundle symbolic name.
- The site initializer thumbnail must live at **both**
  `site-initializer/thumbnail.png` (for the initializer engine) and
  `META-INF/resources/thumbnail.png` (for the *Select Template* tile).
- `fragment.json` references `"configurationPath": "configuration.json"`
  (not `index.json`) by convention in this workspace.
- `Row` page-element `definition` must include the boolean `"gutters"` —
  otherwise `RowLayoutStructureItemImporter` throws a NullPointerException
  on `Map.get("gutters")` and the site creation transaction rolls back with
  a generic *"An unexpected error occurred"*.
- `page-definition.json` must **not** contain `"siteKey"` anywhere — the
  workspace plugin rejects it for 7.4.13.
- Locale keys use the underscore form: `"en_US"`, not `"en-US"`.

### Anchor vs button text-decoration

Liferay's Classic theme applies `a { text-decoration: underline }` globally.
When a button fragment renders as `<a class="nextds-button …">`, the bare
`.nextds-button { text-decoration: none }` rule loses to `.nextds-button--secondary:link`
(equal specificity, source order) which inherits the underline. Buttons in
Next-DS **never** underline, regardless of variant. Always declare
`text-decoration: none` for every state in the fragment CSS, AND add a guard
in the theme:

```css
a.nextds-button,
a.nextds-button:link, a.nextds-button:visited,
a.nextds-button:hover, a.nextds-button:focus, a.nextds-button:active {
  text-decoration: none;
}
```

## Common edits

### Add a new fragment

1. Create `site-initializer/fragments/group/nextds/fragments/nextds-<name>/`
   with `fragment.json`, `configuration.json`, `index.html`, `index.css`,
   `index.js`.
2. `fragment.json` shape:
   ```json
   {
     "configurationPath": "configuration.json",
     "cssPath": "index.css",
     "htmlPath": "index.html",
     "jsPath": "index.js",
     "name": "<Display name>",
     "type": "component"
   }
   ```
3. Use semantic tokens only (Layer 2 / Layer 3) — never Layer 1 primitives.
4. If your fragment relies on theme utility classes, duplicate them at the
   top of `index.css` between the preview-workaround markers.
5. Use **inline `<svg>`** for icons (not `<img src="[resources:...svg]">`
   for stroke-based icons) — `currentColor` does not resolve inside an SVG
   loaded via `<img>` in most browsers, so the icon would render without
   colour. Inline SVG is the safe default.
6. Run the validator: `LIFERAY_VERSION=7.4.13 bash scripts/validate.sh .`.

### Add a new page

1. Create `site-initializer/layouts/<key>/` with `page.json` and
   `page-definition.json`.
2. `page.json` keys: `externalReferenceCode`, `friendlyURL`, `hidden`,
   `name_i18n`, `private`, `system: false`, `type: "Content"`.
3. `page-definition.json` must include
   `"settings": {"masterPage": {"key": "main"}}` to inherit the chrome.
4. Every `Row` element must declare `"gutters": true|false`.
5. Re-run the validator.

### Import a page from a working site

```bash
curl -u 'test@liferay.com:test' \
  "http://<host>/o/headless-delivery/v1.0/sites/<siteId>/site-pages/<friendlyUrl>?nestedFields=pageDefinition" \
  -o /tmp/page.json
```

Run the imported `pageDefinition.pageElement` through a sanitiser that:
- strips every `siteKey` (forbidden in 7.4.13 page-defs),
- ensures every `Row` has `"gutters": true`,
- drops auto-generated UUID `id` fields.

Then write to `site-initializer/layouts/<key>/page-definition.json` wrapped as:
```json
{
  "settings": {"masterPage": {"key": "main"}},
  "pageElement": { ... }
}
```

## Deploy lifecycle

- Site initializer changes apply to **newly created sites** only. Existing
  sites keep the fragments that were copied at creation time — delete and
  recreate to pick up structural fragment changes.
- Theme client-extension changes are live on bundle restart and reflect
  immediately on every site that has the **NextDS Theme** CSS Client
  Extension selected under *Site Settings → Look and Feel*. Use the theme
  to hot-fix token-driven look-and-feel (anchor underline guards, focus
  colour, palette tweaks) without recreating the site.

## Git / commits

Commits in this repo are **plain** — no `Co-Authored-By:` trailer, no
generator footer. The author is the person making the change.
