import 'package:app_user/src/features/ticket/data/ticket_token_service.dart';
import 'package:app_user/src/features/ticket/ui/widgets/ticket_qr_viewer.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Ticket QR Screen**
///
/// Shows the QR code for a specific ticket.
/// Supports offline mode via cached tokens in the local wallet.
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
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: MinglitColors.error,
                  ),
                  SizedBox(height: MinglitSpacing.medium),
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

// Fix #1206: Fetches token from Edge Function when not in local wallet
// ignore: specify_nonobvious_property_types, Reason: Type is inferred correctly by FutureProvider.family
final _ticketTokenProvider = FutureProvider.family<TicketToken?, String>((
  ref,
  ticketId,
) {
  return ref.watch(ticketTokenServiceProvider).getToken(ticketId);
});
