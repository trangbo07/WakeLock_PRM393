import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/shop_item.dart';
import '../providers/gamification_providers.dart';
import '../widgets/coin_pill.dart';
import '../widgets/pill_button.dart';

/// Coin shop. Buying deducts coins and marks the item owned (transaction).
class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  final Set<String> _busy = {};

  Future<void> _buy(ShopItem item) async {
    final uid = ref.read(sessionProvider).asData?.value?.uid;
    if (uid == null) return;
    setState(() => _busy.add(item.id));
    try {
      final ok = await ref
          .read(gamificationDataSourceProvider)
          .purchase(uid, item.id, item.price);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              ok ? 'Đã mua "${item.name}"! 🎉' : 'Không đủ xu để mua vật phẩm này.'),
        ));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(item.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(myProfileProvider).asData?.value;
    final coins = profile?.coins ?? 0;
    final owned = profile?.ownedItems ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cửa hàng'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(child: CoinPill(coins: coins)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          for (final item in kShopItems)
            _ShopTile(
              item: item,
              owned: owned.contains(item.id),
              affordable: coins >= item.price,
              busy: _busy.contains(item.id),
              onBuy: () => _buy(item),
            ),
        ],
      ),
    );
  }
}

class _ShopTile extends StatelessWidget {
  const _ShopTile({
    required this.item,
    required this.owned,
    required this.affordable,
    required this.busy,
    required this.onBuy,
  });

  final ShopItem item;
  final bool owned;
  final bool affordable;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(item.icon, color: item.color, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.mutedForeground)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _Trailing(
              owned: owned,
              affordable: affordable,
              busy: busy,
              price: item.price,
              onBuy: onBuy),
        ],
      ),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({
    required this.owned,
    required this.affordable,
    required this.busy,
    required this.price,
    required this.onBuy,
  });

  final bool owned;
  final bool affordable;
  final bool busy;
  final int price;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    if (owned) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 18),
          SizedBox(width: 4),
          Text('Đã sở hữu',
              style: TextStyle(
                  color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
        ],
      );
    }
    if (busy) {
      return const SizedBox(
          width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    }
    return PillButton(
      onTap: onBuy,
      color: affordable ? AppColors.primary : AppColors.surfaceMuted,
      foreground: affordable ? AppColors.onPrimary : AppColors.mutedForeground,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, size: 16),
          const SizedBox(width: 4),
          Text('$price'),
        ],
      ),
    );
  }
}
