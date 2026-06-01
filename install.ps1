$ErrorActionPreference = "Stop"

$RepoRawBase = "https://raw.githubusercontent.com/OkpoGo/lethal-company/main"
$DownloadVersion = "20260602-doorstop-game"

$ThunderstoreInstallerUrl = "$RepoRawBase/Thunderstore%20Mod%20Manager%20-%20Installer.exe?v=$DownloadVersion"
$PackZipUrl = "$RepoRawBase/lethal-company-pack.zip?v=$DownloadVersion"

$TempRoot = Join-Path $env:TEMP "okpogo-lethal-company"
$InstallerPath = Join-Path $TempRoot "Thunderstore Mod Manager - Installer.exe"
$ZipPath = Join-Path $TempRoot "lethal-company-pack.zip"
$ExtractPath = Join-Path $TempRoot "lethal-company-pack"

function Ensure-TempFolder {
    if (-not (Test-Path $TempRoot)) {
        New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
    }
}

function Pause-Menu {
    Write-Host ""
    Write-Host "계속하려면 아무 키나 누르세요..."
    [void][System.Console]::ReadKey($true)
}

function Show-Menu {
    param (
        [string[]]$Items
    )

    $selected = 0

    while ($true) {
        Clear-Host

        Write-Host "=========================================="
        Write-Host "  OkpoGo Lethal Company 설치 도우미"
        Write-Host "=========================================="
        Write-Host ""
        Write-Host "방향키 ↑ ↓ 로 선택하고 Enter를 누르세요."
        Write-Host ""

        for ($i = 0; $i -lt $Items.Count; $i++) {
            if ($i -eq $selected) {
                Write-Host " > $($Items[$i])" -ForegroundColor Cyan
            } else {
                Write-Host "   $($Items[$i])"
            }
        }

        $key = [System.Console]::ReadKey($true)

        switch ($key.Key) {
            "UpArrow" {
                if ($selected -gt 0) {
                    $selected--
                }
            }
            "DownArrow" {
                if ($selected -lt ($Items.Count - 1)) {
                    $selected++
                }
            }
            "Enter" {
                return $selected
            }
        }
    }
}

