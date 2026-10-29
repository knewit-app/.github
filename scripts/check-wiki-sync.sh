#!/usr/bin/env bash
#
# experiment-to-wiki 연결 상태 점검
#
# org 레포마다 PR이 닫힐 때 "## 실험 결과"를 context-docs/_inbox로 보내는
# 워크플로가 제대로 붙어 있는지 확인합니다.
#
#   워크플로  .github/workflows/experiment-to-wiki.yml 이 기본 브랜치에 있는가
#   템플릿    PR 템플릿에 "## 실험 결과" 섹션이 있는가 (org 기본 템플릿에는 없다)
#   토큰      마지막 실행에서 WIKI_TOKEN 시크릿이 들어왔는가
#
# 토큰은 시크릿 값을 직접 볼 수 없어서 마지막 실행 로그의 env 출력(*** 이면 있음)으로 판단합니다.
# 실행 이력이 없으면 UNKNOWN이고, 그 레포에서 PR 하나가 닫힌 뒤 다시 돌리면 됩니다.
#
# 사용법:
#   ./scripts/check-wiki-sync.sh                      # org 레포 전체
#   ./scripts/check-wiki-sync.sh knewit-fe knewit-be  # 특정 레포만
#
# 요구사항: gh CLI 로그인 (`gh auth status`)
# 문제가 하나라도 있으면 exit 1 입니다.

set -euo pipefail

ORG="knewit-app"
WF=".github/workflows/experiment-to-wiki.yml"
# 기록을 받는 쪽이거나 코드 레포가 아니라 대상에서 뺀다
SKIP=" context-docs .github capstone-docs "

if [ $# -gt 0 ]; then
  REPOS=("$@")
else
  mapfile -t REPOS < <(gh repo list "$ORG" --no-archived --limit 100 --json name --jq '.[].name' | sort)
fi

has_section() { gh api "repos/$ORG/$1/contents/$2" --jq .content 2>/dev/null | base64 -d 2>/dev/null | grep -q '^## 실험 결과'; }

fail=0
printf '%-24s %-9s %-9s %s\n' REPO WORKFLOW TEMPLATE TOKEN
for r in "${REPOS[@]}"; do
  case "$SKIP" in *" $r "*) continue ;; esac

  wf=OK; tpl=OK; tok=OK
  gh api "repos/$ORG/$r/contents/$WF" --silent 2>/dev/null || wf=MISSING
  has_section "$r" .github/PULL_REQUEST_TEMPLATE.md \
    || has_section "$r" .github/pull_request_template.md \
    || tpl=MISSING

  run=$(gh run list -R "$ORG/$r" -w experiment-to-wiki.yml -L 1 --json databaseId --jq '.[0].databaseId // empty' 2>/dev/null || true)
  if [ -z "$run" ]; then
    tok=UNKNOWN
  elif ! gh run view "$run" -R "$ORG/$r" --log 2>/dev/null | grep -q 'WIKI_TOKEN: \*\*\*'; then
    tok="MISSING (run $run)"
  fi

  printf '%-24s %-9s %-9s %s\n' "$r" "$wf" "$tpl" "$tok"
  [ "$wf$tpl" = OKOK ] && [[ "$tok" != MISSING* ]] || fail=1
done

if [ "$fail" = 1 ]; then
  cat <<'EOF'

조치
  WORKFLOW MISSING  다른 레포의 experiment-to-wiki.yml 을 그대로 복사
  TEMPLATE MISSING  "## 실험 결과" 섹션이 있는 PULL_REQUEST_TEMPLATE.md 를 레포에 추가
  TOKEN MISSING     Org Settings → Secrets and variables → Actions → WIKI_TOKEN → Repository access 에 레포 추가
EOF
  exit 1
fi
