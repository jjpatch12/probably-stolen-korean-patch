# Probably Stolen 비공식 한국어 패치 1.0

영문(English) 언어 슬롯을 사용하는 Windows PC용 누적 한국어 패치입니다.

**[1.0 BAT 한 파일 다운로드](https://github.com/jjpatch12/probably-stolen-korean-patch/releases/download/v1.0/ProbablyStolen_Korean_Patch_1.0.bat)** · [전체 릴리즈](https://github.com/jjpatch12/probably-stolen-korean-patch/releases)

## 패치 범위

| 항목 | 반영 내용 |
| --- | --- |
| 텍스트 | 영문 기반 번역 항목 **6,680개**. 대사·전화, HUD/UI, 기기·감정, 아이템·설명 등 |
| 이미지 | 간판·보안카드·진료소·환경 문구·서류·가이드 **19개** 한국어화 |
| 원형 유지 | 로고·상표·기관 문양·기호 등 검토 후보 **62개** 유지 |
| 감정 퍼즐 | 정품·고의 오탈자·색상·인쇄 누락·서체 차이 및 가이드 예시 대응 유지 |
| 표시 보정 | 선택 모드에 버튼 글자 최대 15% 축소, 대사 표시 속도 보정, 넘침 진단 포함 |

19개 이미지에는 WATER/NOW HIRING/ORGAN 간판, SECURITY 카드, OPEN 표시,
환경 포스터·낙서·문구, 공문서 및 관련 가이드 예시가 포함됩니다.
이전 작업분을 모두 포함하므로 별도 구버전 패치는 필요하지 않습니다.

## 설치

1. [릴리즈](https://github.com/jjpatch12/probably-stolen-korean-patch/releases/tag/v1.0)의 **ProbablyStolen_Korean_Patch_1.0.bat** 한 파일만 받습니다.
2. 게임을 종료하고 BAT를 실행한 뒤 **[1] 설치**를 선택합니다.
3. `Probably Stolen.exe`가 있는 게임 폴더를 선택하고, 게임 내 언어를 **English**로 설정합니다.

게임 폴더를 BAT 위에 끌어 놓아도 설치할 수 있습니다.

번역·폰트·이미지는 기본 적용됩니다. 대사 표시 속도와 글자 넘침 보정을 사용하려면
게임의 모드 메뉴에서 **PS Korean English Base**를 직접 신뢰·활성화합니다.
설치기는 모드 활성화·신뢰 설정, 세이브와 게임 환경설정을 바꾸지 않습니다.

## 원본 복원

같은 BAT를 다시 실행하고 **[2] 원본 복원**을 선택한 뒤 같은 게임 폴더를 지정합니다.
설치 전 파일은 게임 폴더의 `PSKorean_Backup`에 자동 보관됩니다. 이 폴더를 유지해야 자동 복원할 수 있습니다.
설치 후 다른 패치나 업데이트로 파일이 변경되면 복원을 중단합니다.


## 파일 구성

배포 파일은 **ProbablyStolen_Korean_Patch_1.0.bat 한 개**입니다.
필요한 데이터는 BAT에 내장되어 실행 중 임시 폴더에 풀리고, 종료 시 임시 파일이 정리됩니다.
BAT의 **[3] 안내/폰트 라이선스**에서 설명과 라이선스 전문을 확인할 수 있습니다.
저장소의 `installer` 폴더는 내부 적용 엔진·모드·명세의 검토용 소스입니다.
