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

    var networkFailures = 0;
    var completedProbes = 0;

    for (var i = 0; i < 2; i++) {
      final result = await _probeRewardedAd();
      completedProbes++;

      // AdMob's network error is the useful signal here. Other errors such as
      // no-fill are normal and must not block the user.
      if (result == _ProbeResult.networkError) {
        networkFailures++;
      }

      // Two independent network failures are required before reporting a
      // possible blocker. This avoids blocking users because of one bad ad.
      if (networkFailures >= 2) return true;
    }

    return completedProbes == 2 && networkFailures == 2;
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
