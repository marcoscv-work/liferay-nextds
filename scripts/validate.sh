#!/usr/bin/env bash
# DS site initializer strict validator. Returns 0 on pass, nonzero on fail.
# Usage:
#   LIFERAY_VERSION=7.4.13 bash validate.sh /path/to/workspace
#   LIFERAY_VERSION=2024.Q2 bash validate.sh /path/to/workspace
set -uo pipefail

ROOT="${1:-.}"
VERSION="${LIFERAY_VERSION:-7.4.13}"
ERR=0
WARN=0

red()    { printf '\033[31m%s\033[0m\n' "$*"; }
green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
fail()   { red    "  FAIL: $*"; ERR=$((ERR+1)); }
warn()   { yellow "  WARN: $*"; WARN=$((WARN+1)); }
pass()   { green  "  OK:   $*"; }
section(){ printf '\n\033[1m== %s ==\033[0m\n' "$*"; }

command -v jq >/dev/null || { red "jq is required"; exit 2; }

SI="$ROOT/site-initializer"
[[ -d "$SI" ]] || { red "Not a workspace: $SI not found"; exit 2; }

section "FreeMarker syntax (bracket vs angle)"
if grep -rEn '<#(if|assign|list|else|elseif|return|local|global)\b' "$SI/fragments" 2>/dev/null; then
  fail "Found <#...> FreeMarker tags — must use bracket [#...] in 7.4.13"
else
  pass "All FreeMarker uses bracket syntax"
fi
if grep -rn '\[#elseif' "$SI/fragments" 2>/dev/null; then
  fail "[#elseif] used — not supported in 7.4.13; use multiple [#if] blocks"
fi

section "Fragment configuration fields"
CFG_FILES=$(find "$SI/fragments" \( -name 'configuration.json' -o -name 'index.json' \) 2>/dev/null)
for f in $CFG_FILES; do
  jq -e . "$f" >/dev/null 2>&1 || { fail "$f is not valid JSON"; continue; }
  BAD=$(jq -r '[.fieldSets[]?.fields[]? | select(.type=="checkbox") | select(has("dataType"))] | length' "$f")
  [[ "$BAD" == "0" ]] || fail "$f: $BAD checkbox field(s) have dataType (must be absent)"
  BAD=$(jq -r '[.fieldSets[]?.fields[]? | select(.type=="checkbox") | select(.defaultValue|type != "string")] | length' "$f")
  [[ "$BAD" == "0" ]] || fail "$f: $BAD checkbox field(s) have non-string defaultValue (use \"true\"/\"false\")"
done
[[ -n "$CFG_FILES" ]] && pass "Checkbox fields are well-formed"

section "fragment.json shape"
for f in $(find "$SI/fragments" -name 'fragment.json' 2>/dev/null); do
  jq -e . "$f" >/dev/null 2>&1 || { fail "$f is not valid JSON"; continue; }
  CFG=$(jq -r '.configurationPath // empty' "$f")
  [[ -z "$CFG" ]] && warn "$f: no configurationPath"
  if [[ -n "$CFG" ]]; then
    DIR=$(dirname "$f")
    [[ -f "$DIR/$CFG" ]] || fail "$f: configurationPath '$CFG' points to missing file"
  fi
done

section "page-definition.json — siteKey forbidden in 7.4.13"
if [[ "$VERSION" == 7.4.13* ]]; then
  if grep -rln '"siteKey"' "$SI/layouts" "$SI/layout-page-templates" 2>/dev/null; then
    fail "siteKey found in page-definitions — must be removed for 7.4.13"
  else
    pass "No siteKey in page-definitions"
  fi
fi

section "Locale keys"
if grep -rEn '"[a-z]{2}-[A-Z]{2}"' "$SI" 2>/dev/null; then
  fail "Locale keys with hyphens found — Liferay expects underscores (en_US, es_ES)"
else
  pass "All locale keys use underscore form"
fi

