$ErrorActionPreference = "Stop"

$InstallerSelfUrl = "https://raw.githubusercontent.com/OkpoGo/lethal-company/main/install.ps1?v=20260602-checklist"
$InstallerRawBase = "https://raw.githubusercontent.com/OkpoGo/lethal-company/main"
$DataFolderRawBase = "https://raw.githubusercontent.com/OkpoGo/lethal-company/af022681fb77502cd3c3d9daca6681f96df39230"
$DownloadVersion = "20260602-checklist"

$ThunderstoreInstallerUrl = "$InstallerRawBase/Thunderstore%20Mod%20Manager%20-%20Installer.exe?v=$DownloadVersion"
$DataFolderZipParts = @(
    "datafolder-parts/lethal-company-datafolder.zip.001",
    "datafolder-parts/lethal-company-datafolder.zip.002",
    "datafolder-parts/lethal-company-datafolder.zip.003",
    "datafolder-parts/lethal-company-datafolder.zip.004"
)
$ExpectedDataFolderZipBytes = 174223888
$ExpectedDataFolderZipSha256 = "06379147C9FE092A2B06DED11AB2F89CC997234E0ABBF06EEC31105E3E2CAE0F"
$BackupKeepCount = 3

$TempRoot = Join-Path $env:TEMP "okpogo-lethal-company"
$InstallerPath = Join-Path $TempRoot "Thunderstore Mod Manager - Installer.exe"
$Script:DownloadedInstallerPath = Join-Path $TempRoot "install.ps1"
$ZipPath = Join-Path $TempRoot "lethal-company-datafolder.zip"
$ExtractPath = Join-Path $TempRoot "lethal-company-datafolder"
$Script:LogPath = $null
$Script:TranscriptStarted = $false

function Ensure-TempFolder {
    if (-not (Test-Path $TempRoot)) {
        New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
    }
}

