$ErrorActionPreference = "Stop"

$RepoRawBase = "https://raw.githubusercontent.com/OkpoGo/lethal-company/main"
$DownloadVersion = "20260602-powershell-copy"

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

function Get-LethalCompanyProfilePath {
    $candidates = @(
        (Join-Path $env:APPDATA "r2modmanPlus-local\LethalCompany\profiles\Default"),
        (Join-Path $env:APPDATA "Thunderstore Mod Manager\DataFolder\LethalCompany\profiles\Default")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    foreach ($candidate in $candidates) {
        $profilesRoot = Split-Path $candidate -Parent
        if (Test-Path $profilesRoot) {
            return $candidate
        }
    }

    Write-Host "[안내] Thunderstore Default 프로필 경로를 자동으로 찾지 못했습니다." -ForegroundColor Yellow
    Write-Host "Thunderstore에서 Lethal Company - Default 프로필을 만든 뒤 다시 실행하는 것이 가장 좋습니다."
    Write-Host ""

    $fallback = $candidates[0]
    $manualPath = Read-Host "직접 경로를 붙여넣거나 Enter를 누르면 기본 경로를 사용합니다"

    if ([string]::IsNullOrWhiteSpace($manualPath)) {
        return $fallback
    }

    return $manualPath.Trim('"')
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

    Copy-IfExists -Source (Join-Path $Target "mods.yml") -Destination $backupDir
    Copy-IfExists -Source (Join-Path $Target "doorstop_config.ini") -Destination $backupDir
    Copy-IfExists -Source (Join-Path $Target "winhttp.dll") -Destination $backupDir

    Write-Host ""
    Write-Host "BepInEx 전체 복사 중..."
    Invoke-RobocopyChecked -Source $sourceBepInEx -Destination $targetBepInEx

    Write-Host ""
    Write-Host "프로필 루트 파일 복사 중..."
    Copy-IfExists -Source (Join-Path $PackRoot "mods.yml") -Destination $Target
    Copy-IfExists -Source (Join-Path $PackRoot "doorstop_config.ini") -Destination $Target
    Copy-IfExists -Source (Join-Path $PackRoot "winhttp.dll") -Destination $Target

    $coreCheck = Join-Path $targetBepInEx "core\BepInEx.dll"

    if (-not (Test-Path $coreCheck)) {
        throw "BepInEx\core가 복사되지 않았습니다. 확인 경로: $coreCheck"
    }

    Write-Host ""
    Write-Host "BepInEx core 확인 완료:"
    Write-Host $coreCheck
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

    $target = Get-LethalCompanyProfilePath

    Install-PackToProfile -PackRoot $packRoot -Target $target

    Write-Host ""
    Write-Host "Lethal Company Pack 세팅 완료."
    Write-Host ""
    Write-Host "Thunderstore에서 Lethal Company - Default 프로필로 Modded 실행하면 됩니다."
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
