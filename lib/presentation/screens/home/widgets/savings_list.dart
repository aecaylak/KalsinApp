import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../domain/models/category.dart';
import '../../../../domain/models/saving.dart';
import '../../../providers/currency_provider.dart';
import '../../../providers/savings_provider.dart';
import '../../add_saving/add_saving_sheet.dart';

// Her 5 tasarruf kaydından sonra reklam yerleştirme aralığı
const int _adInterval = 5;

/// Ana ekrandaki kısa tasarruf listesi.
class SavedList extends ConsumerWidget {
  const SavedList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentSavingsProvider(15));

    if (recents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.lg),
          child: Column(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 40)),
              const SizedBox(height: AppTheme.sm),
              Text(
                'Henüz tasarruf yok\nİlk "Kalsın"ını ekle!',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Her 5 kayıttan sonra reklam ekleyerek liste elemanlarını oluştur
    final List<Widget> listItems = [];
    for (int i = 0; i < recents.length; i++) {
      listItems.add(_SavingTile(saving: recents[i], index: i));
      // 5, 10, 15... indekslerinden sonra reklam kartı ekle (0-indexed: 4, 9, 14...)
      if ((i + 1) % _adInterval == 0 && (i + 1) < recents.length) {
        listItems.add(_BannerAdTile(adIndex: (i + 1) ~/ _adInterval));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.sm),
          child: Row(
            children: [
              Text('Son Tasarruflar', style: AppTheme.headingMedium),
              const Spacer(),
              Text('${recents.length} kayıt', style: AppTheme.labelSmall),
            ],
          ),
        ),
        ...listItems,
      ],
    );
  }
}

/// Reklam kartı — tasarruf kartıyla aynı görünümde, içinde banner reklam.
class _BannerAdTile extends StatefulWidget {
  const _BannerAdTile({required this.adIndex});
  final int adIndex;

  @override
  State<_BannerAdTile> createState() => _BannerAdTileState();
}

class _BannerAdTileState extends State<_BannerAdTile> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // Test ID — canlıya geçerken AdMob'dan aldığın gerçek ID ile değiştir
  static const String _adUnitId =
      'ca-app-pub-5404730657063470/3302266042'; // Android test banner ID

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner, // 320x50 standart banner
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
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
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppTheme.adaptiveBorder(context), width: 0.8),
      ),
      child: Column(
        children: [
          // "Reklam" etiketi
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Reklam',
              style: AppTheme.labelSmall.copyWith(fontSize: 10),
            ),
          ),
          const SizedBox(height: 4),
          // Banner reklam alanı
          SizedBox(
            height: 50,
            child: _isLoaded && _bannerAd != null
                ? AdWidget(ad: _bannerAd!)
                : const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: widget.adIndex * 60))
        .fadeIn(duration: 400.ms);
  }
}

class _SavingTile extends ConsumerWidget {
  const _SavingTile({required this.saving, required this.index});
  final Saving saving;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = AppCategories.findById(saving.categoryId);
    final currency = ref.watch(currencyProvider);
    final formatter = NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '+${currency.symbol}',
      decimalDigits: 0,
    );
    final timeAgo = _timeAgo(saving.savedAt);

    return Dismissible(
      key: Key(saving.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: const Text('Tasarrufu Sil'),
            content: Text(
                '${formatter.format(saving.amount)} tutarındaki tasarrufu silmek istediğine emin misin?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                child: const Text('Sil', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) {
        ref.read(savingsProvider.notifier).deleteSaving(saving.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.sm),
        decoration: BoxDecoration(
          color: AppTheme.danger.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppTheme.md),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppTheme.danger, size: 22),
      ),
      child: GestureDetector(
        onTap: () => showAddSavingSheet(context, existing: saving),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppTheme.sm),
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.md, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: AppTheme.adaptiveBorder(context), width: 0.8),
          ),
          child: Row(
            children: [
              // Kategori emoji
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.md),
              // İçerik
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      saving.note ?? category.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${category.name} · $timeAgo',
                      style: AppTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              // Tutar
              Text(
                formatter.format(saving.amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: index * 60))
          .fadeIn(duration: 400.ms)
          .slideX(begin: 0.1),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}dk önce';
    if (diff.inHours < 24) return '${diff.inHours}sa önce';
    if (diff.inDays == 1) return 'dün';
    return '${diff.inDays}g önce';
  }
}
