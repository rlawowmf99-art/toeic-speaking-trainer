#!/bin/sh
# Verify the TOEIC Speaking trainer is live on GitHub Pages.
# Usage: sh work/toeic-deploy/verify-live.sh
# Prerequisite: Pages must be enabled by the account owner
#   Settings -> Pages -> Source: Deploy from a branch -> main / (root) -> Save
#   (Pickle's GitHub connection has no Pages permission, so it cannot turn this on.)
set -u
OWNER=rlawowmf99-art
REPO=$OWNER/toeic-speaking-trainer
URL=https://$OWNER.github.io/$REPO/
# the repo name part of the pages URL
URL=https://$OWNER.github.io/toeic-speaking-trainer/

echo "== pages config"
gh api "repos/$REPO/pages" 2>/dev/null | head -c 400; echo

echo "== latest build"
gh api "repos/$REPO/pages/builds/latest" --jq '{status,created_at,commit}' 2>/dev/null || echo "(no build yet)"

echo "== http + content"
code=$(curl -s -o /tmp/live.html -w '%{http_code}' "$URL")
echo "http=$code bytes=$(wc -c < /tmp/live.html 2>/dev/null)"
grep -o '<title>[^<]*</title>' /tmp/live.html
for m in "Part 1" "Part 2" "Part 3" "Part 4" "Part 5" "모의고사"; do
  if grep -q "$m" /tmp/live.html; then echo "  ok: $m"; else echo "  MISSING: $m"; fi
done
