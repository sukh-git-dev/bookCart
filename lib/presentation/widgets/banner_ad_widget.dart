import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  static const _productionAdUnitId = 'ca-app-pub-2992194837739047/7340662564';
  static const _androidTestBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _iosTestBannerId = 'ca-app-pub-3940256099942544/2934735716';

  BannerAd? bannerAd;
  bool isLoaded = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    if (kIsWeb) {
      errorMessage = 'Banner ads are not supported in Flutter web here.';
      return;
    }

    try {
      bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: _adUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) {
              setState(() {
                isLoaded = true;
                errorMessage = null;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            debugPrint('Banner ad failed to load: $error');
            if (mounted) {
              setState(() {
                bannerAd = null;
                errorMessage = error.message;
              });
            } else {
              bannerAd = null;
              errorMessage = error.message;
            }
          },
        ),
      )..load();
    } catch (error) {
      debugPrint('Banner ad init error: $error');
      bannerAd = null;
      errorMessage = error.toString();
    }
  }

  String get _adUnitId {
    if (!kDebugMode) {
      return _productionAdUnitId;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _iosTestBannerId;
      case TargetPlatform.android:
      default:
        return _androidTestBannerId;
    }
  }

  @override
  void dispose() {
    bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && errorMessage != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Text(
          'Ad debug: $errorMessage',
          style: const TextStyle(fontSize: 12),
        ),
      );
    }

    if (kIsWeb || bannerAd == null || !isLoaded) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: bannerAd!.size.height.toDouble(),
      width: bannerAd!.size.width.toDouble(),
      child: AdWidget(ad: bannerAd!),
    );
  }
}