function Start-InstallLog {
    Ensure-TempFolder
    $Script:LogPath = Join-Path $TempRoot ("install-log_{0}.txt" -f (Get-Date -Format "yyyy-MM-dd_HH-mm-ss"))

    try {
        Start-Transcript -Path $Script:LogPath -Force | Out-Null
        $Script:TranscriptStarted = $true
        Write-Host "설치 로그:"
        Write-Host $Script:LogPath
    } catch {
        Write-Host "[경고] 설치 로그를 시작하지 못했음: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Stop-InstallLog {
    if ($Script:TranscriptStarted) {
        try {
            Stop-Transcript | Out-Null
        } catch {
        }
    }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Administrator {
    if (Test-IsAdministrator) {
        return
    }

    Ensure-TempFolder

    $scriptPath = $PSCommandPath

    if ([string]::IsNullOrWhiteSpace($scriptPath) -or -not (Test-Path $scriptPath)) {
        Write-Host "설치 스크립트 파일 저장 중..."
        Invoke-WebRequest -Uri $InstallerSelfUrl -OutFile $Script:DownloadedInstallerPath
        $scriptPath = $Script:DownloadedInstallerPath
    }

    Write-Host ""
    Write-Host "관리자 권한 PowerShell로 다시 실행함..."
    Write-Host "UAC 창이 뜨면 예를 누르면 됨."

    $argumentList = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    Start-Process -FilePath "powershell.exe" -ArgumentList $argumentList -Verb RunAs
    exit
}

function Pause-Menu {
    Write-Host ""
    Write-Host "계속하려면 아무 키나 누르셈..."
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
        Write-Host "방향키 ↑ ↓ 로 선택하고 Enter 누르면 됨."
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

function Invoke-RobocopyChecked {
    param (
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        throw "복사할 폴더가 없음: $Source"
    }

    if (-not (Test-Path $Destination)) {
        New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    }

    & robocopy $Source $Destination /E /R:2 /W:1 | Out-Host

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
        Copy-Item -LiteralPath $Source -Destination $Destination -Force
    }
}

function Get-ThunderstoreDataFolderPath {
    return (Join-Path $env:APPDATA "Thunderstore Mod Manager\DataFolder")
}

function Get-LethalCompanyDataFolderPath {
    return (Join-Path (Get-ThunderstoreDataFolderPath) "LethalCompany")
}

function Get-DefaultProfilePath {
    return (Join-Path (Get-LethalCompanyDataFolderPath) "profiles\Default")
}

function Get-BackupFolders {
    $dataFolderPath = Get-ThunderstoreDataFolderPath

    if (-not (Test-Path $dataFolderPath)) {
        return @()
    }

    return @(
        Get-ChildItem -LiteralPath $dataFolderPath -Directory -Filter "backup_LethalCompany_*" |
            Sort-Object LastWriteTime -Descending
    )
}

function Assert-SafeLethalCompanyTarget {
    param (
        [string]$DataFolderPath,
        [string]$TargetPath
    )

    $dataFolderFullPath = [System.IO.Path]::GetFullPath($DataFolderPath)
    $targetFullPath = [System.IO.Path]::GetFullPath($TargetPath)
    $expectedPrefix = $dataFolderFullPath.TrimEnd("\") + "\"

    if ((Split-Path -Path $targetFullPath -Leaf) -ne "LethalCompany") {
        throw "삭제 대상 폴더 이름이 LethalCompany가 아님: $targetFullPath"
    }

    if (-not $targetFullPath.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "삭제 대상 경로가 DataFolder 밖임: $targetFullPath"
    }
}

function Remove-OldLethalCompanyBackups {
    param (
        [int]$Keep = $BackupKeepCount
    )

    $backups = @(Get-BackupFolders)

    if ($backups.Count -le $Keep) {
        return
    }

    Write-Host ""
    Write-Host "오래된 백업 정리 중..."

    $backups |
        Select-Object -Skip $Keep |
        ForEach-Object {
            Write-Host "삭제: $($_.FullName)"
            Remove-Item -LiteralPath $_.FullName -Recurse -Force
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
                $pathMatch = [regex]::Match($line, '^\s*"path"\s+"(?<path>[^"]+)"')
                $legacyMatch = [regex]::Match($line, '^\s*"\d+"\s+"(?<legacy>[^"]+)"')

                if ($pathMatch.Success) {
                    $paths += $pathMatch.Groups["path"].Value.Replace("\\", "\")
                } elseif ($legacyMatch.Success) {
                    $paths += $legacyMatch.Groups["legacy"].Value.Replace("\\", "\")
                }
            }
        }
    }

    return $paths | Sort-Object -Unique
}

function Get-LethalCompanyGamePath {
    param (
        [switch]$NoPrompt
    )

    foreach ($library in Get-SteamLibraryPaths) {
        $candidate = Join-Path $library "steamapps\common\Lethal Company"

        if (Test-Path (Join-Path $candidate "Lethal Company.exe")) {
            return $candidate
        }
    }

    if ($NoPrompt) {
        return $null
    }

    $manualPath = Read-Host "Lethal Company 게임 설치 폴더를 못 찾음. 직접 경로 붙여넣거나 Enter 누르면 건너뜀"

    if ([string]::IsNullOrWhiteSpace($manualPath)) {
        return $null
    }

    return $manualPath.Trim('"')
}

function Set-DoorstopTargetAssembly {
    param (
        [string]$ConfigPath,
        [string]$TargetAssembly
    )

    $targetAssemblyForConfig = $TargetAssembly.Replace("\", "/")

    if (Test-Path $ConfigPath) {
        $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8

        if ([regex]::IsMatch($config, "(?m)^target_assembly\s*=.*$")) {
            $config = [regex]::Replace($config, "(?m)^target_assembly\s*=.*$", "target_assembly=$targetAssemblyForConfig")
        } else {
            $config = $config.TrimEnd() + "`r`n" + "target_assembly=$targetAssemblyForConfig" + "`r`n"
        }
    } else {
        $config = @"
# General options for Unity Doorstop
[General]

enabled = true
target_assembly=$targetAssemblyForConfig
redirect_output_log = false
boot_config_override =
ignore_disable_switch = false

[UnityMono]
dll_search_path_override =
debug_enabled = false
debug_address = 127.0.0.1:10000
debug_suspend = false
"@
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($ConfigPath, $config, $utf8NoBom)
}

function Get-DoorstopTargetAssembly {
    param (
        [string]$ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        return $null
    }

    $match = [regex]::Match((Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8), "(?m)^target_assembly\s*=\s*(?<path>.+?)\s*$")

    if ($match.Success) {
        return $match.Groups["path"].Value.Trim()
    }

    return $null
}

function Install-DoorstopToGameFolder {
    param (
        [string]$PackRoot,
        [string]$ProfilePath
    )

    $gamePath = Get-LethalCompanyGamePath

    if (-not $gamePath) {
        Write-Host "[경고] 게임 설치 폴더를 못 찾아서 Doorstop 파일 복사 건너뜀." -ForegroundColor Yellow
        Write-Host "이 경우 Thunderstore에서 Modded 눌러도 모드 적용 안 될 수 있음."
        return
    }

    Write-Host ""
    Write-Host "게임 폴더 Doorstop 파일 복사 중..."
    Write-Host $gamePath

    foreach ($fileName in @("winhttp.dll", ".doorstop_version")) {
        Copy-IfExists -Source (Join-Path $PackRoot $fileName) -Destination $gamePath
    }

    $configSource = Join-Path $PackRoot "doorstop_config.ini"
    $configDestination = Join-Path $gamePath "doorstop_config.ini"

    Copy-IfExists -Source $configSource -Destination $configDestination

    $targetAssembly = Join-Path $ProfilePath "BepInEx\core\BepInEx.Preloader.dll"

    if (-not (Test-Path $targetAssembly)) {
        throw "Doorstop 대상 파일을 못 찾음: $targetAssembly"
    }

    Set-DoorstopTargetAssembly -ConfigPath $configDestination -TargetAssembly $targetAssembly

    Write-Host ""
    Write-Host "Doorstop 대상 프로필:"
    Write-Host $ProfilePath
    Write-Host "Doorstop 대상 파일:"
    Write-Host $targetAssembly
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
    Write-Host "설치 프로그램 실행함. 설치 창 뜨면 설치 끝내면 됨."

    Start-Process -FilePath $InstallerPath -Wait

    Write-Host ""
    Write-Host "Thunderstore 설치 단계 완료."
    Write-Host ""
    Write-Host "다음 순서:"
    Write-Host "1. Thunderstore 실행"
    Write-Host "2. Lethal Company 선택"
    Write-Host "3. Default 프로필 생성"
    Write-Host "4. 다시 이 스크립트에서 2번 실행"
    Pause-Menu
}

function Download-DataFolderZip {
    Ensure-TempFolder

    if (Test-Path $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    Write-Host "DataFolder 압축 조각 다운로드 중..."

    $partPaths = @()

    foreach ($partRelativePath in $DataFolderZipParts) {
        $partName = Split-Path -Path $partRelativePath -Leaf
        $partUrl = "$DataFolderRawBase/$partRelativePath"
        $partPath = Join-Path $TempRoot $partName

        if (Test-Path $partPath) {
            Remove-Item -LiteralPath $partPath -Force
        }

        Write-Host $partName
        Invoke-WebRequest -Uri $partUrl -OutFile $partPath
        $partPaths += $partPath
    }

    Write-Host ""
    Write-Host "압축 조각 합치는 중..."

    $outputStream = [System.IO.File]::Open($ZipPath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write)

    try {
        foreach ($partPath in $partPaths) {
            $inputStream = [System.IO.File]::OpenRead($partPath)

            try {
                $inputStream.CopyTo($outputStream)
            } finally {
                $inputStream.Close()
            }
        }
    } finally {
        $outputStream.Close()
    }

    $actualBytes = (Get-Item -LiteralPath $ZipPath).Length

    if ($actualBytes -ne $ExpectedDataFolderZipBytes) {
        throw "압축 파일 크기가 맞지 않음. 예상: $ExpectedDataFolderZipBytes, 실제: $actualBytes"
    }

    $actualHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash

    if ($actualHash -ne $ExpectedDataFolderZipSha256) {
        throw "압축 파일 해시가 맞지 않음. 다운로드가 깨졌을 수 있음."
    }

    Write-Host "압축 파일 확인 완료:"
    Write-Host $ZipPath
}

function Get-ExtractedLethalCompanySource {
    $directPath = Join-Path $ExtractPath "LethalCompany"

    if (Test-Path (Join-Path $directPath "profiles\Default")) {
        return $directPath
    }

    $foundPath = Get-ChildItem -Path $ExtractPath -Directory -Recurse |
        Where-Object {
            $_.Name -eq "LethalCompany" -and
            (Test-Path (Join-Path $_.FullName "profiles\Default"))
        } |
        Select-Object -ExpandProperty FullName -First 1

    if (-not $foundPath) {
        throw "압축 파일 안에서 LethalCompany DataFolder를 못 찾음."
    }

    return $foundPath
}

function Replace-LethalCompanyDataFolder {
    param (
        [string]$SourceLethalCompany
    )

    $dataFolderPath = Get-ThunderstoreDataFolderPath
    $targetLethalCompany = Get-LethalCompanyDataFolderPath
    $backupPath = Join-Path $dataFolderPath ("backup_LethalCompany_{0}" -f (Get-Date -Format "yyyy-MM-dd_HH-mm-ss"))

    Assert-SafeLethalCompanyTarget -DataFolderPath $dataFolderPath -TargetPath $targetLethalCompany
    New-Item -ItemType Directory -Path $dataFolderPath -Force | Out-Null

    Write-Host ""
    Write-Host "Thunderstore DataFolder:"
    Write-Host $dataFolderPath

    if (Test-Path $targetLethalCompany) {
        Write-Host ""
        Write-Host "기존 LethalCompany 폴더 백업 중..."
        Write-Host $backupPath
        Invoke-RobocopyChecked -Source $targetLethalCompany -Destination $backupPath

        Write-Host ""
        Write-Host "기존 LethalCompany 폴더 삭제 중..."
        Remove-Item -LiteralPath $targetLethalCompany -Recurse -Force
    }

    Write-Host ""
    Write-Host "새 LethalCompany DataFolder 복사 중..."
    Invoke-RobocopyChecked -Source $SourceLethalCompany -Destination $targetLethalCompany
    Remove-OldLethalCompanyBackups

    return $targetLethalCompany
}

function Install-LethalCompanyPack {
    Clear-Host
    Write-Host "=========================================="
    Write-Host "  2. Lethal Company DataFolder 다운로드 및 세팅"
    Write-Host "=========================================="
    Write-Host ""

    Ensure-TempFolder

    if (Test-Path $ExtractPath) {
        Remove-Item -LiteralPath $ExtractPath -Recurse -Force
    }

    if (Test-Path $ZipPath) {
        Remove-Item -LiteralPath $ZipPath -Force
    }

    Download-DataFolderZip

    Write-Host "압축 해제 중..."
    Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

    Write-Host ""
    Write-Host "압축 해제 완료:"
    Write-Host $ExtractPath
    Write-Host ""

    $sourceLethalCompany = Get-ExtractedLethalCompanySource
    $targetLethalCompany = Replace-LethalCompanyDataFolder -SourceLethalCompany $sourceLethalCompany
    $doorstopProfile = Join-Path $targetLethalCompany "profiles\Default"

    if (-not (Test-Path (Join-Path $doorstopProfile "BepInEx\core\BepInEx.Preloader.dll"))) {
        throw "Default 프로필의 BepInEx Preloader를 못 찾음: $doorstopProfile"
    }

    Install-DoorstopToGameFolder -PackRoot $doorstopProfile -ProfilePath $doorstopProfile

    Write-Host ""
    Write-Host "Lethal Company DataFolder 세팅 완료."
    Write-Host ""
    Write-Host "Thunderstore에서 Lethal Company - Default 프로필로 Modded 실행하면 됨."
    Pause-Menu
}

function Write-CheckResult {
    param (
        [string]$Label,
        [bool]$Ok,
        [string]$Detail = ""
    )

    if ($Ok) {
        Write-Host "[OK] $Label" -ForegroundColor Green
    } else {
        Write-Host "[NO] $Label" -ForegroundColor Red
    }

    if (-not [string]::IsNullOrWhiteSpace($Detail)) {
        Write-Host "     $Detail"
    }
}

function Test-InstallStatus {
    Clear-Host
    Write-Host "=========================================="
    Write-Host "  설치 상태 확인"
    Write-Host "=========================================="
    Write-Host ""

    $dataFolderPath = Get-ThunderstoreDataFolderPath
    $lethalCompanyPath = Get-LethalCompanyDataFolderPath
    $profilePath = Get-DefaultProfilePath
    $preloaderPath = Join-Path $profilePath "BepInEx\core\BepInEx.Preloader.dll"
    $profileConfigPath = Join-Path $profilePath "BepInEx\config\BepInEx.cfg"
    $logOutputPath = Join-Path $profilePath "BepInEx\LogOutput.log"
    $profileWinhttpPath = Join-Path $profilePath "winhttp.dll"
    $profileDoorstopPath = Join-Path $profilePath "doorstop_config.ini"
    $gamePath = Get-LethalCompanyGamePath -NoPrompt
    $expectedTarget = $preloaderPath.Replace("\", "/")

    Write-CheckResult "Thunderstore DataFolder" (Test-Path $dataFolderPath) $dataFolderPath
    Write-CheckResult "LethalCompany DataFolder" (Test-Path $lethalCompanyPath) $lethalCompanyPath
    Write-CheckResult "Default 프로필" (Test-Path $profilePath) $profilePath
    Write-CheckResult "BepInEx Preloader" (Test-Path $preloaderPath) $preloaderPath
    Write-CheckResult "BepInEx 설정" (Test-Path $profileConfigPath) $profileConfigPath
    Write-CheckResult "프로필 winhttp.dll" (Test-Path $profileWinhttpPath) $profileWinhttpPath
    Write-CheckResult "프로필 doorstop_config.ini" (Test-Path $profileDoorstopPath) $profileDoorstopPath

    if (Test-Path $logOutputPath) {
        $logInfo = Get-Item -LiteralPath $logOutputPath
        Write-CheckResult "BepInEx 로그" $true "$logOutputPath / 마지막 변경: $($logInfo.LastWriteTime)"
    } else {
        Write-CheckResult "BepInEx 로그" $false $logOutputPath
    }

    if ($gamePath) {
        $gameWinhttp = Join-Path $gamePath "winhttp.dll"
        $gameDoorstop = Join-Path $gamePath "doorstop_config.ini"
        $gameDoorstopTarget = Get-DoorstopTargetAssembly -ConfigPath $gameDoorstop
        $normalizedTarget = if ($gameDoorstopTarget) { $gameDoorstopTarget.Replace("\", "/") } else { "" }

        Write-CheckResult "Steam 게임 폴더" $true $gamePath
        Write-CheckResult "게임 폴더 winhttp.dll" (Test-Path $gameWinhttp) $gameWinhttp
        Write-CheckResult "게임 폴더 doorstop_config.ini" (Test-Path $gameDoorstop) $gameDoorstop
        Write-CheckResult "Doorstop target_assembly" ($normalizedTarget -eq $expectedTarget) $normalizedTarget
    } else {
        Write-CheckResult "Steam 게임 폴더" $false "자동으로 못 찾음"
    }

    $backups = @(Get-BackupFolders)
    Write-CheckResult "백업 폴더" ($backups.Count -gt 0) ("개수: {0}" -f $backups.Count)

    if ($Script:LogPath) {
        Write-Host ""
        Write-Host "이번 실행 로그:"
        Write-Host $Script:LogPath
    }

    Pause-Menu
}

function Restore-LethalCompanyBackup {
    Clear-Host
    Write-Host "=========================================="
    Write-Host "  백업 복구"
    Write-Host "=========================================="
    Write-Host ""

    $backups = @(Get-BackupFolders)

    if ($backups.Count -eq 0) {
        Write-Host "복구할 백업이 없음." -ForegroundColor Yellow
        Pause-Menu
        return
    }

    Write-Host "복구할 백업 선택하면 됨. Enter 누르면 취소."
    Write-Host ""

    for ($i = 0; $i -lt $backups.Count; $i++) {
        Write-Host "$($i + 1). $($backups[$i].Name) / $($backups[$i].LastWriteTime)"
    }

    Write-Host ""
    $choice = Read-Host "번호 입력"

    if ([string]::IsNullOrWhiteSpace($choice)) {
        return
    }

    $selected = 0

    if (-not ([int]::TryParse($choice, [ref]$selected)) -or $selected -lt 1 -or $selected -gt $backups.Count) {
        Write-Host "잘못된 선택임: $choice" -ForegroundColor Red
        Pause-Menu
        return
    }

    $selectedBackup = $backups[$selected - 1]
    $dataFolderPath = Get-ThunderstoreDataFolderPath
    $targetLethalCompany = Get-LethalCompanyDataFolderPath
    $currentBackupPath = Join-Path $dataFolderPath ("backup_LethalCompany_before_restore_{0}" -f (Get-Date -Format "yyyy-MM-dd_HH-mm-ss"))

    Assert-SafeLethalCompanyTarget -DataFolderPath $dataFolderPath -TargetPath $targetLethalCompany

    if (Test-Path $targetLethalCompany) {
        Write-Host ""
        Write-Host "현재 LethalCompany 폴더 임시 백업 중..."
        Write-Host $currentBackupPath
        Invoke-RobocopyChecked -Source $targetLethalCompany -Destination $currentBackupPath

        Write-Host ""
        Write-Host "현재 LethalCompany 폴더 삭제 중..."
        Remove-Item -LiteralPath $targetLethalCompany -Recurse -Force
    }

    Write-Host ""
    Write-Host "선택한 백업 복구 중..."
    Write-Host $selectedBackup.FullName
    Invoke-RobocopyChecked -Source $selectedBackup.FullName -Destination $targetLethalCompany

    $doorstopProfile = Join-Path $targetLethalCompany "profiles\Default"

    if (Test-Path (Join-Path $doorstopProfile "BepInEx\core\BepInEx.Preloader.dll")) {
        Install-DoorstopToGameFolder -PackRoot $doorstopProfile -ProfilePath $doorstopProfile
    }

    Write-Host ""
    Write-Host "백업 복구 완료."
    Pause-Menu
}

Start-InstallLog

try {
    Ensure-Administrator

    while ($true) {
        $choice = Show-Menu @(
            "1. Thunderstore Mod Manager exe 파일부터 설치",
            "2. Lethal Company DataFolder 다운로드 후 자동 세팅",
            "3. 설치 상태 확인",
            "4. 이전 백업으로 복구",
            "5. 종료"
        )

        switch ($choice) {
            0 {
                Install-Thunderstore
            }
            1 {
                Install-LethalCompanyPack
            }
            2 {
                Test-InstallStatus
            }
            3 {
                Restore-LethalCompanyBackup
            }
            4 {
                Clear-Host
                Write-Host "종료함."
                break
            }
        }

        if ($choice -eq 4) {
            break
        }
    }
} catch {
    Write-Host ""
    Write-Host "[오류] $($_.Exception.Message)" -ForegroundColor Red

    if ($Script:LogPath) {
        Write-Host ""
        Write-Host "로그 파일:"
        Write-Host $Script:LogPath
    }

    Pause-Menu
    exit 1
} finally {
    Stop-InstallLog
}
