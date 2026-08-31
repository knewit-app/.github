#!/usr/bin/env bash
#
# knewit org 공통 라벨 동기화
#
# 라벨은 커뮤니티 헬스 파일과 달리 org에서 상속되지 않으므로,
# 새 레포를 만들 때마다 이 스크립트로 라벨 세트를 맞춥니다.
#
# 사용법:
#   ./scripts/sync-labels.sh                          # DEFAULT_REPOS 전체에 적용
#   ./scripts/sync-labels.sh knewit-app/knewit-fe     # 특정 레포만
#   ./scripts/sync-labels.sh --prune knewit-app/...   # GitHub 기본 라벨도 정리
#
# 요구사항: gh CLI 로그인 (`gh auth status`)

set -euo pipefail

ORG="knewit-app"
DEFAULT_REPOS=(
  "$ORG/knewit-fe"
  "$ORG/knewit-be"
  "$ORG/.github"
)

# name|color|description
LABELS=(
  "bug|d73a4a|버그"
  "enhancement|a2eeef|기능 추가 · 개선"
  "task|c5def5|리팩터링 · 설정 · 문서 등 일반 작업"
  "docs|0075ca|문서"
  "fe|fbca04|프론트엔드"
  "be|5319e7|백엔드"
  "infra|bfd4f2|인프라 · CI"
)

# 안 쓰는 GitHub 기본 라벨 (--prune 옵션일 때만 삭제)
STALE_LABELS=(
  "documentation" "duplicate" "good first issue"
  "help wanted" "invalid" "question" "wontfix"
)

PRUNE=false
if [[ "${1:-}" == "--prune" ]]; then
  PRUNE=true
  shift
fi

REPOS=("$@")
if [[ ${#REPOS[@]} -eq 0 ]]; then
  REPOS=("${DEFAULT_REPOS[@]}")
fi

command -v gh >/dev/null || { echo "gh CLI가 필요합니다: https://cli.github.com"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "gh 로그인이 필요합니다: gh auth login"; exit 1; }

for repo in "${REPOS[@]}"; do
  if ! gh repo view "$repo" >/dev/null 2>&1; then
    echo "!! $repo — 접근할 수 없어 건너뜁니다"
    continue
  fi

  echo "→ $repo"
  for entry in "${LABELS[@]}"; do
    IFS='|' read -r name color desc <<< "$entry"
    gh label create "$name" -R "$repo" -c "$color" -d "$desc" --force >/dev/null
    echo "   + $name"
  done

  if [[ "$PRUNE" == true ]]; then
    for name in "${STALE_LABELS[@]}"; do
      if gh label delete "$name" -R "$repo" --yes >/dev/null 2>&1; then
        echo "   - $name"
      fi
    done
  fi
done

echo "완료."
