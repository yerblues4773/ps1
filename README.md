# ps1

ThinkPad X13 Gen 3 の初期化後や環境構築時に、システム設定の最適化および主要アプリケーションのインストールを一括で自動化するための PowerShell スクリプトです。

## 概要

`tpx13gen3.ps1` を実行することで、以下のセットアップおよび最適化を自動で行います。

- **デバイス名の確定**: コンピュータ名を `TPX13GEN3` に変更
- **キーアサイン最適化**: Ctrl ⇔ CapsLock の入れ替え（レジストリ変更）
- **環境・基本ツール**: winget の自動最新化、PowerShell 7 の導入
- **不要サービスの除去**: OneDrive の完全停止＆アンインストール
- **アプリの一括導入**: Google Chrome, Google 日本語入力, 1Password, Adobe Acrobat Reader, Logi Options+, iCloud, pCloud Drive, Obsidian, iTunes, mpv.net, AutoHotkey v2, ThreeFingerDragOnWindows, .NET 10 Desktop Runtime 10.0.11, VS Code
- **ブラウザ・通知最適化**: Edgeのバックグラウンド動作抑制、Chromeの優先化、Focus Assistによる通知抑制
- **スタートアップ・操作最適化**: 不要なスタートアップの削除、マウスホイールのナチュラルスクロール化（Mac風）、電源設定の自動調整

## 使い方

PowerShell を **管理者として実行** し、以下のコマンドを順番に実行します。

```powershell
# 1. 実行ポリシーの変更（スクリプト実行を許可）
Set-ExecutionPolicy RemoteSigned -Scope Process

# 2. リポジトリのクローン（またはファイルの配置場所へ移動）
git clone https://github.com/yerblues4773/ps1.git
cd ps1

# 3. 変更を行わない起動テスト
.\tpx13gen3.ps1 -DryRun

# 4. スクリプトの実行（管理者として実行）
.\tpx13gen3.ps1
```

iCloud Drive はシンボリックリンクを作成せず、既定の `C:\Users\r.takahara\iCloudDrive` を使用します。三本指ドラッグはレジストリ変更を行わず、ThreeFingerDragOnWindows で設定します。
