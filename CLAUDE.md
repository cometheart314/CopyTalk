# CopyTalk

## アプリ概要
アプリケーション名 ClipVoice
クリップボードのテキストを読み上げるユーティリティー。　様々なアプリの中でcmd+Cキーの２回連打で選択テキストを読み上げます。Google TextToSpeechのAPIを登録するとAIによる高品質な読み上げを実現できます。APIを登録しなくてもAppleシステムの読み上げ機能で読み上げできますが、Google TextToSpeech APIを登録してAIで読み上げたほうが圧倒的に高品質な読み上げを行えます。Google TextToSpeech は月間100万文字までが無料です。

## 技術スタック
- Swift / AppKit
- macOS 13+
- Xcode 126.4

## プロジェクト構成
- CopyTalk.xcodeproj


## 開発方針
Claude-code と Xcode のプロジェクト名は、CopyTalkだか、アプリケーション名は ClipVoice

 | プロジェクトファイル          | `CopyTalk.xcodeproj`      |
| ------------------- | ------------------------- |
| ソースディレクトリ           | `CopyTalk/`               |
| Entitlements ファイル名  | `CopyTalk.entitlements`   |
| アイコンファイル名           | `CopyTalkAppIcon.icon`    |
| pbxproj 内のコメント/パス参照 | グループ名、ターゲットコメント、ビルド設定のパス等 |
| バンドルID              | `jp.co.artman21.copytalk` |
| Keychain サービス名      | `jp.co.artman21.copytalk` |
