import 'package:app_user/src/features/payment/logic/purchase_history_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:url_launcher/url_launcher.dart';

part 'purchase_history_card.dart';
part 'purchase_history_refund_row.dart';
part 'purchase_history_status_badge.dart';

class PurchaseHistoryPage extends ConsumerWidget {
  const PurchaseHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(purchaseHistoryControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('구매 내역'),
      ),
      body: MinglitAsyncValueWidget(
        value: historyAsync,
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Text(
                '구매 내역이 없습니다.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            itemCount: history.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: MinglitSpacing.medium),
            itemBuilder: (context, index) {
              return PurchaseHistoryCard(application: history[index]);
            },
          );
        },
      ),
    );
  }
}
