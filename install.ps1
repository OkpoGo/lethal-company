$ErrorActionPreference = "Stop"

$RepoRawBase = "https://raw.githubusercontent.com/OkpoGo/lethal-company/main"

$ThunderstoreInstallerUrl = "$RepoRawBase/Thunderstore%20Mod%20Manager%20-%20Installer.exe"
$PackZipUrl = "$RepoRawBase/lethal-company-pack.zip"

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

    $InstallBat = Get-ChildItem -Path $ExtractPath -Filter "install.bat" -Recurse | Select-Object -First 1

    if (-not $InstallBat) {
        Write-Host "[오류] 압축 파일 안에서 install.bat을 찾지 못했습니다." -ForegroundColor Red
        Write-Host ""
        Write-Host "lethal-company-pack.zip 안에 install.bat이 들어 있어야 합니다."
        Pause-Menu
        return
    }

    Write-Host "install.bat 실행:"
    Write-Host $InstallBat.FullName
    Write-Host ""

    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$($InstallBat.FullName)`"" -WorkingDirectory $InstallBat.DirectoryName -Wait

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
