#!/usr/bin/env bash
#
# fix-sidebar-scroll.sh
#
# Adds a scroll-fix block to docs/css/sidebar.css so the left navigation
# is always scrollable when it overflows the viewport.
#
# Background:
#   With navigation.sections + navigation.instant in mkdocs.yml, the
#   default Material sidebar can end up with overflow:hidden on the
#   scrollwrap and no usable scroll behaviour. This appends explicit
#   overflow-y:auto + max-height rules on .md-sidebar__scrollwrap.
#
# Usage:
#   1. cd into the root of your docker-workshop repo
#   2. ./fix-sidebar-scroll.sh
#   3. git add docs/css/sidebar.css
#      git commit -m "Fix sidebar scrolling on long navs"
#      git push
#
# Idempotent: re-running is a no-op (detects an existing marker).

set -euo pipefail

CSS="docs/css/sidebar.css"
MARKER="SCROLL FIX — ensure long sidebars are always scrollable"

if [ ! -f "$CSS" ]; then
  echo "Error: $CSS not found." >&2
  echo "Run this script from the root of the docker-workshop repo." >&2
  exit 1
fi

if grep -qF "$MARKER" "$CSS"; then
  echo "Scroll-fix block already present in $CSS — nothing to do."
  exit 0
fi

# Back up
cp "$CSS" "$CSS.bak"
echo "Backed up $CSS -> $CSS.bak"

# Append the fix
cat >> "$CSS" <<'CSSEOF'

/* ============================================================
   SCROLL FIX — ensure long sidebars are always scrollable
   ============================================================
   With navigation.sections + navigation.instant, the sidebar
   scrollwrap can occasionally end up clipped without scroll.
   Force overflow-y:auto so it always works.
   ============================================================ */

.md-sidebar--primary .md-sidebar__scrollwrap {
  overflow-y: auto !important;
  /* Header is ~2.4rem; leave a little breathing room */
  max-height: calc(100vh - 2.4rem);
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 transparent;
}

/* Subtle scrollbar styling on WebKit browsers */
.md-sidebar--primary .md-sidebar__scrollwrap::-webkit-scrollbar {
  width: 6px;
}
.md-sidebar--primary .md-sidebar__scrollwrap::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 3px;
}
.md-sidebar--primary .md-sidebar__scrollwrap::-webkit-scrollbar-thumb:hover {
  background: #94a3b8;
}

/* Same for the right-hand TOC */
.md-sidebar--secondary .md-sidebar__scrollwrap {
  overflow-y: auto !important;
  max-height: calc(100vh - 2.4rem);
  scrollbar-width: thin;
  scrollbar-color: #cbd5e1 transparent;
}
CSSEOF

echo "Appended scroll-fix block to $CSS"
echo ""
echo "Next steps:"
echo "  1. Verify locally:    mkdocs serve   (then resize the window or zoom in)"
echo "  2. Commit and push:"
echo "       git add $CSS"
echo "       git commit -m 'Fix sidebar scrolling on long navs'"
echo "       git push"
echo ""
echo "If the change causes issues, restore with:"
echo "       mv $CSS.bak $CSS"
