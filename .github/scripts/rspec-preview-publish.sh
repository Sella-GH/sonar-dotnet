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
  rm -rf "$cache_dir/index.html" "$cache_dir/style.css" "$cache_dir/vendor" "$cache_dir/cs" "$cache_dir/vbnet"
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
  echo '<title>RSpec preview branches</title></head>'
  echo '<body>'
  echo '<p><a href="../index.html">&larr; Back to main site</a></p>'
  echo '<h1>Active branch previews</h1>'
  if [ "${#branches[@]}" -eq 0 ]; then
    echo '<p>No active branch previews.</p>'
  else
    echo '<ul>'
    for branch in "${branches[@]}"; do
      echo "<li><a href=\"$branch/\">$branch</a></li>"
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
