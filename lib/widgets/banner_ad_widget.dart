import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:deadline_manager/services/ad_service.dart';
import 'package:deadline_manager/theme/app_theme.dart';

/// 再利用可能なバナー広告ウィジェット（モダンスタイル対応）
class BannerAdWidget extends StatefulWidget {
  final AdPlacement placement;

  const BannerAdWidget({
    Key? key,
    required this.placement,
  }) : super(key: key);

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdService.getBannerAdUnitId(widget.placement),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() => _isLoaded = true);
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('バナー広告のロードに失敗: ${error.message}');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  // TODO: スクリーンショット撮影後は false に戻すこと
  static const bool _hideAdsForScreenshot = false;

  @override
  Widget build(BuildContext context) {
    // アプリストアのスクリーンショット用に広告を非表示
    if (_hideAdsForScreenshot) {
      return const SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFF8F7FC);

    if (!_isLoaded || _bannerAd == null) {
      return SafeArea(
        top: false,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border(
              top: BorderSide(
                color: isDarkMode
                    ? AppTheme.secondaryColor.withOpacity(0.1)
                    : AppTheme.primaryColor.withOpacity(0.08),
                width: 1,
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(
              color: isDarkMode
                  ? AppTheme.secondaryColor.withOpacity(0.1)
                  : AppTheme.primaryColor.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
