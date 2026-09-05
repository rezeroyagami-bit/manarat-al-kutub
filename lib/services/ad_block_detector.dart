import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Detects strong signs that AdMob traffic is being blocked.
///
/// A single ad failure is never treated as an ad blocker because ads can fail
/// for normal reasons (no fill, temporary network problems, etc.).
class AdBlockDetector {
  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static Future<bool> isLikelyBlocked() async {
    try {
      await MobileAds.instance.initialize();
    } catch (_) {
      return false;
    }

    final results = await Future.wait([
      _probeRewardedAd(),
      _probeRewardedAd(),
    ]);

    // Require two independent AdMob network failures. No-fill and other
    // normal AdMob errors must never block access to KITARA.
    return results.every((result) => result == _ProbeResult.networkError);
  }

  static Future<_ProbeResult> _probeRewardedAd() async {
    final completer = Completer<_ProbeResult>();
    var finished = false;

    void complete(_ProbeResult result) {
      if (finished) return;
      finished = true;
      completer.complete(result);
    }

    RewardedAd.load(
      adUnitId: _testRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.dispose();
          complete(_ProbeResult.loaded);
        },
        onAdFailedToLoad: (error) {
          // AdMob error code 2 = network error.
          if (error.code == 2) {
            complete(_ProbeResult.networkError);
          } else {
            complete(_ProbeResult.otherError);
          }
        },
      ),
    );

    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => _ProbeResult.timeout,
    );
  }
}

enum _ProbeResult {
  loaded,
  networkError,
  otherError,
  timeout,
}
