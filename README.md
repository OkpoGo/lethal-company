# OkpoGo Lethal Company 설치 도우미

친구에게는 아래 PowerShell 명령어 한 줄만 보내면 됩니다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/OkpoGo/lethal-company/main/install.ps1?v=20260602-powershell-copy' | iex"
```

이 명령어는 GitHub에서 `install.ps1`을 바로 내려받아 실행합니다.
실행하면 메뉴가 뜨고, 필요한 파일은 자동으로 다운로드됩니다.

## 사용 방법

1. Windows에서 PowerShell을 엽니다.
2. 위 명령어를 그대로 복사해서 붙여넣습니다.
3. Enter를 누릅니다.
4. 메뉴가 뜨면 방향키로 원하는 항목을 선택하고 Enter를 누릅니다.

메뉴는 아래처럼 나옵니다.

```txt
1. Thunderstore Mod Manager exe 파일부터 설치
2. lethal-company-pack.zip 다운로드 후 자동 세팅
3. 종료
```

## 처음 설치하는 친구

처음 설치하는 친구는 아래 순서대로 하면 됩니다.

1. PowerShell에서 명령어를 실행합니다.
2. 메뉴에서 `1. Thunderstore Mod Manager exe 파일부터 설치`를 선택합니다.
3. Thunderstore 설치 창이 뜨면 설치를 끝냅니다.
4. Thunderstore를 실행합니다.
5. `Lethal Company`를 선택합니다.
6. `Default` 프로필을 하나 만듭니다.
7. 다시 PowerShell 명령어를 실행합니다.
8. 메뉴에서 `2. lethal-company-pack.zip 다운로드 후 자동 세팅`을 선택합니다.
9. 설치가 끝나면 Thunderstore에서 `Lethal Company - Default` 프로필로 `Modded` 실행합니다.

## Thunderstore가 이미 설치된 친구

Thunderstore가 이미 설치되어 있고 `Lethal Company - Default` 프로필도 만들어져 있으면 아래처럼 하면 됩니다.

1. PowerShell에서 명령어를 실행합니다.
2. 메뉴에서 `2. lethal-company-pack.zip 다운로드 후 자동 세팅`을 선택합니다.
3. 설치가 끝나면 Thunderstore에서 `Modded`로 실행합니다.

## 각 메뉴 설명

### 1. Thunderstore Mod Manager exe 파일부터 설치

GitHub에 올라가 있는 `Thunderstore Mod Manager - Installer.exe`를 다운로드하고 설치 프로그램을 실행합니다.

설치가 끝나면 Thunderstore에서 `Lethal Company`를 고르고 `Default` 프로필을 만들어야 합니다.
그 다음 다시 이 스크립트를 실행해서 2번 메뉴를 진행하면 됩니다.

### 2. lethal-company-pack.zip 다운로드 후 자동 세팅

GitHub에 올라가 있는 `lethal-company-pack.zip`을 다운로드하고 압축을 풉니다.
압축 안에 있는 `install.bat`을 실행해서 Thunderstore의 `Lethal Company - Default` 프로필에 모드 파일을 복사합니다.

설치할 때 기존 파일은 백업 폴더에 따로 복사됩니다.

### 3. 종료

설치 도우미를 종료합니다.

## 주의사항

- Windows PowerShell에서 실행하세요.
- 친구 PC에 Lethal Company가 설치되어 있어야 합니다.
- 2번 메뉴를 실행하기 전에 Thunderstore에서 `Lethal Company - Default` 프로필을 만들어두는 것이 좋습니다.
- 다운로드가 막히면 PowerShell을 다시 열어서 한 번 더 실행해보세요.
- 회사, 학교, PC방 네트워크에서는 GitHub 다운로드가 막힐 수 있습니다.

## 저장소에 들어 있는 파일

```txt
lethal-company
├─ README.md
├─ install.ps1
├─ lethal-company-pack.zip
└─ Thunderstore Mod Manager - Installer.exe
```
