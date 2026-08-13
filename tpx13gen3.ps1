set-executionpolicy remotesigned -Scope process
# =================================================================
#  tpx13gen3.ps1
#  ThinkPad X13 Gen 3 専用 完全自動セットアップ＆最適化スクリプト
# =================================================================

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  ThinkPad X13 Gen 3 コックピット完全覚醒プロセス  " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# -----------------------------------------------------------------
# 1. コンピュータ名（デバイス名）を 'TPX13GEN3' に確定
# -----------------------------------------------------------------
Write-Host "[1/9] デバイス名を 'TPX13GEN3' に変更中..." -ForegroundColor Yellow
$currentName = (Get-WmiObject Win32_ComputerSystem).Name
if ($currentName -ne "TPX13GEN3") {
    Rename-Computer -NewName "TPX13GEN3" -Force
    Write-Host " -> デバイス名を 'TPX13GEN3' に変更しました。(再起動後に反映)" -ForegroundColor Green
} else {
    Write-Host " -> すでにデバイス名は 'TPX13GEN3' です。" -ForegroundColor Green
}

# -----------------------------------------------------------------
# 2. Ctrl ⇔ CapsLock キーの入れ替え
# -----------------------------------------------------------------
Write-Host "[2/9] Ctrl ⇔ CapsLock キーの入れ替えを適用中..." -ForegroundColor Yellow
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layout"
$name = "Scancode Map"
$value = [byte[]](0x00,0x00,0x00,0x00, 0x00,0x00,0x00,0x00, 0x03,0x00,0x00,0x00, 0x1d,0x00,0x3a,0x00, 0x3a,0x00,0x1d,0x00, 0x00,0x00,0x00,0x00)

if (-not (Test-Path $registryPath)) { New-Item -Path $registryPath -Force | Out-Null }
New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType Binary -Force | Out-Null
Write-Host " -> キー入れ替えを適用しました。(再起動後に反映)" -ForegroundColor Green

# -----------------------------------------------------------------
# 3. winget の自動最新化
# -----------------------------------------------------------------
Write-Host "[3/9] winget をバックグラウンドで自動最新化中..." -ForegroundColor Yellow
$ProgressPreference = 'SilentlyContinue'
$wingetUrl = "https://aka.ms/getwinget"
$tempPath = "$env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

try {
    Invoke-WebRequest -Uri $wingetUrl -OutFile $tempPath -UseBasicParsing -ErrorAction Stop
    Add-AppxPackage -Path $tempPath -ErrorAction Stop
    Write-Host " -> winget の自動アップデートに成功しました。" -ForegroundColor Green
} catch {
    Write-Warning " -> winget 最新化スキップ（すでに最新かネットワーク未接続）"
} finally {
    $ProgressPreference = 'Continue'
}

# -----------------------------------------------------------------
# 4. PowerShell 7 のインストール
# -----------------------------------------------------------------
Write-Host "[4/9] PowerShell 7 をインストール中..." -ForegroundColor Yellow
winget install --id Microsoft.PowerShell --source winget --silent --accept-package-agreements --accept-source-agreements --force | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host " -> PowerShell 7 のインストールが完了しました。" -ForegroundColor Green
} else {
    Write-Warning " -> PowerShell 7 はすでに最新版が導入済みか、処理をスキップしました。"
}

# -----------------------------------------------------------------
# 5. 不要な標準アプリ（OneDrive・天気・各種標準ブロートウェア）の一括アンインストール
# -----------------------------------------------------------------
Write-Host "[5/9] 不要な標準アプリの一括削除・アンインストールを実行中..." -ForegroundColor Yellow

# 1) OneDrive の削除
Get-Process -Name "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force
$onedriveApp = Get-AppxPackage -Name "*OneDrive*" -ErrorAction SilentlyContinue
if ($onedriveApp) { Remove-AppxPackage -Package $onedriveApp.PackageFullName -ErrorAction SilentlyContinue }

$onedriveSetup = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
if (Test-Path $onedriveSetup) {
    Start-Process $onedriveSetup -ArgumentList "/uninstall" -Wait
}
Write-Host " -> OneDrive の完全削除完了" -ForegroundColor Green

# 2) 定番の不要標準アプリ（天気、ニュース、Xbox等）の削除リスト
$bloatwareApps = @(
    "*BingWeather*",       # 天気 (MSN Weather)
    "*BingNews*",          # ニュース
    "*GamingApp*",         # Xbox App
    "*XboxGamingOverlay*", # Xbox Game Bar
    "*WindowsFeedbackHub*",# フィードバック Hub
    "*GetHelp*",           # 問い合わせ
    "*WindowsMaps*",       # マップ
    "*MicrosoftSolitaireCollection*", # ソリティア
    "*YourPhone*"          # スマートフォン連携
)

foreach ($app in $bloatwareApps) {
    $target = Get-AppxPackage -Name $app -ErrorAction SilentlyContinue
    if ($target) {
        Remove-AppxPackage -Package $target.PackageFullName -ErrorAction SilentlyContinue
        Write-Host " -> 標準アプリを削除しました: $($target.Name)" -ForegroundColor Green
    }
}

# -----------------------------------------------------------------
# 6. winget による主要アプリの一括インストール（Logi Options+ 追加済み）
# -----------------------------------------------------------------
Write-Host "[6/9] アプリの一括インストールを開始します..." -ForegroundColor Yellow