section "Style books"
SB_DIR="$SI/style-books"
if [[ -d "$SB_DIR" ]]; then
  DEFAULTS=0
  for f in $(find "$SB_DIR" -name 'style-book.json' 2>/dev/null); do
    jq -e . "$f" >/dev/null 2>&1 || { fail "$f is not valid JSON"; continue; }
    THEME=$(jq -r '.themeId // empty' "$f")
    [[ "$THEME" == "classic_WAR_classictheme" ]] || fail "$f: themeId='$THEME' (must be 'classic_WAR_classictheme')"
    jq -e 'has("defaultStyleBookEntry")' "$f" >/dev/null || fail "$f: missing defaultStyleBookEntry"
    jq -e 'has("defaultStyleBook")' "$f" >/dev/null 2>&1 && fail "$f: uses 'defaultStyleBook' — must be 'defaultStyleBookEntry'"
    [[ "$(jq -r '.defaultStyleBookEntry' "$f")" == "true" ]] && DEFAULTS=$((DEFAULTS+1))
    VAL_PATH=$(jq -r '.frontendTokensValuesPath // empty' "$f")
    if [[ -n "$VAL_PATH" ]]; then
      DIR=$(dirname "$f")
      [[ -f "$DIR/$VAL_PATH" ]] || fail "$f: frontendTokensValuesPath '$VAL_PATH' missing"
    fi
  done
  [[ "$DEFAULTS" == "1" ]] || fail "Expected exactly 1 default style book, found $DEFAULTS"
fi

section "Thumbnails"
[[ -f "$SI/thumbnail.png" ]] || fail "Missing $SI/thumbnail.png"
if [[ "$VERSION" == 7.4.13* ]]; then
  [[ -f "$ROOT/META-INF/resources/thumbnail.png" ]] || fail "Missing META-INF/resources/thumbnail.png — Select Template tile renders blank"
fi

section "metadata.json themeName"
META="$SI/layout-set/public/metadata.json"
if [[ -f "$META" ]]; then
  TN=$(jq -r '.themeName // "Classic"' "$META")
  if [[ "$VERSION" == 7.4.13* ]]; then
    [[ "$TN" == "Classic" ]] || fail "metadata.json themeName='$TN' — must be 'Classic' in 7.4.13 (workspace plugin doesn't resolve CX theme IDs)"
  fi
fi

section "Theme CX (if Scenario B)"
for yaml in $(find "$ROOT/client-extensions" -maxdepth 2 -name 'client-extension.yaml' 2>/dev/null); do
  if grep -qE 'type:\s*(themeCSS|globalCSS)' "$yaml"; then
    grep -q 'frontendTokenDefinitionJSON' "$yaml" || fail "$yaml: themeCSS/globalCSS CX missing frontendTokenDefinitionJSON entry — token def won't ship in ZIP"
    grep -q 'assemble:' "$yaml" || warn "$yaml: no 'assemble:' block — verify src/ files end up in dist ZIP"
  fi
done

section "Token usage in fragments — semantic only"
PRIMITIVE_HITS=$(grep -rE 'var\(--regular-primitives-' "$SI/fragments" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$PRIMITIVE_HITS" -gt 0 ]]; then
  fail "Fragments reference primitive tokens directly ($PRIMITIVE_HITS hits). Use semantic tokens only."
  grep -rEn 'var\(--regular-primitives-' "$SI/fragments" 2>/dev/null | head -10
else
  pass "Fragments use semantic tokens only"
fi

section "Editable IDs unique within fragment"
DUPE_FOUND=0
for html in $(find "$SI/fragments" -name 'index.html' 2>/dev/null); do
  DUPES=$(grep -oE 'data-lfr-editable-id="[^"]+"' "$html" | sort | uniq -d)
  if [[ -n "$DUPES" ]]; then
    fail "$html has duplicate data-lfr-editable-id: $DUPES"
    DUPE_FOUND=1
  fi
done
[[ "$DUPE_FOUND" == "0" ]] && pass "All editable IDs unique within their fragment"

section "ZIP/jar hygiene"
if find "$ROOT" -name '.DS_Store' -o -name '__MACOSX' 2>/dev/null | head -1 | grep -q .; then
  fail "Found .DS_Store or __MACOSX entries — clean before packaging"
else
  pass "No .DS_Store / __MACOSX leftovers"
fi

section "OSGi headers (PATH A only)"
if [[ "$VERSION" == 7.4.13* ]]; then
  BND=$(find "$ROOT/build-scripts" -name 'bnd.bnd' 2>/dev/null | head -1)
  if [[ -n "$BND" ]]; then
    grep -q '^Provide-Capability:[[:space:]]*liferay.site.initializer' "$BND" || fail "$BND missing 'Provide-Capability: liferay.site.initializer'"
    grep -q '^Liferay-Site-Initializer-Name:' "$BND" || fail "$BND missing 'Liferay-Site-Initializer-Name'"
  else
    warn "No bnd.bnd found in build-scripts/ — required for PATH A"
  fi
fi

printf '\n'
if [[ $ERR -eq 0 ]]; then
  green "All strict checks passed (warnings: $WARN)"
  exit 0
else
  red "$ERR check(s) failed — deploy is BLOCKED"
  exit 1
fi
