import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:deadline_manager/services/ad_service.dart';

/// 再利用可能なバナー広告ウィジェット
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

  /// バナー広告をロード
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

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      // 広告がロードされるまでの高さを確保（ちらつき防止）
      return const SafeArea(
        top: false,
        child: SizedBox(height: 50),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
