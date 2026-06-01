# OkpoGo Lethal Company 설치 도우미

친구에게는 아래 PowerShell 명령어 한 줄만 보내면 됩니다.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm 'https://raw.githubusercontent.com/OkpoGo/lethal-company/da195af0dcb1d022307cf597e8a6027893f1f91b/install.ps1' | iex"
```

이 명령어는 GitHub에서 `install.ps1`을 바로 내려받아 실행합니다.
실행하면 메뉴가 뜨고, 필요한 파일은 자동으로 다운로드됩니다.

## 사용 방법

1. Windows에서 PowerShell을 엽니다.
2. 위 명령어를 그대로 복사해서 붙여넣습니다.
3. Enter를 누릅니다.
4. 메뉴가 뜨면 방향키로 원하는 항목을 선택하고 Enter를 누릅니다.
5. 프로필 선택 화면이 나오면, 잘 모르겠으면 Enter만 눌러 모든 프로필에 설치합니다.

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
3. 프로필 선택 화면이 나오면, 실제로 실행할 프로필을 고르거나 Enter를 눌러 모든 프로필에 설치합니다.
4. 설치가 끝나면 Thunderstore에서 `Modded`로 실행합니다.

## 각 메뉴 설명

### 1. Thunderstore Mod Manager exe 파일부터 설치

GitHub에 올라가 있는 `Thunderstore Mod Manager - Installer.exe`를 다운로드하고 설치 프로그램을 실행합니다.

설치가 끝나면 Thunderstore에서 `Lethal Company`를 고르고 `Default` 프로필을 만들어야 합니다.
그 다음 다시 이 스크립트를 실행해서 2번 메뉴를 진행하면 됩니다.

### 2. lethal-company-pack.zip 다운로드 후 자동 세팅

GitHub에 올라가 있는 `lethal-company-pack.zip`을 다운로드하고 압축을 풉니다.
Thunderstore의 Lethal Company 프로필을 찾아서 프로필 파일 전체를 복사합니다.

설치할 때 기존 파일은 백업 폴더에 따로 복사됩니다.
그 다음 기존 `BepInEx`, `_state`, `mods.yml`, `doorstop_config.ini`, `.doorstop_version`, `winhttp.dll`을 정리하고 새 파일로 다시 넣습니다.

### 3. 종료

설치 도우미를 종료합니다.

## 주의사항

- Windows PowerShell에서 실행하세요.
- 친구 PC에 Lethal Company가 설치되어 있어야 합니다.
- 2번 메뉴를 실행하기 전에 Thunderstore에서 `Lethal Company - Default` 프로필을 만들어두는 것이 좋습니다.
- 설치 후에는 Steam에서 그냥 실행하지 말고, 반드시 Thunderstore에서 `Lethal Company` 프로필을 열고 `Modded` 버튼으로 실행하세요.
- 설치 후에도 적용이 안 보이면 Thunderstore를 완전히 종료했다가 다시 켠 뒤 `Modded`로 실행하세요.
- 설치 스크립트는 Thunderstore 프로필뿐 아니라 Steam의 `Lethal Company` 게임 폴더에도 Doorstop 로더 파일을 복사합니다.
- 2번 메뉴는 기존 모드 파일을 백업한 뒤 깨끗하게 정리하고 새 팩으로 다시 설치합니다.
- 친구 PC에서 `Modded`를 눌렀는데 검은 콘솔창이 안 뜨면, 모드 문제가 아니라 BepInEx 로더가 시작되지 않은 상태일 가능성이 큽니다.
- 그런 경우 2번 메뉴를 다시 실행하세요. 그래도 안 되면 PowerShell을 관리자 권한으로 열어서 같은 명령어를 다시 실행하세요.
- 다운로드가 막히면 PowerShell을 다시 열어서 한 번 더 실행해보세요.
- 회사, 학교, PC방 네트워크에서는 GitHub 다운로드가 막힐 수 있습니다.

## 적용 확인 방법

Thunderstore에서 `Modded`로 실행하면 보통 검은 콘솔창이 같이 뜹니다.
그 콘솔창이 뜨면 BepInEx 로더가 실행된 것입니다.

아래 파일 시간이 방금 실행한 시간으로 바뀌어도 모드 로더가 실행된 것입니다.

```txt
%APPDATA%\Thunderstore Mod Manager\DataFolder\LethalCompany\profiles\Default\BepInEx\LogOutput.log
```

파일 안에 아래 문구들이 보이면 모드가 로드된 상태입니다.

```txt
14 plugins to load
Loading [MoreCompany
Loading [LCKR
Loading [More Suits
```

콘솔창이 안 뜨고 `LogOutput.log` 시간도 안 바뀌면 아래 파일들이 Steam 게임 폴더에 있는지 확인하세요.

```txt
Steam\steamapps\common\Lethal Company\winhttp.dll
Steam\steamapps\common\Lethal Company\doorstop_config.ini
Steam\steamapps\common\Lethal Company\.doorstop_version
```

특히 `doorstop_config.ini` 안의 `target_assembly`가 아래처럼 Thunderstore 프로필의 `BepInEx.Preloader.dll`을 가리켜야 합니다.

```txt
target_assembly=C:/Users/사용자명/AppData/Roaming/Thunderstore Mod Manager/DataFolder/LethalCompany/profiles/Default/BepInEx/core/BepInEx.Preloader.dll
```

## 저장소에 들어 있는 파일

```txt
lethal-company
├─ README.md
├─ install.ps1
├─ lethal-company-pack.zip
└─ Thunderstore Mod Manager - Installer.exe
```
