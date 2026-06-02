# OkpoGo Lethal Company 모드팩

PowerShell 열고 아래 명령어 붙여넣으면 설치 메뉴 뜸.

```powershell
irm https://github.com/OkpoGo/lethal-company/raw/main/go.ps1|iex
```

위 명령어가 막히면 아래 명령어로 실행하면 됨.

```powershell
powershell -ep bypass -c "irm https://github.com/OkpoGo/lethal-company/raw/main/go.ps1|iex"
```

## 설치 순서

처음 설치하는 경우는 이렇게 하면 됨.

1. 위 명령어 실행
2. 메뉴에서 `1. Thunderstore Mod Manager exe 파일부터 설치` 선택
3. Thunderstore 설치 끝내기
4. Thunderstore 실행
5. `Lethal Company` 선택
6. `Default` 프로필 만들기
7. 위 명령어 다시 실행
8. 메뉴에서 `2. Lethal Company DataFolder 다운로드 후 자동 세팅` 선택
9. 설치 끝나면 Thunderstore에서 `Lethal Company - Default` 들어간 뒤 `Modded` 실행

Thunderstore랑 `Default` 프로필이 이미 있으면 바로 2번 메뉴만 실행하면 됨.

## 메뉴

```txt
1. Thunderstore Mod Manager exe 파일부터 설치
2. Lethal Company DataFolder 다운로드 후 자동 세팅
3. 설치 상태 확인
4. 이전 백업으로 복구
5. 종료
```

## 들어간 기능 체크리스트

- [x] 설치 로그 저장함
- [x] 관리자 권한 아니면 자동으로 다시 실행함
- [x] 설치 상태 확인 메뉴 넣음
- [x] 기존 백업 최근 3개만 남기게 정리함
- [x] 이전 백업으로 복구하는 메뉴 넣음
- [x] GitHub Release 방식 확인함
- [x] Release 업로드 도구가 현재 PC에 없어서 압축 조각 방식 유지함

설치 로그는 아래 폴더에 생김.

```txt
%TEMP%\okpogo-lethal-company
```

문제 생기면 `install-log_날짜_시간.txt` 보면 됨.

## 2번 메뉴가 하는 것

2번 메뉴는 GitHub에 올라간 압축 파일 조각을 다운로드함.
그 조각들을 다시 하나의 zip 파일로 합친 뒤 아래 위치에 `LethalCompany` 폴더 전체를 넣음.

```txt
%APPDATA%\Thunderstore Mod Manager\DataFolder
```

기존 `LethalCompany` 폴더는 먼저 백업됨.
그 다음 기존 폴더를 지우고 새 폴더로 교체됨.

설치 후 구조는 대충 이런 식임.

```txt
DataFolder
└─ LethalCompany
   ├─ cache
   └─ profiles
      └─ Default
```

Steam 게임 폴더에도 `winhttp.dll`, `doorstop_config.ini`, `.doorstop_version` 맞춰서 들어감.

## 실행 방법

설치 끝나고 Steam에서 그냥 실행하면 안 됨.
Thunderstore에서 `Modded` 버튼 눌러서 실행해야 함.

정상 적용되면 게임 켜질 때 검은 콘솔창도 같이 뜸.
그 창이 뜨면 BepInEx가 제대로 잡힌 상태임.

콘솔창이 안 뜨면 3번 메뉴로 상태 확인하고, 필요하면 2번 다시 실행하면 됨.

## 복구 방법

설치 전 기존 `LethalCompany` 폴더는 자동으로 백업됨.
문제 생기면 4번 메뉴에서 이전 백업 선택해서 되돌릴 수 있음.

백업은 기본적으로 최근 3개만 남김.

## 확인 방법

모드가 제대로 잡히면 아래 파일 시간이 방금 실행한 시간으로 바뀜.

```txt
%APPDATA%\Thunderstore Mod Manager\DataFolder\LethalCompany\profiles\Default\BepInEx\LogOutput.log
```

파일 안에 아래 내용이 보이면 모드 로딩된 상태임.

```txt
14 plugins to load
Loading [MoreCompany
Loading [LCKR
Loading [More Suits
```

## 들어있는 것

```txt
lethal-company
├─ README.md
├─ go.ps1
├─ install.ps1
├─ datafolder-parts
│  ├─ lethal-company-datafolder.zip.001
│  ├─ lethal-company-datafolder.zip.002
│  ├─ lethal-company-datafolder.zip.003
│  └─ lethal-company-datafolder.zip.004
└─ Thunderstore Mod Manager - Installer.exe
```
