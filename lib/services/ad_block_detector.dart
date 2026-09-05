import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Detects strong signs that AdMob traffic is being blocked.
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
      _probeRewardedAd(),
    ]);

    // If two or more independent probes report an AdMob network failure,
    // treat it as an ad blocker. This is more reliable than requiring every
    // probe to fail, while still avoiding a block from one transient failure.
    final networkFailures = results
        .where((result) => result == _ProbeResult.networkError)
        .length;
    return networkFailures >= 2;
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
