#!/usr/bin/env bash
# Publishes (or removes) one subtree of the merged, multi-branch RSpec
# preview site persisted on the gh-pages-data branch, then commits and
# pushes the change. Must be run from the root of a checkout of this repo
# (it fetches and worktree-adds gh-pages-data itself).
#
# Usage:
#   rspec-preview-publish.sh <cache-dir> <subpath> [source-dir]
#
#   cache-dir   path to check the gh-pages-data worktree out at (must not
#               already exist)
#   subpath     "" for the site root (master), or "preview/<branch>" for a
#               branch preview
#   source-dir  directory whose contents replace <cache-dir>/<subpath>;
#               omit to just remove that subtree (used for cleanup)
set -euo pipefail

cache_dir=$1
subpath=${2:-}
src_dir=${3:-}

git fetch origin gh-pages-data 2>/dev/null || true
if git rev-parse --verify -q origin/gh-pages-data >/dev/null; then
  git worktree add "$cache_dir" origin/gh-pages-data
  git -C "$cache_dir" checkout -B gh-pages-data
else
  git worktree add --orphan -b gh-pages-data "$cache_dir"
fi

if [ -z "$subpath" ]; then
  # Site root (master): only remove the known generated top-level paths.
  # Never rm -rf the whole cache dir - that would also wipe .git and preview/.
  rm -rf "$cache_dir/index.html" "$cache_dir/style.css" "$cache_dir/theme.js" "$cache_dir/vendor" "$cache_dir/cs" "$cache_dir/vbnet"
  target="$cache_dir"
else
  target="$cache_dir/$subpath"
  rm -rf "$target"
fi

if [ -n "$src_dir" ]; then
  mkdir -p "$target"
  cp -r "$src_dir"/. "$target"/
fi

preview_dir="$cache_dir/preview"
mkdir -p "$preview_dir"

# Branch names are attacker-controlled (anyone who can push a branch) and git
# refnames allow characters like & < > " that are unsafe to interpolate into
# HTML unescaped, so every branch name is escaped before use below.
html_escape() {
  local s=$1
  # & in the replacement of ${s//pat/repl} is a backreference to the match
  # (as in sed), so it must be escaped as \& to produce a literal ampersand.
  s=${s//&/\&amp;}
  s=${s//</\&lt;}
  s=${s//>/\&gt;}
  s=${s//\"/\&quot;}
  s=${s//\'/\&#39;}
  printf '%s' "$s"
}

mapfile -t idx_files < <(find "$preview_dir" -mindepth 2 -name index.html | sort)
branches=()
for f in "${idx_files[@]}"; do
  rel=${f#"$preview_dir"/}
  branches+=("${rel%/index.html}")
done

{
  echo '<!DOCTYPE html>'
  echo '<html lang="en">'
  echo '<head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
  echo '<meta name="color-scheme" content="light dark">'
  echo '<meta name="theme-color" content="#ffffff" media="(prefers-color-scheme: light)">'
  echo '<meta name="theme-color" content="#16181d" media="(prefers-color-scheme: dark)">'
  echo '<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='"'"'http://www.w3.org/2000/svg'"'"' viewBox='"'"'0 0 16 16'"'"'%3E%3Crect width='"'"'16'"'"' height='"'"'16'"'"' rx='"'"'3'"'"' fill='"'"'%23c0392b'"'"'/%3E%3Ctext x='"'"'8'"'"' y='"'"'12'"'"' font-size='"'"'10'"'"' font-weight='"'"'bold'"'"' text-anchor='"'"'middle'"'"' fill='"'"'%23ffffff'"'"'%3ES%3C/text%3E%3C/svg%3E">'
  echo '<title>RSpec preview branches</title>'
  echo '<link rel="stylesheet" href="../style.css">'
  echo '<script src="../theme.js"></script>'
  echo '</head>'
  echo '<body>'
  echo '<div class="header-row">'
  echo '<p><a class="back" href="../index.html"><span aria-hidden="true">&larr;</span> Back to main site</a></p>'
  echo '<button type="button" id="theme-toggle">Theme: Auto</button>'
  echo '</div>'
  echo '<h1>Active branch previews</h1>'
  if [ "${#branches[@]}" -eq 0 ]; then
    echo '<p>No active branch previews.</p>'
  else
    echo '<ul>'
    for branch in "${branches[@]}"; do
      esc_branch=$(html_escape "$branch")
      echo "<li><a href=\"$esc_branch/\">$esc_branch</a></li>"
    done
    echo '</ul>'
  fi
  echo '</body></html>'
} > "$preview_dir/index.html"

cd "$cache_dir"
git add -A
if ! git diff --cached --quiet; then
  git commit -m "Update ${subpath:-site root}"
  git push origin gh-pages-data
fi
