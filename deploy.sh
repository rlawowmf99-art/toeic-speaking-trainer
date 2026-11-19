#!/bin/sh
# Publish the TOEIC Speaking trainer to GitHub Pages at
# https://rlawowmf99-art.github.io/toeic-speaking-trainer/
# Safe to re-run: it checks the real remote state before touching anything.
set -u
OWNER=rlawowmf99-art
REPO=$OWNER/toeic-speaking-trainer
SRC=/workspace/projects/toeic-speaking-trainer
WORK=/workspace/work/toeic-publish
WANT_SIZE=395705
URL=https://$OWNER.github.io/toeic-speaking-trainer/

echo "== 1. repo state"
if ! gh repo view "$REPO" --json visibility,isEmpty,defaultBranchRef >/tmp/repo.json 2>/tmp/repo.err; then
  cat /tmp/repo.err
  echo "STOP: $REPO does not exist yet (only the account owner can create it)."
  exit 10
fi
cat /tmp/repo.json

echo "== 2. publish files"
if gh api "repos/$REPO/contents/index.html" >/dev/null 2>&1; then
  echo "remote already has index.html; updating in place without rewriting history"
  rm -rf "$WORK"
  git clone -q "https://github.com/$REPO.git" "$WORK" || { echo "STOP: clone failed"; exit 12; }
  cp "$SRC/index.html" "$SRC/README.md" "$WORK"/
  cd "$WORK" || exit 12
  git add -A
  git -c user.name="$OWNER" -c user.email="$OWNER@users.noreply.github.com" commit -q -m "Update TOEIC Speaking AL trainer v3" || echo "(no content change)"
else
  echo "remote has no index.html; using the prepared commit in work/toeic-deploy"
  cd /workspace/work/toeic-deploy || exit 11
  git remote remove origin 2>/dev/null
  git remote add origin "https://github.com/$REPO.git"
  git push -u origin main || { echo "STOP: push failed"; exit 12; }
fi

echo "== 3. enable GitHub Pages (main, /)"
gh api "repos/$REPO/pages" -X POST -f build_type=legacy -f "source[branch]=main" -f "source[path]=/" >/tmp/pages.json 2>/tmp/pages.err
if [ $? -ne 0 ]; then
  echo "(POST failed; checking existing config)"
  cat /tmp/pages.err
  gh api "repos/$REPO/pages" | head -c 500; echo
else
  head -c 300 /tmp/pages.json; echo
fi

echo "== 4. wait for build and live page"
i=0
while [ $i -lt 16 ]; do
  st=$(gh api "repos/$REPO/pages/builds/latest" --jq '.status' 2>/dev/null)
  live=$(curl -s -o /tmp/live.html -w '%{http_code}' "$URL")
  echo "t=$((i*15))s build=$st http=$live bytes=$(wc -c </tmp/live.html 2>/dev/null)"
  if [ "$live" = "200" ] && grep -q "TOEIC Speaking" /tmp/live.html; then
    echo "LIVE: $URL"
    exit 0
  fi
  sleep 15
  i=$((i+1))
done

echo "NOT LIVE YET: last status build=$st http=$live"
exit 20