function Get-LethalCompanyProfilePaths {
    $profileRoots = @(
        (Join-Path $env:APPDATA "r2modmanPlus-local\LethalCompany\profiles"),
        (Join-Path $env:APPDATA "Thunderstore Mod Manager\DataFolder\LethalCompany\profiles"),
        (Join-Path $env:APPDATA "Thunderstore Mod Manager\LethalCompany\profiles")
    )

    $profiles = @()
    $thunderstoreLog = Join-Path $env:APPDATA "Thunderstore Mod Manager\DataFolder\log.txt"

    if (Test-Path $thunderstoreLog) {
        $logLines = Get-Content -Path $thunderstoreLog -Tail 200 -ErrorAction SilentlyContinue

        foreach ($line in $logLines) {
            $match = [regex]::Match($line, '--doorstop-target-assembly"\s+"(?<path>.+?)[/\\]BepInEx[/\\]core[/\\]BepInEx\.Preloader\.dll"')

            if ($match.Success) {
                $profiles += $match.Groups["path"].Value.Replace("/", "\")
            }
        }
    }

    foreach ($root in $profileRoots) {
        if (Test-Path $root) {
            $profiles += Get-ChildItem -Path $root -Directory | Select-Object -ExpandProperty FullName
        }
    }

    $profiles = $profiles | Sort-Object -Unique

    if ($profiles.Count -eq 0) {
        Write-Host "[안내] Lethal Company 프로필 경로를 자동으로 찾지 못했습니다." -ForegroundColor Yellow
        Write-Host "Thunderstore에서 Lethal Company 프로필을 만든 뒤 다시 실행하세요."
        Write-Host "이미 프로필이 있다면 Thunderstore에서 Modded를 한 번 눌렀다가 꺼진 후 다시 실행하면 실제 경로를 찾을 수 있습니다."
        Write-Host ""

        $manualPath = Read-Host "직접 프로필 경로를 붙여넣거나 Enter를 누르면 취소합니다"

        if ([string]::IsNullOrWhiteSpace($manualPath)) {
            throw "설치할 Thunderstore 프로필 경로가 없습니다."
        }

        return @($manualPath.Trim('"'))
    }

    if ($profiles.Count -eq 1) {
        return @($profiles[0])
    }

    Write-Host "설치할 프로필을 선택하세요."
    Write-Host "Enter만 누르면 아래 모든 프로필에 설치합니다."
    Write-Host ""
    Write-Host "0. 모든 프로필에 설치"

    for ($i = 0; $i -lt $profiles.Count; $i++) {
        Write-Host "$($i + 1). $($profiles[$i])"
    }

    Write-Host ""
    $choice = Read-Host "번호 입력"

    if ([string]::IsNullOrWhiteSpace($choice) -or $choice -eq "0") {
        return $profiles
    }

    $selected = 0

    if ([int]::TryParse($choice, [ref]$selected) -and $selected -ge 1 -and $selected -le $profiles.Count) {
        return @($profiles[$selected - 1])
    }

    throw "잘못된 선택입니다: $choice"
}

function Invoke-RobocopyChecked {
    param (
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        throw "복사할 폴더가 없습니다: $Source"
    }

    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    & robocopy $Source $Destination /E /R:2 /W:1

    if ($LASTEXITCODE -ge 8) {
        throw "복사 실패: $Source -> $Destination"
    }
}

function Copy-IfExists {
    param (
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path $Source) {
        Copy-Item -Path $Source -Destination $Destination -Force
    }
}

function Get-SteamLibraryPaths {
    $paths = @()
    $steamRoots = @()

    $defaultSteam = Join-Path ${env:ProgramFiles(x86)} "Steam"

    if (Test-Path $defaultSteam) {
        $steamRoots += $defaultSteam
    }

    try {
        $steamPath = (Get-ItemProperty -Path "HKCU:\Software\Valve\Steam" -Name SteamPath -ErrorAction Stop).SteamPath

        if ($steamPath -and (Test-Path $steamPath)) {
            $steamRoots += $steamPath
        }
    } catch {
    }

    foreach ($root in ($steamRoots | Sort-Object -Unique)) {
        $paths += $root
        $libraryFile = Join-Path $root "steamapps\libraryfolders.vdf"

        if (Test-Path $libraryFile) {
            $lines = Get-Content -Path $libraryFile -ErrorAction SilentlyContinue

            foreach ($line in $lines) {
                $match = [regex]::Match($line, '"path"\s+"(?<path>[^"]+)"|"\d+"\s+"(?<legacy>[^"]+)"')

                if ($match.Success) {
                    $libraryPath = if ($match.Groups["path"].Success) {
                        $match.Groups["path"].Value
                    } else {
                        $match.Groups["legacy"].Value
                    }

                    $paths += $libraryPath.Replace("\\", "\")
                }
            }
        }
    }

    return $paths | Sort-Object -Unique
}

function Get-LethalCompanyGamePath {
    foreach ($library in Get-SteamLibraryPaths) {
        $candidate = Join-Path $library "steamapps\common\Lethal Company"

        if (Test-Path (Join-Path $candidate "Lethal Company.exe")) {
            return $candidate
        }
    }

    $manualPath = Read-Host "Lethal Company 게임 설치 폴더를 찾지 못했습니다. 직접 경로를 붙여넣거나 Enter를 누르면 건너뜁니다"

    if ([string]::IsNullOrWhiteSpace($manualPath)) {
        return $null
    }

    return $manualPath.Trim('"')
}

function Install-DoorstopToGameFolder {
    param (
        [string]$PackRoot
    )

    $gamePath = Get-LethalCompanyGamePath

    if (-not $gamePath) {
        Write-Host "[경고] 게임 설치 폴더를 찾지 못해서 Doorstop 파일 복사를 건너뜁니다." -ForegroundColor Yellow
        Write-Host "이 경우 Thunderstore에서 Modded를 눌러도 모드가 적용되지 않을 수 있습니다."
        return
    }

    Write-Host ""
    Write-Host "게임 폴더 Doorstop 파일 복사 중..."
    Write-Host $gamePath

    foreach ($fileName in @("winhttp.dll", "doorstop_config.ini", ".doorstop_version")) {
        $source = Join-Path $PackRoot $fileName

        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $gamePath -Force
        }
    }
}

function Install-PackToProfile {
    param (
        [string]$PackRoot,
        [string]$Target
    )

    $sourceBepInEx = Join-Path $PackRoot "BepInEx"
    $targetBepInEx = Join-Path $Target "BepInEx"

    if (-not (Test-Path $sourceBepInEx)) {
        throw "압축 파일 안에서 BepInEx 폴더를 찾지 못했습니다."
    }

    $backupDir = Join-Path $Target ("backup_{0}" -f (Get-Date -Format "yyyy-MM-dd_HH-mm-ss"))

    Write-Host ""
    Write-Host "설치 대상 경로:"
    Write-Host $Target
    Write-Host ""
    Write-Host "백업 경로:"
    Write-Host $backupDir
    Write-Host ""

    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    if (Test-Path $targetBepInEx) {
        Write-Host "기존 BepInEx 백업 중..."
        Invoke-RobocopyChecked -Source $targetBepInEx -Destination (Join-Path $backupDir "BepInEx")
    }

    if (Test-Path (Join-Path $Target "_state")) {
        Write-Host "기존 _state 백업 중..."
        Invoke-RobocopyChecked -Source (Join-Path $Target "_state") -Destination (Join-Path $backupDir "_state")
    }

    Copy-IfExists -Source (Join-Path $Target "mods.yml") -Destination $backupDir
    Copy-IfExists -Source (Join-Path $Target "doorstop_config.ini") -Destination $backupDir
    Copy-IfExists -Source (Join-Path $Target ".doorstop_version") -Destination $backupDir
    Copy-IfExists -Source (Join-Path $Target "winhttp.dll") -Destination $backupDir

    Write-Host ""
    Write-Host "프로필 전체 복사 중..."
    Invoke-RobocopyChecked -Source $PackRoot -Destination $Target

    $coreCheck = Join-Path $targetBepInEx "core\BepInEx.dll"

    if (-not (Test-Path $coreCheck)) {
        throw "BepInEx\core가 복사되지 않았습니다. 확인 경로: $coreCheck"
    }

    Write-Host ""
    Write-Host "BepInEx core 확인 완료:"
    Write-Host $coreCheck

    Install-DoorstopToGameFolder -PackRoot $PackRoot
}

function Install-Thunderstore {
    Clear-Host
    Write-Host "=========================================="
    Write-Host "  1. Thunderstore Mod Manager 설치"
    Write-Host "=========================================="
    Write-Host ""

    Ensure-TempFolder

    Write-Host "Thunderstore 설치 파일 다운로드 중..."
    Write-Host $ThunderstoreInstallerUrl
    Write-Host ""

    Invoke-WebRequest -Uri $ThunderstoreInstallerUrl -OutFile $InstallerPath

    Write-Host "다운로드 완료:"
    Write-Host $InstallerPath
    Write-Host ""

    Write-Host "설치 프로그램을 실행합니다."
    Write-Host "설치 창이 뜨면 설치를 진행하세요."
    Write-Host ""

    Start-Process -FilePath $InstallerPath -Wait

    Write-Host ""
    Write-Host "Thunderstore 설치 단계가 완료되었습니다."
    Write-Host ""
    Write-Host "다음 순서:"
    Write-Host "1. Thunderstore 실행"
    Write-Host "2. Lethal Company 선택"
    Write-Host "3. Default 프로필 생성"
    Write-Host "4. 다시 이 스크립트에서 2번을 실행"
    Pause-Menu
}

function Install-LethalCompanyPack {
    Clear-Host
    Write-Host "=========================================="
    Write-Host "  2. Lethal Company Pack 다운로드 및 세팅"
    Write-Host "=========================================="
    Write-Host ""

    Ensure-TempFolder

    if (Test-Path $ExtractPath) {
        Remove-Item $ExtractPath -Recurse -Force
    }

    if (Test-Path $ZipPath) {
        Remove-Item $ZipPath -Force
    }

    Write-Host "lethal-company-pack.zip 다운로드 중..."
    Write-Host $PackZipUrl
    Write-Host ""

    Invoke-WebRequest -Uri $PackZipUrl -OutFile $ZipPath

    Write-Host "압축 해제 중..."
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

    Write-Host ""
    Write-Host "압축 해제 완료:"
    Write-Host $ExtractPath
    Write-Host ""

    $packRoot = $ExtractPath

    if (-not (Test-Path (Join-Path $packRoot "BepInEx"))) {
        $packRoot = Get-ChildItem -Path $ExtractPath -Directory -Recurse |
            Where-Object { Test-Path (Join-Path $_.FullName "BepInEx") } |
            Select-Object -ExpandProperty FullName -First 1
    }

    if (-not $packRoot) {
        Write-Host "[오류] 압축 파일 안에서 BepInEx 폴더를 찾지 못했습니다." -ForegroundColor Red
        Pause-Menu
        return
    }

    $targets = Get-LethalCompanyProfilePaths

    foreach ($target in $targets) {
        Install-PackToProfile -PackRoot $packRoot -Target $target
    }

    Write-Host ""
    Write-Host "Lethal Company Pack 세팅 완료."
    Write-Host ""
    Write-Host "Thunderstore에서 방금 설치한 프로필로 Modded 실행하면 됩니다."
    Pause-Menu
}

while ($true) {
    $choice = Show-Menu @(
        "1. Thunderstore Mod Manager exe 파일부터 설치",
        "2. lethal-company-pack.zip 다운로드 후 자동 세팅",
        "3. 종료"
    )

    switch ($choice) {
        0 {
            Install-Thunderstore
        }
        1 {
            Install-LethalCompanyPack
        }
        2 {
            Clear-Host
            Write-Host "종료합니다."
            exit
        }
    }
}
