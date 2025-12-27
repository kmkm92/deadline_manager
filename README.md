# Deadline Manager 仕様書

## 概要
Deadline Managerは、タスクの期限管理に特化したシンプルで使いやすいTODOアプリケーションです。
Flutterで構築されており、直感的なUIでタスクの作成、編集、削除、通知設定を行うことができます。特に「期限」に対する意識を高めるため、残り時間の表示や通知機能に重点を置いています。

## スクリーンショット
(ここにアプリのスクリーンショットを配置してください)

## 主な機能

### 1. タスク管理機能
*   **新規タスク作成**:
    *   タスク名、期限（日付・時間）、通知設定、繰り返し設定を入力可能。
*   **タスク一覧表示**:
    *   登録したタスクをリスト形式で表示。
    *   期限までの残り時間をリアルタイムで表示（例：「残り 2時間 30分」）。
    *   期限切れのタスクは警告色で表示。
*   **タスク編集**:
    *   既存タスクの内容をいつでも変更可能。
*   **タスク完了**:
    *   チェックボックスをタップして完了状態に切り替え。完了タスクは取り消し線が表示されます。
*   **タスク削除**:
    *   リストを左にスワイプして削除（ゴミ箱へ移動）。
*   **並び替え**:
    *   タスクを長押ししてドラッグ＆ドロップで任意の順序に並び替え可能。

### 2. 強力な通知機能
*   **期限通知**:
    *   設定した期限に合わせてローカル通知を送信。
*   **繰り返し通知**:
    *   毎日、毎週、毎月、毎年といった周期での繰り返しタスク設定に対応。

### 3. 設定・カスタマイズ
*   **テーマ切り替え**:
    *   ライトモード、ダークモード、システム設定（端末の設定に追従）から選択可能。
*   **削除確認設定**:
    *   タスク削除時の確認ダイアログ表示のオン/オフ設定。
    *   「次回から表示しない」オプションですぐに削除可能に。
*   **ゴミ箱機能**:
    *   削除したタスクは一時的に「ゴミ箱」に保管。
    *   誤って削除した場合の復元や、完全削除が可能。
    *   削除から30日経過したタスクは自動的に完全削除。

## 技術スタック

本アプリケーションは、以下の最新のFlutterエコシステム技術を利用して開発されています。

*   **Framework**: Flutter
*   **Language**: Dart
*   **State Management**: [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
*   **Database**: [drift](https://pub.dev/packages/drift) (SQLite abstraction)
*   **Notifications**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
*   **Data Class / Code Gen**: [freezed](https://pub.dev/packages/freezed), [json_serializable](https://pub.dev/packages/json_serializable)
*   **Settings Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences)
*   **UI Components**: [settings_ui](https://pub.dev/packages/settings_ui), [animations](https://pub.dev/packages/animations)
*   **Utilities**: [intl](https://pub.dev/packages/intl) (dateFormat), [flutter_screenutil](https://pub.dev/packages/flutter_screenutil) (responsive size)

## ディレクトリ構成

`lib/` 以下の主要なディレクトリ構成は以下の通りです。

```
lib/
├── database.dart       # Driftデータベース定義
├── main.dart           # アプリのエントリーポイント
├── models/             # データモデル (Freezedクラスなど)
│   └── task.dart       # タスクモデル
├── utils/              # ユーティリティ関数
│   └── date_logic.dart # 日付計算ロジック
├── view_models/        # ViewModel (Riverpod Provider)
│   ├── home_view_model.dart
│   └── ...
└── views/              # UI (画面)
    ├── home_view.dart        # メイン画面（タスク一覧）
    ├── task_from_view.dart   # タスク追加・編集画面
    ├── settings_view.dart    # 設定画面
    ├── delete_task_view.dart # ゴミ箱画面
    └── license_view.dart     # ライセンス画面
```

## インストールと実行方法

### 前提条件
*   Flutter SDK (バージョン 3.0.0 以上推奨)
*   Dart SDK

### セットアップ手順

1. **リポジトリのクローン**
   ```bash
   git clone <repository_url>
   cd deadline_manager
   ```

2. **依存関係のインストール**
   ```bash
   flutter pub get
   ```

3. **コード生成の実行**
   DriftやFreezedを使用しているため、初回やモデル変更時には以下を実行してください。
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **アプリの実行**
   ```bash
   flutter run
   ```

## 使用方法ガイド

### 📝 タスクを追加する
1.  ホーム画面右下の「**新規タスク**」ボタンをタップします。
2.  タスクフォームが開くので、以下の情報を入力します。
    *   **タイトル**: タスクの名前（必須）
    *   **期限**: 日付と時間を選択
    *   **通知**: 必要に応じてオン/オフ
    *   **繰り返し**: 定期タスクの場合は選択
3.  右上の「保存」または画面下部のボタンを押して完了です。

### ✏️ タスクを編集する
1.  リスト上の編集したいタスクカードをタップします。
2.  編集画面が開くので、内容を修正して保存します。

### ✅ タスクを完了する
1.  タスクカード左側の丸いチェックボックスをタップします。
2.  タスクに取り消し線が引かれ、完了状態になります。

### 🗑 タスクを削除する
1.  削除したいタスクを**右から左へスワイプ**します。
2.  確認ダイアログが表示されるので「削除」を選択します。
    *   *ヒント: 設定で確認ダイアログを非表示にできます。*
3.  削除されたタスクは「設定 > ゴミ箱」から確認・復元できます。

### ⚙️ 設定を変更する
ホーム画面右上の歯車アイコン（⚙️）から設定画面にアクセスできます。
*   **テーマ**: ダークモードで目に優しく使いたい場合はこちらで変更。
*   **タスク削除時の確認**: スワイプ削除時のワンクッションが不要な場合はオフにできます。
