import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 広告配置箇所
enum AdPlacement {
  homeList, // 一覧画面下部
  taskForm, // 追加・編集画面
  settings, // 設定画面
}

/// AdMob広告管理サービス
class AdService {
  static bool _initialized = false;

  /// AdMobを初期化
  static Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  /// 配置箇所に応じたバナー広告ユニットIDを取得
  /// 本番ビルド時は --dart-define で各IDを指定
  static String getBannerAdUnitId(AdPlacement placement) {
    // 各配置箇所の環境変数
    const homeAdId = String.fromEnvironment('BANNER_AD_HOME');
    const taskFormAdId = String.fromEnvironment('BANNER_AD_TASK_FORM');
    const settingsAdId = String.fromEnvironment('BANNER_AD_SETTINGS');

    switch (placement) {
      case AdPlacement.homeList:
        if (homeAdId.isNotEmpty) return homeAdId;
        break;
      case AdPlacement.taskForm:
        if (taskFormAdId.isNotEmpty) return taskFormAdId;
        break;
      case AdPlacement.settings:
        if (settingsAdId.isNotEmpty) return settingsAdId;
        break;
    }

    // 環境変数が設定されていない場合はテスト用IDを使用
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // iOSテスト用
    }
    return 'ca-app-pub-3940256099942544/6300978111'; // Androidテスト用
  }
}
