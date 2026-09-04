# .github

knewit org의 **공통 커뮤니티 헬스 파일**을 모아둔 레포입니다.
org 내 모든 레포는 자체 파일이 없으면 여기 있는 템플릿을 자동으로 상속합니다.

## 구성

```
.github/
├─ profile/
│  └─ README.md               # org 프로필 페이지 (github.com/knewit-app 메인)
├─ .github/
│  ├─ PULL_REQUEST_TEMPLATE.md
│  └─ ISSUE_TEMPLATE/
│     ├─ bug.yml              # 버그 리포트 폼
│     ├─ feature.yml          # 기능 제안 폼
│     ├─ task.yml             # 일반 작업 폼 (리팩터링/설정/문서 등)
│     └─ config.yml           # 이슈 선택 화면 설정
├─ scripts/
│  └─ sync-labels.sh          # org 공통 라벨을 각 레포에 동기화
├─ CONTRIBUTING.md            # 공통 기여 가이드
├─ .gitignore
└─ README.md
```

## 동작 방식

- **상속** — 개별 레포에 `.github/ISSUE_TEMPLATE/`나 `PULL_REQUEST_TEMPLATE.md`가 없으면 이 레포의 파일이 쓰입니다.
- **Override** — 레포에 같은 이름의 파일을 두면 그 레포에서는 그쪽이 우선합니다. 부분 상속은 없고 **디렉터리 단위로 통째로 대체**되니, 이슈 템플릿을 하나라도 커스텀하려면 필요한 템플릿 전체를 해당 레포에 두어야 합니다.
- `profile/README.md`는 org 메인 페이지에만 노출되고 상속과는 무관합니다.

## 라벨

라벨은 **상속되지 않습니다.** 레포마다 따로 존재해야 하므로 스크립트로 맞춥니다.

```bash
./scripts/sync-labels.sh                        # 기본 레포 전체
./scripts/sync-labels.sh knewit-app/knewit-fe   # 특정 레포만
./scripts/sync-labels.sh --prune <repo>         # GitHub 기본 라벨까지 정리
```

라벨 세트를 바꿀 때는 스크립트의 `LABELS` 배열을 수정하고 다시 실행하면 됩니다. (`--force`라 기존 라벨은 덮어씁니다.)
새로 만들 레포에 자동 적용하려면 Organization Settings → Repository → Repository defaults → Labels 도 함께 맞춰두세요.

## 레포별 커스터마이징 가이드

템플릿은 RN 클라이언트 / Spring / FastAPI를 함께 쓰는 것을 전제로 일부러 일반적으로 작성했습니다.
레포 성격상 아래 정도만 손보면 충분합니다.

- 이슈 폼의 `영역` dropdown → 해당 레포에 맞는 항목만 남기기
- PR 템플릿의 체크리스트 → 레포별 필수 검증 항목 추가 (예: 스냅샷 테스트, DB 마이그레이션)
- 브랜치 전략이 다르면 레포 `CONTRIBUTING.md`에 그 부분만 기술

## 수정할 때

이 레포의 변경은 org 전체에 영향을 줍니다. 템플릿을 바꿀 때는 PR로 올리고 각 파트 리뷰를 받아주세요.
