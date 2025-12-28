# リーマ (Reema) 仕様書

## 概要
リーマは、**通知に特化した**シンプルで使いやすいリマインダーアプリケーションです。
Flutterで構築されており、直感的なUIでリマインダーの作成、編集、削除を行うことができます。「忘れたくないこと」を確実に通知でお知らせすることに重点を置いており、残り時間のリアルタイム表示や柔軟な繰り返し設定をサポートしています。

## スクリーンショット
(ここにアプリのスクリーンショットを配置してください)

## 主な機能

### 1. リマインダー管理機能
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

### 2. 繰り返しタスク機能
*   **繰り返しタスクの管理**:
    *   繰り返しタスクは専用のタブで管理・表示。
*   **多彩な繰り返し設定**:
    *   **毎日**: 毎日同じ時刻にリマインド。
    *   **毎週**: 曜日を選択して週単位でリマインド。
    *   **毎月**: 日付を選択して月単位でリマインド。
*   **ドラムロール型時刻ピッカー**:
    *   繰り返しタスク専用の直感的な時刻選択UI。
*   **自動更新**:
    *   期限切れの繰り返しタスクは自動的に次回の発生日時に更新。
*   **完了チェックボックス非表示**:
    *   繰り返しタスクには完了チェックボックスを表示しない設計。

### 3. 強力な通知機能
*   **期限通知**:
    *   設定した期限に合わせてローカル通知を送信。
*   **相対時刻通知**:
    *   「今から○時間○分後」という相対的な時刻設定にも対応。
*   **繰り返し通知**:
    *   繰り返しタスクに連動した定期的な通知をサポート。

### 4. 設定・カスタマイズ
*   **テーマ切り替え**:
    *   ライトモード、ダークモード、システム設定（端末の設定に追従）から選択可能。
    *   Material Design 3 (Material You) に対応したモダンなデザイン。
*   **削除確認設定**:
    *   タスク削除時の確認ダイアログ表示のオン/オフ設定。
    *   「次回から表示しない」オプションですぐに削除可能に。
*   **端末の通知設定**:
    *   設定画面から端末の通知設定に直接アクセス可能。
*   **ゴミ箱機能**:
    *   削除したタスクは一時的に「ゴミ箱」に保管。
    *   誤って削除した場合の復元や、完全削除が可能。
    *   削除から30日経過したタスクは自動的に完全削除。

### 5. 広告機能
*   **Google AdMob バナー広告**:
    *   各画面の下部にバナー広告を表示。
    *   SafeAreaに対応し、iOSのノッチやジェスチャーエリアを考慮した配置。
    *   テスト広告と本番広告の切り替えをビルド時の環境変数で制御。

## 技術スタック

本アプリケーションは、以下の最新のFlutterエコシステム技術を利用して開発されています。

*   **Framework**: Flutter
*   **Language**: Dart
*   **State Management**: [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
*   **Database**: [drift](https://pub.dev/packages/drift) (SQLite abstraction)
*   **Notifications**: [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
*   **Data Class / Code Gen**: [freezed](https://pub.dev/packages/freezed), [json_serializable](https://pub.dev/packages/json_serializable)
*   **Settings Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences)
*   **Ads**: [google_mobile_ads](https://pub.dev/packages/google_mobile_ads) (AdMob)
*   **UI & Design**: 
    *   [google_fonts](https://pub.dev/packages/google_fonts) (Noto Sans JP)
    *   [animations](https://pub.dev/packages/animations)
    *   Material Design 3 対応
*   **Utilities**: 
    *   [intl](https://pub.dev/packages/intl) (日付フォーマット)
    *   [flutter_screenutil](https://pub.dev/packages/flutter_screenutil) (レスポンシブサイズ)
    *   [permission_handler](https://pub.dev/packages/permission_handler) (権限管理)
    *   [app_settings](https://pub.dev/packages/app_settings) (端末設定へのアクセス)

## ディレクトリ構成

`lib/` 以下の主要なディレクトリ構成は以下の通りです。

```
lib/
├── database.dart         # Driftデータベース定義
├── main.dart             # アプリのエントリーポイント
├── models/               # データモデル (Freezedクラス)
│   └── task.dart         # タスクモデル
├── services/             # サービスレイヤー
│   └── ad_service.dart   # AdMob広告管理
├── theme/                # テーマ設定
│   └── app_theme.dart    # ライト/ダークテーマ定義
├── utils/                # ユーティリティ関数
│   └── date_logic.dart   # 日付計算ロジック
├── view_models/          # ViewModel (Riverpod Provider)
│   ├── home_view_model.dart
│   ├── delete_task_view_model.dart
│   └── theme_view_model.dart
├── views/                # UI (画面)
│   ├── home_view.dart        # メイン画面（タスク一覧）
│   ├── task_from_view.dart   # タスク追加・編集画面
│   ├── settings_view.dart    # 設定画面
│   ├── delete_task_view.dart # ゴミ箱画面
│   └── license_view.dart     # ライセンス画面
└── widgets/              # 再利用可能なウィジェット
    └── banner_ad_widget.dart # バナー広告ウィジェット
```

## インストールと実行方法

### 前提条件
*   Flutter SDK (バージョン 3.0.0 以上)
*   Dart SDK
*   iOS: Xcode 14以上
*   Android: Android Studio

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
   # 開発版（テスト広告を使用）
   flutter run
   
   # 本番版（本番広告IDを指定）
   flutter run --dart-define=BANNER_AD_UNIT_ID=ca-app-pub-XXXXX/YYYYY
   ```

### AdMob設定

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXX~YYYYYYYYY</string>
```

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXX~YYYYYYYYY"/>
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

### 🔄 繰り返しタスクを追加する
1.  ホーム画面で「繰り返し」タブに切り替えます。
2.  右下の「**新規タスク**」ボタンをタップします。
3.  繰り返し頻度（毎日/毎週/毎月）を選択します。
4.  毎週の場合は曜日を、毎月の場合は日付を選択します。
5.  ドラムロール型ピッカーで時刻を選択して保存します。

### ✏️ タスクを編集する
1.  リスト上の編集したいタスクカードをタップします。
2.  編集画面が開くので、内容を修正して保存します。

### ✅ タスクを完了する
1.  タスクカード左側の丸いチェックボックスをタップします。
2.  タスクに取り消し線が引かれ、完了状態になります。
    *   *注: 繰り返しタスクには完了チェックボックスはありません。*

### 🗑 タスクを削除する
1.  削除したいタスクを**右から左へスワイプ**します。
2.  確認ダイアログが表示されるので「削除」を選択します。
    *   *ヒント: 設定で確認ダイアログを非表示にできます。*
3.  削除されたタスクは「設定 > ゴミ箱」から確認・復元できます。

### ⚙️ 設定を変更する
ホーム画面右上の歯車アイコン（⚙️）から設定画面にアクセスできます。
*   **テーマ**: ダークモードで目に優しく使いたい場合はこちらで変更。
*   **リマインダー削除時の確認**: スワイプ削除時のワンクッションが不要な場合はオフにできます。
*   **端末の通知設定**: 通知が届かない場合はこちらで端末の設定を確認できます。
*   **ゴミ箱**: 誤って削除したタスクの復元や完全削除ができます。

## ライセンス
このアプリケーションはプライベートプロジェクトです。ライセンス情報はアプリ内の設定画面から確認できます。
