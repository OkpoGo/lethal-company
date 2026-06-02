# OkpoGo Lethal Company 모드팩

PowerShell에서 아래 명령어를 실행하면 설치 메뉴가 열립니다.

```powershell
irm https://github.com/OkpoGo/lethal-company/raw/main/go.ps1|iex
```

위 명령어로 실행이 막히면 아래 명령어를 사용하세요.

```powershell
powershell -ep bypass -c "irm https://github.com/OkpoGo/lethal-company/raw/main/go.ps1|iex"
```

## 설치 순서

처음 설치하는 경우:

1. 위 명령어 실행
2. 메뉴에서 `1. Thunderstore Mod Manager exe 파일부터 설치` 선택
3. Thunderstore 설치 완료
4. Thunderstore 실행
5. `Lethal Company` 선택
6. `Default` 프로필 만들기
7. 위 명령어 다시 실행
8. 메뉴에서 `2. Lethal Company DataFolder 다운로드 후 자동 세팅` 선택
9. 끝나면 Thunderstore에서 `Lethal Company - Default`로 들어가서 `Modded` 실행

Thunderstore와 `Default` 프로필이 이미 있으면 2번 메뉴만 실행하면 됩니다.

## 메뉴

```txt
1. Thunderstore Mod Manager exe 파일부터 설치
2. Lethal Company DataFolder 다운로드 후 자동 세팅
3. 종료
```

## 2번이 하는 일

2번 메뉴는 GitHub에 올라간 압축 파일 조각을 다운로드한 뒤 하나의 zip 파일로 다시 합칩니다.
그 다음 아래 위치에 `LethalCompany` 폴더 전체를 설치합니다.

```txt
%APPDATA%\Thunderstore Mod Manager\DataFolder
```

기존 `LethalCompany` 폴더는 먼저 백업되고, 이후 새 폴더로 교체됩니다.

설치 후 구조는 대략 아래와 같습니다.

```txt
DataFolder
└─ LethalCompany
   ├─ cache
   └─ profiles
      └─ Default
```

또한 Steam 게임 폴더에도 `winhttp.dll`, `doorstop_config.ini`, `.doorstop_version`을 맞춰 넣습니다.

## 실행할 때

설치 후 Steam에서 직접 실행하지 말고 Thunderstore에서 `Modded` 버튼으로 실행하세요.

정상적으로 적용되면 게임이 켜질 때 검은 콘솔창이 같이 뜹니다.
그 창이 뜨면 BepInEx가 정상적으로 잡힌 상태입니다.

콘솔창이 안 뜨면 PowerShell을 관리자 권한으로 열고 2번 메뉴를 다시 실행하세요.

## 확인용

모드가 제대로 잡히면 아래 파일 시간이 방금 실행한 시간으로 바뀝니다.

```txt
%APPDATA%\Thunderstore Mod Manager\DataFolder\LethalCompany\profiles\Default\BepInEx\LogOutput.log
```

파일 안에 아래 내용이 보이면 모드가 로딩된 상태입니다.

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
