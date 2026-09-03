import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/book.dart';

class DownloadOptionsScreen extends StatefulWidget {
  final Book book;

  const DownloadOptionsScreen({
    super.key,
    required this.book,
  });

  @override
  State<DownloadOptionsScreen> createState() =>
      _DownloadOptionsScreenState();
}

class _DownloadOptionsScreenState
    extends State<DownloadOptionsScreen> {
  RewardedAd? _rewardedAd;
  bool _isLoadingAd = false;

  // Rewarded Ad Unit ID الخاص بـ KITARA
  static const String _rewardedAdUnitId =
      'ca-app-pub-6792981270949925/4708033165';

  @override
  void initState() {
    super.initState();
    _loadRewardedAd();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoadingAd = false;

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent:
                (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _loadRewardedAd();

              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تعذر تشغيل الإعلان. حاول مرة أخرى.',
                    ),
                  ),
                );
              }
            },
          );

          if (mounted) {
            setState(() {});
          }
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoadingAd = false;

          if (mounted) {
            setState(() {});
          }
        },
      ),
    );

    _isLoadingAd = true;
  }

  Future<void> _openDownloadLink() async {
    final uri = Uri.parse(widget.book.downloadUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر فتح رابط التحميل.',
          ),
        ),
      );
    }
  }

  void _showRewardedAd() {
    final ad = _rewardedAd;

    if (ad == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الإعلان غير جاهز حاليًا. حاول مرة أخرى بعد قليل.',
          ),
        ),
      );

      _loadRewardedAd();
      return;
    }

    _rewardedAd = null;

    bool earnedReward = false;

    ad.show(
      onUserEarnedReward: (
        AdWithoutView ad,
        RewardItem reward,
      ) async {
        earnedReward = true;

        await _openDownloadLink();
      },
    );

    if (!earnedReward) {
      // لا يتم فتح الرابط هنا.
      // الرابط يفتح فقط بعد حصول المستخدم على المكافأة.
    }
  }

  void _confirmFreeDownload() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تحميل مجاني'),
          content: const Text(
            'شاهد الإعلان كاملًا للحصول على التحميل المجاني.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _showRewardedAd();
              },
              icon: const Icon(
                Icons.play_circle_outline,
              ),
              label: const Text(
                'مشاهدة الإعلان',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF28C28);

    return Scaffold(
      appBar: AppBar(
        title: const Text('خيارات التحميل'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            const Icon(
              Icons.download,
              size: 80,
              color: orange,
            ),

            const SizedBox(height: 20),

            Text(
              widget.book.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'التحميل المباشر سيكون متاحًا للمشتركين المدفوعين.',
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.workspace_premium,
              ),
              label: const Text(
                'تحميل مباشر — للمشتركين',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFE85D04),
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: _confirmFreeDownload,
              icon: const Icon(
                Icons.play_circle_outline,
                color: Colors.green,
              ),
              label: const Text(
                'تحميل مجاني — شاهد إعلانًا',
              ),
            ),

            const SizedBox(height: 18),

            if (_isLoadingAd)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'جاري تجهيز الإعلان...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
