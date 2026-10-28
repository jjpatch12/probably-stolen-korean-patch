# Probably Stolen 비공식 한국어 패치

영문(English) 언어 슬롯을 사용하는 Windows PC용 누적 한국어 패치입니다.

**[v0.1.0 베타 다운로드](https://github.com/jjpatch12/probably-stolen-korean-patch/releases/tag/v0.1.0)** · [전체 릴리즈](https://github.com/jjpatch12/probably-stolen-korean-patch/releases)

## 패치 범위

| 항목 | 반영 내용 |
| --- | --- |
| 텍스트 | 영문 기반 번역 항목 **6,680개**. 대사·전화, HUD/UI, 기기·감정, 아이템·설명 등 |
| 검수 | 초벌 번역에 Humanize Korean 검수 및 용어 정리 반영 |
| UI·대사 폰트 | **Noto Sans KR Medium** |
| 제목·기기 폰트 | **NeoDunggeunmo** |
| 이미지 | 간판·보안카드·진료소·환경 문구·서류·가이드 **19개** 한국어화 |
| 원형 유지 | 로고·상표·기관 문양·기호 등 검토 후보 **62개** 유지 |
| 감정 퍼즐 | 정품·고의 오탈자·색상·인쇄 누락·서체 차이 및 가이드 예시 대응 유지 |
| 표시 보정 | 선택 모드에 버튼 글자 최대 15% 축소, 대사 표시 속도 보정, 넘침 진단 포함 |

19개 이미지에는 WATER/NOW HIRING/ORGAN 간판, SECURITY 카드, OPEN 표시,
환경 포스터·낙서·문구, 공문서 및 관련 가이드 예시가 포함됩니다.
이전 작업분을 모두 포함하므로 별도 구버전 패치는 필요하지 않습니다.

## 설치

1. [릴리즈](https://github.com/jjpatch12/probably-stolen-korean-patch/releases/tag/v0.1.0)의 `ProbablyStolen_Korean_Patch_v0.1_20261029.zip`을 내려받아 **압축을 해제**합니다.
2. 게임을 종료하고 `Install_Korean.bat`를 실행합니다.
3. `Probably Stolen.exe`가 있는 게임 폴더를 선택합니다. 패치 폴더가 게임 폴더 안에 있으면 자동 인식합니다.
4. 게임 내 언어를 **English**로 설정합니다.

게임 폴더를 BAT 위에 끌어 놓아도 설치할 수 있습니다. Windows 기본 PowerShell을 사용하므로 Python이나 별도 패처가 필요 없습니다.

번역·폰트·이미지는 기본 적용됩니다. 대사 표시 속도와 글자 넘침 보정을 사용하려면
게임의 모드 메뉴에서 **PS Korean English Base**를 직접 신뢰·활성화합니다.
설치기는 모드 활성화·신뢰 설정, 세이브와 게임 환경설정을 바꾸지 않습니다.

## 원본 복원

`Uninstall_Korean.bat`를 실행하고 같은 게임 폴더를 선택합니다.
설치 전 파일은 게임 폴더의 `PSKorean_Backup`에 자동 보관됩니다. 이 폴더를 유지해야 자동 복원할 수 있습니다.
설치 후 다른 패치나 업데이트로 파일이 변경되면 복원을 중단합니다.

## 지원 빌드와 확인 범위

- 분석한 Windows PC 원본 빌드(내부 Unity **2021.3.45f2**) 기준입니다. 지원 원본의 SHA-256은 [매니페스트](installer/manifest.json)에 기록되어 있습니다.
- 다른 버전·다른 패치로 원본 해시가 다르면 덮어쓰기 전에 중단합니다.
- 게임 원본 전체 파일 대신 COPY/ADD 변경 데이터와 자체 제작 모드를 배포합니다.
- 새 설치·재설치·복원·버전 불일치·패치 손상 차단·설치 중 실패 시 자동 복구를 테스트 폴더에서 확인했습니다.
- **게임 플레이 검증은 아직 수행하지 않은 베타 배포본입니다.** 이미지 판독은 원본 크기와 확대 이미지에서 확인했습니다.
- 한글 가독성 때문에 작은 서류 2종의 글자 영역을 소폭 조정했습니다. 감정 퍼즐의 실제 표시 배율과 판별 난도는 실기 확인이 필요합니다.

## 파일 구성

`Install_Korean.bat` / `Uninstall_Korean.bat`, `tools/`, `data/`, `manifest.json`, `README_KO.txt`, `licenses/`, `source/`가 한 묶음입니다.
BAT만 따로 옮기지 말고 압축을 푼 폴더 전체를 유지하세요.
이 저장소에는 설치기·모드 소스와 해시 명세가 있으며, 변경 데이터는 릴리즈 ZIP에 포함됩니다.

글꼴 저작권·OFL 고지는 [licenses](installer/licenses)에 보관합니다. 게임 본편과 실행 파일은 포함하지 않습니다.
