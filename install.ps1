$ErrorActionPreference = "Stop"

$InstallerRawBase = "https://raw.githubusercontent.com/OkpoGo/lethal-company/main"
$DataFolderRawBase = "https://raw.githubusercontent.com/OkpoGo/lethal-company/af022681fb77502cd3c3d9daca6681f96df39230"
$DownloadVersion = "20260602-datafolder-zip"

$ThunderstoreInstallerUrl = "$InstallerRawBase/Thunderstore%20Mod%20Manager%20-%20Installer.exe?v=$DownloadVersion"
$DataFolderZipParts = @(
    "datafolder-parts/lethal-company-datafolder.zip.001",
    "datafolder-parts/lethal-company-datafolder.zip.002",
    "datafolder-parts/lethal-company-datafolder.zip.003",
    "datafolder-parts/lethal-company-datafolder.zip.004"
)
$ExpectedDataFolderZipBytes = 174223888
$ExpectedDataFolderZipSha256 = "06379147C9FE092A2B06DED11AB2F89CC997234E0ABBF06EEC31105E3E2CAE0F"

$TempRoot = Join-Path $env:TEMP "okpogo-lethal-company"
$InstallerPath = Join-Path $TempRoot "Thunderstore Mod Manager - Installer.exe"
$ZipPath = Join-Path $TempRoot "lethal-company-datafolder.zip"
$ExtractPath = Join-Path $TempRoot "lethal-company-datafolder"

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

    $profiles = @(
        $profiles |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Sort-Object -Unique
    )

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
        Copy-Item -Path $Source -Destination $Destination -Force
    }
}

function Remove-ProfileItemIfExists {
    param (
        [string]$ProfilePath,
        [string]$ItemName
    )

    $profileFullPath = [System.IO.Path]::GetFullPath($ProfilePath)
    $itemPath = Join-Path $profileFullPath $ItemName
    $itemFullPath = [System.IO.Path]::GetFullPath($itemPath)
    $profilePrefix = $profileFullPath.TrimEnd("\") + "\"

    if (-not $itemFullPath.StartsWith($profilePrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "삭제 대상 경로가 프로필 밖입니다: $itemFullPath"
    }

    if (Test-Path $itemFullPath) {
        Remove-Item -LiteralPath $itemFullPath -Recurse -Force
    }
}

function Clear-ManagedProfileFiles {
    param (
        [string]$ProfilePath
    )

    Write-Host ""
    Write-Host "기존 모드 파일 정리 중..."

    foreach ($itemName in @("BepInEx", "_state", "mods.yml", "doorstop_config.ini", ".doorstop_version", "winhttp.dll")) {
        Remove-ProfileItemIfExists -ProfilePath $ProfilePath -ItemName $itemName
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

function Get-PreferredDoorstopProfile {
    param (
        [string[]]$Profiles
    )

    $defaultProfile = $Profiles |
        Where-Object { (Split-Path -Path $_ -Leaf) -eq "Default" } |
        Select-Object -First 1

    if ($defaultProfile) {
        return $defaultProfile
    }

    return $Profiles | Select-Object -First 1
}

function Install-DoorstopToGameFolder {
    param (
        [string]$PackRoot,
        [string]$ProfilePath
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

    foreach ($fileName in @("winhttp.dll", ".doorstop_version")) {
        $source = Join-Path $PackRoot $fileName

        if (Test-Path $source) {
            Copy-Item -Path $source -Destination $gamePath -Force
        }
    }

    $configSource = Join-Path $PackRoot "doorstop_config.ini"
    $configDestination = Join-Path $gamePath "doorstop_config.ini"

    if (Test-Path $configSource) {
        Copy-Item -Path $configSource -Destination $configDestination -Force
    }

    $targetAssembly = Join-Path $ProfilePath "BepInEx\core\BepInEx.Preloader.dll"

    if (-not (Test-Path $targetAssembly)) {
        throw "Doorstop 대상 파일을 찾지 못했습니다. 확인 경로: $targetAssembly"
    }

    Set-DoorstopTargetAssembly -ConfigPath $configDestination -TargetAssembly $targetAssembly

    Write-Host ""
    Write-Host "Doorstop 대상 프로필:"
    Write-Host $ProfilePath
    Write-Host "Doorstop 대상 파일:"
    Write-Host $targetAssembly
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

    Clear-ManagedProfileFiles -ProfilePath $Target

    Write-Host ""
    Write-Host "프로필 전체 복사 중..."
    Invoke-RobocopyChecked -Source $PackRoot -Destination $Target

    $coreCheck = Join-Path $targetBepInEx "core\BepInEx.dll"
    $preloaderCheck = Join-Path $targetBepInEx "core\BepInEx.Preloader.dll"

    if (-not (Test-Path $coreCheck)) {
        throw "BepInEx\core가 복사되지 않았습니다. 확인 경로: $coreCheck"
    }

    if (-not (Test-Path $preloaderCheck)) {
        throw "BepInEx Preloader가 복사되지 않았습니다. 확인 경로: $preloaderCheck"
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

function Get-ThunderstoreDataFolderPath {
    return (Join-Path $env:APPDATA "Thunderstore Mod Manager\DataFolder")
}

function Get-LethalCompanyDataFolderPath {
    return (Join-Path (Get-ThunderstoreDataFolderPath) "LethalCompany")
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
        throw "압축 파일 크기가 맞지 않습니다. 예상: $ExpectedDataFolderZipBytes, 실제: $actualBytes"
    }

    $actualHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash

    if ($actualHash -ne $ExpectedDataFolderZipSha256) {
        throw "압축 파일 해시가 맞지 않습니다. 다운로드가 깨졌을 수 있습니다."
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
        throw "압축 파일 안에서 LethalCompany DataFolder를 찾지 못했습니다."
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
    $dataFolderFullPath = [System.IO.Path]::GetFullPath($dataFolderPath)
    $targetFullPath = [System.IO.Path]::GetFullPath($targetLethalCompany)
    $expectedPrefix = $dataFolderFullPath.TrimEnd("\") + "\"

    if ((Split-Path -Path $targetFullPath -Leaf) -ne "LethalCompany") {
        throw "삭제 대상 폴더 이름이 LethalCompany가 아닙니다: $targetFullPath"
    }

    if (-not $targetFullPath.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "삭제 대상 경로가 DataFolder 밖입니다: $targetFullPath"
    }

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
        Remove-Item $ExtractPath -Recurse -Force
    }

    if (Test-Path $ZipPath) {
        Remove-Item $ZipPath -Force
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
        throw "Default 프로필의 BepInEx Preloader를 찾지 못했습니다. 확인 경로: $doorstopProfile"
    }

    Install-DoorstopToGameFolder -PackRoot $doorstopProfile -ProfilePath $doorstopProfile

    Write-Host ""
    Write-Host "Lethal Company DataFolder 세팅 완료."
    Write-Host ""
    Write-Host "Thunderstore에서 Lethal Company - Default 프로필로 Modded 실행하면 됩니다."
    Pause-Menu
}

while ($true) {
    $choice = Show-Menu @(
        "1. Thunderstore Mod Manager exe 파일부터 설치",
        "2. Lethal Company DataFolder 다운로드 후 자동 세팅",
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