$apps = @(
    @{ Name = "Google Chrome"; Id = "Google.Chrome"; Source = "winget" },
    @{ Name = "Google 日本語入力"; Id = "Google.JapaneseIME"; Source = "winget" },
    @{ Name = "1Password"; Id = "AgileBits.1Password"; Source = "winget" },
    @{ Name = "Adobe Acrobat Reader"; Id = "Adobe.Acrobat.Reader.64-bit"; Source = "winget" },
    @{ Name = "Logi Options+"; Id = "Logitech.LogiOptionsPlus"; Source = "winget" },
    @{ Name = "iCloud (Microsoft Store最新版)"; Id = "9PKDQDX07HP9"; Source = "msstore" },
    @{ Name = "pCloud Drive"; Id = "pCloudAG.pCloudDrive"; Source = "winget" },
    @{ Name = "Obsidian"; Id = "Obsidian.Obsidian"; Source = "winget" },
    @{ Name = "iTunes"; Id = "Apple.iTunes"; Source = "winget" },
    @{ Name = "mpv.net"; Id = "stefanbreunig.mpvnet"; Source = "winget" },
    @{ Name = "AutoHotkey"; Id = "AutoHotkey.AutoHotkey"; Source = "winget" },
    @{ Name = "VS Code"; Id = "Microsoft.VisualStudioCode"; Source = "winget" }
)

foreach ($app in $apps) {
    Write-Host " -> インストール/最新化チェック中: $($app.Name)" -ForegroundColor Cyan
    winget install --id $app.Id --source $app.Source --silent --accept-package-agreements --accept-source-agreements --force | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   => $($app.Name) の処理が完了しました。" -ForegroundColor Green
    } else {
        Write-Warning "   => $($app.Name) はすでに最新版が導入済みか、処理をスキップしました。"
    }
}

# -----------------------------------------------------------------
# 7. Chrome優先化（Edge無効化・規定のブラウザ/メール連携）
# -----------------------------------------------------------------
Write-Host "[7/9] Google Chrome をシステム優先ブラウザ・メールに設定中..." -ForegroundColor Yellow
$edgeKey1 = "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main"
$edgeKey2 = "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\TabPreloader"
if (-not (Test-Path $edgeKey1)) { New-Item -Path $edgeKey1 -Force | Out-Null }
if (-not (Test-Path $edgeKey2)) { New-Item -Path $edgeKey2 -Force | Out-Null }
Set-ItemProperty -Path $edgeKey1 -Name "AllowPrelaunch" -Value 0 -Force | Out-Null
Set-ItemProperty -Path $edgeKey2 -Name "PreventTabPreloading" -Value 1 -Force | Out-Null

$userChoicePath = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations"
@("http", "https", "mailto") | ForEach-Object {
    $path = "$userChoicePath\$_"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name "ProgId" -Value "ChromeHTML" -Force | Out-Null
}
Write-Host " -> Edgeの背景起動をブロックし、Chrome優先を設定しました。" -ForegroundColor Green

# -----------------------------------------------------------------
# 8. 通知制限（Focus Assist有効化）
# -----------------------------------------------------------------
Write-Host "[8/9] システム通知の抑制設定を適用中..." -ForegroundColor Yellow
$notifPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\PushNotifications"
if (-not (Test-Path $notifPath)) { New-Item -Path $notifPath -Force | Out-Null }
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\QuietHours" -Name "UserNoDisturbMode" -Value 1 -Force | Out-Null
Write-Host " -> 不要な通知バナーを抑制しました。" -ForegroundColor Green

# -----------------------------------------------------------------
# 9. 不要なスタートアップの完全掃除＆環境最適化
# -----------------------------------------------------------------
Write-Host "[9/9] 不要なスタートアップアプリの停止＆環境最適化中..." -ForegroundColor Yellow

$targetApps = @("OneDrive", "Xbox", "PowerAutomate", "Teams", "ms-teams", "ToDo", "Copilot", "Cortana", "Edge")

$runKeys = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
)
foreach ($key in $runKeys) {
    if (Test-Path $key) {
        $props = Get-ItemProperty -Path $key
        foreach ($prop in $props.PSObject.Properties) {
            foreach ($target in $targetApps) {
                if ($prop.Name -like "*$target*" -or $prop.Value -like "*$target*") {
                    Remove-ItemProperty -Path $key -Name $prop.Name -ErrorAction SilentlyContinue
                    Write-Host " -> スタートアップレジストリから削除: $($prop.Name)" -ForegroundColor Green
                }
            }
        }
    }
}

$startupFolders = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:PROGRAMDATA\Microsoft\Windows\Start Menu\Programs\Startup"
)
foreach ($folder in $startupFolders) {
    if (Test-Path $folder) {
        Get-ChildItem -Path $folder -Recurse | ForEach-Object {
            foreach ($target in $targetApps) {
                if ($_.Name -like "*$target*") {
                    Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
                    Write-Host " -> スタートアップフォルダから削除: $($_.Name)" -ForegroundColor Green
                }
            }
        }
    }
}

# Mac風スクロール＆電源設定
$hids = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Enum\HID" -Recurse
foreach ($hid in $hids) {
    if ($hid.Name -like "*Device Parameters*") {
        $path = $hid.Name -replace "HKEY_LOCAL_MACHINE", "HKLM:"
        if (Get-ItemProperty -Path $path -Name "FlipFlopWheel" -ErrorAction SilentlyContinue) {
            Set-ItemProperty -Path $path -Name "FlipFlopWheel" -Value 1 -Force
        }
    }
}
powercfg /change monitor-timeout-ac 15
powercfg /change monitor-timeout-dc 5
powercfg /change standby-timeout-ac 30
powercfg /change standby-timeout-dc 15

Write-Host "==================================================" -ForegroundColor Green
Write-Host "   すべてのクリーンアップ・セットアップが完了！   " -ForegroundColor Green
Write-Host "   変更を完全に反映させるため、PCを再起動してください。 " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Green
