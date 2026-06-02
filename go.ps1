$url = 'https://raw.githubusercontent.com/OkpoGo/lethal-company/e189194526eb7fed108d819cd05e5323ea32523e/install.ps1'
$dir = Join-Path $env:TEMP 'okpogo-lethal-company'
$path = Join-Path $dir 'install.ps1'

New-Item -ItemType Directory -Path $dir -Force | Out-Null
Invoke-WebRequest -Uri $url -OutFile $path
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $path
