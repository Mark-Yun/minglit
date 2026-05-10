import 'dart:async';

import 'package:app_user/src/features/ticket/data/ticket_token_service.dart';
import 'package:app_user/src/features/ticket/ui/widgets/boarding_pass_card.dart';
import 'package:app_user/src/logic/ticket_event_meta.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:screen_brightness/screen_brightness.dart';

// Fix #1526: TicketQRScreen 리팩터링 — BoardingPassCard 통합 + 이벤트 메타 전달

/// **Ticket QR Screen**
///
/// Displays the ticket as a boarding-pass-style card with the QR code.
/// [eventMeta] provides display context (title, date, venue, ticket type).
/// When [eventMeta] is null the card still renders, showing placeholder text.
///
/// Supports offline mode via cached tokens in the local wallet.
class TicketQRScreen extends StatefulWidget {
  const TicketQRScreen({
    required this.ticketId,
    this.eventMeta,
    super.key,
  });

  final String ticketId;

  /// Event metadata for boarding pass display. Optional — callers that cannot
  /// provide it (e.g. deep links) will still see the QR but without event info.
  final TicketEventMeta? eventMeta;

  @override
  State<TicketQRScreen> createState() => _TicketQRScreenState();
}

class _TicketQRScreenState extends State<TicketQRScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanningController;
  double? _originalBrightness;

  @override
  void initState() {
    super.initState();
    _scanningController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_scanningController.repeat(reverse: true));
    unawaited(_maximizeBrightness());
  }

  @override
  void dispose() {
    _scanningController.dispose();
    unawaited(_restoreBrightness());
    super.dispose();
  }

  Future<void> _maximizeBrightness() async {
    try {
      _originalBrightness = await ScreenBrightness().application;
      await ScreenBrightness().setApplicationScreenBrightness(1);
    } on Object catch (e) {
      Log.e('Failed to set screen brightness', e);
    }
  }

  Future<void> _restoreBrightness() async {
    // Fix #382: 강제 언래핑 제거 — local variable로 null 안전성 확보
    final brightness = _originalBrightness;
    if (brightness != null) {
      try {
        await ScreenBrightness().setApplicationScreenBrightness(brightness);
      } on Object catch (e) {
        Log.e('Failed to restore screen brightness', e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: MinglitColors.surface,
      appBar: MinglitTheme.simpleAppBar(title: '내 티켓'),
      body: Consumer(
        builder: (context, ref, _) {
          final ticketAsync = ref.watch(_ticketTokenProvider(widget.ticketId));

          return MinglitAsyncValueWidget<TicketToken?>(
            value: ticketAsync,
            data: (token) {
              if (token == null) {
                return const Center(
                  child: Column(
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
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(MinglitSpacing.large),
                child: Column(
                  children: [
                    // Boarding pass card
                    BoardingPassCard(
                      token: token,
                      eventMeta: widget.eventMeta,
                      scanningAnimation: _scanningController,
                    ),

                    const SizedBox(height: MinglitSpacing.large),

                    // Fix #2374: 입장 안내 — 명시적 semantic label (스크린리더 접근성)
                    Semantics(
                      label: '입장 안내: 입장 시 파트너에게 이 화면을 보여주세요',
                      child: Text(
                        '입장 시 파트너에게 이 화면을 보여주세요',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: MinglitSpacing.small),

                    // Fix #2374: 캡처 방지 안내 — 명시적 semantic label
                    Semantics(
                      label: '캡처 방지 안내: 스크린샷은 입장에 사용할 수 없습니다',
                      child: Text(
                        '스크린샷은 입장에 사용할 수 없습니다',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: MinglitOpacity.muted,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
