import 'dart:async';

import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'ticket_selection_widgets.dart';

class TicketSelectionSheet extends ConsumerStatefulWidget {
  const TicketSelectionSheet({required this.event, super.key});

  final Event event;

  @override
  ConsumerState<TicketSelectionSheet> createState() =>
      _TicketSelectionSheetState();
}

class _TicketSelectionSheetState extends ConsumerState<TicketSelectionSheet> {
  String? _selectedTicketId;
  int _quantity = 1;
  var _balanceStatus = <String, bool>{};
  bool _isBalanceStatusLoading = true;
  bool _isUserDataLoading = true;
  UserProfile? _userProfile;
  List<String> _approvedVerificationIds = [];
  TicketRecommendationResult? _recommendation;
  bool _hasAutoSelected = false;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchBalanceStatus());
    unawaited(_fetchUserData());
  }

  void _selectTicket(String ticketId) {
    setState(() {
      _selectedTicketId = ticketId;
      _quantity = 1;
    });
  }

  Future<void> _fetchBalanceStatus() async {
    try {
      final repository = ref.read(eventRepositoryProvider);
      final status = await repository.getTicketBalanceStatus(widget.event.id);
      if (!mounted) return;
      setState(() {
        _balanceStatus = status;
        _isBalanceStatusLoading = false;
      });
      _updateRecommendation();
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() => _isBalanceStatusLoading = false);
      _updateRecommendation();
    }
  }

  Future<void> _fetchUserData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      if (!mounted) return;
      setState(() => _isUserDataLoading = false);
      _updateRecommendation();
      return;
    }

    final userRepository = ref.read(userRepositoryProvider);
    final profile = await userRepository.getUserProfile(user.id);
    final verificationIds = await userRepository.getApprovedVerificationIds(
      user.id,
    );

    if (!mounted) return;
    setState(() {
      _userProfile = profile;
      _approvedVerificationIds = verificationIds;
      _isUserDataLoading = false;
    });
    _updateRecommendation();
  }

  void _updateRecommendation() {
    if (!mounted) return;
    if (_isBalanceStatusLoading || _isUserDataLoading) return;
    final recommendation = TicketRecommendationUtil.recommend(
      event: widget.event,
      userProfile: _userProfile,
      approvedVerificationIds: _approvedVerificationIds,
      balanceStatus: _balanceStatus,
    );

    final recommendedTicket = recommendation.recommendedTicket;
    final selectedIsEligible =
        _selectedTicketId != null &&
        recommendation.eligibleTickets.any(
          (ticket) => ticket.id == _selectedTicketId,
        );

    setState(() {
      _recommendation = recommendation;
      if (!_hasAutoSelected) {
        _selectedTicketId = recommendedTicket?.id;
        _quantity = 1;
        _hasAutoSelected = true;
      } else if (!selectedIsEligible) {
        _selectedTicketId = recommendedTicket?.id;
        _quantity = 1;
      }
    });
  }

  void _onNext() {
    if (_selectedTicketId == null) return;

    // Close sheet first
    Navigator.pop(context);

    // Navigate to Application Wizard via Coordinator
    ref
        .read(eventCoordinatorProvider)
        .goToApplicationWizard(
          widget.event.id,
          ticketId: _selectedTicketId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tickets = widget.event.tickets ?? [];
    final recommendation = _recommendation;
    final recommendedTicket = recommendation?.recommendedTicket;
    final eligibleTickets = recommendation?.eligibleTickets ?? [];
    final ineligibleReasons = recommendation?.ineligibleReasons ?? {};
    final otherTickets = tickets
        .where(
          (ticket) => ticket.id != recommendedTicket?.id,
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MinglitRadius.card),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '티켓 선택',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          if (_isBalanceStatusLoading || _isUserDataLoading)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: MinglitSpacing.large,
              ),
              child: Text(
                '추천 티켓을 확인 중입니다.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else if (tickets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: MinglitSpacing.large,
              ),
              child: Text(
                '현재 구매 가능한 티켓이 없습니다.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else if (recommendedTicket == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: MinglitSpacing.medium,
              ),
              child: Text(
                '현재 구매 가능한 티켓이 없습니다.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            ...tickets.map(
              (ticket) => buildTicketOption(
                ticket,
                isLocked: true,
                isRecommended: false,
                ineligibleReason: ineligibleReasons[ticket.id],
              ),
            ),
          ] else ...[
            Text(
              '추천 티켓',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            buildTicketOption(
              recommendedTicket,
              isLocked: false,
              isRecommended: true,
              ineligibleReason: null,
            ),
            if (otherTickets.isNotEmpty) ...[
              const SizedBox(height: MinglitSpacing.medium),
              Text(
                '다른 티켓',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: MinglitSpacing.small),
              ...otherTickets.map((ticket) {
                final isEligible = eligibleTickets.any(
                  (eligible) => eligible.id == ticket.id,
                );
                return buildTicketOption(
                  ticket,
                  isLocked: !isEligible,
                  isRecommended: false,
                  ineligibleReason: ineligibleReasons[ticket.id],
                );
              }),
            ],
          ],
          const SizedBox(height: MinglitSpacing.large),

          // Quantity (Only if ticket selected)
          if (_selectedTicketId != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '수량',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                buildQuantityStepper(),
              ],
            ),
            const SizedBox(height: MinglitSpacing.large),
            const Divider(),
            const SizedBox(height: MinglitSpacing.medium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 결제 금액',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  calculateTotal(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.large),
          ],

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedTicketId == null ? null : _onNext,
              child: const Text('다음'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }
}
