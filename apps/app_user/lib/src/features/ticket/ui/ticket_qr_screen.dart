import 'package:app_user/src/features/ticket/data/ticket_wallet_repository.dart';
import 'package:app_user/src/features/ticket/ui/widgets/ticket_qr_viewer.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Ticket QR Screen**
///
/// Shows the QR code for a specific ticket.
/// Supports offline mode by reading from [TicketWalletRepository].
class TicketQRScreen extends ConsumerWidget {
  const TicketQRScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(_ticketTokenProvider(ticketId));

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '내 티켓'),
      body: Center(
        child: MinglitAsyncValueWidget<TicketToken?>(
          value: ticketAsync,
          data: (token) {
            if (token == null) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text('티켓 정보를 찾을 수 없습니다.'),
                ],
              );
            }
            return TicketQRViewer(token: token);
          },
        ),
      ),
    );
  }
}

// ignore: specify_nonobvious_property_types
final _ticketTokenProvider = FutureProvider.family<TicketToken?, String>((
  ref,
  id,
) {
  return ref.watch(ticketWalletRepositoryProvider).getTicket(id);
});
