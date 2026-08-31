import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdManager {
  // NOTA: REEMPLAZA ESTOS IDs CON LOS TUYOS REALES ANTES DE SUBIR A LA TIENDA
  static final String _bannerId = Platform.isAndroid
      ? 'ca-app-pub-1676922798634610/8967117429'
      : 'ca-app-pub-1676922798634610/8967117429';
  static final String _interstitialId = Platform.isAndroid
      ? 'ca-app-pub-1676922798634610/5154853166'
      : 'ca-app-pub-1676922798634610/5154853166';
  static final String _rewardedId = Platform.isAndroid
      ? 'ca-app-pub-1676922798634610/6448765297'
      : 'ca-app-pub-1676922798634610/6448765297';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;

  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
        },
        onAdFailedToLoad: (err) {
          _isInterstitialReady = false;
        },
      ),
    );
  }

  Future<void> showInterstitial(bool isPro, Function onAdClosed) async {
    if (isPro) {
      onAdClosed();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    int currentPlayed = (prefs.getInt('games_played_count') ?? 0) + 1;
    await prefs.setInt('games_played_count', currentPlayed);

    // Mostrar anuncio exactamente cada 3 partidas completadas
    if (currentPlayed % 3 != 0) {
      onAdClosed();
      return;
    }

    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitial();
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          loadInterstitial();
          onAdClosed();
        },
      );
      _interstitialAd!.show();
      _isInterstitialReady = false;
    } else {
      onAdClosed();
      loadInterstitial();
    }
  }

  void loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
        },
        onAdFailedToLoad: (err) {
          _isRewardedReady = false;
        },
      ),
    );
  }

  void showRewarded(Function onUserEarnedReward) {
    if (_isRewardedReady && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadRewarded();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          loadRewarded();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onUserEarnedReward();
        },
      );
      _isRewardedReady = false;
    } else {
      loadRewarded();
    }
  }

  static BannerAd createBanner({VoidCallback? onLoaded}) {
    return BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }
}
