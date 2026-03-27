import 'dart:async';

import 'package:app_user/src/features/ticket/logic/ticket_recommendation_util.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'ticket_selection_widgets.dart';

// Fix #453: onTicketSelected 콜백으로 event feature 의존 제거 — 순환 참조 해소
class TicketSelectionSheet extends ConsumerStatefulWidget {
  const TicketSelectionSheet({
    required this.event,
    required this.onTicketSelected,
    super.key,
  });

  final Event event;
  final void Function(String eventId, String? ticketId) onTicketSelected;

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

    // Fix #453: 콜백으로 네비게이션 위임 — event feature 직접 참조 제거
    widget.onTicketSelected(widget.event.id, _selectedTicketId);
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
        .where((ticket) => ticket.id != recommendedTicket?.id)
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
            buildLoadingState(theme)
          else if (tickets.isEmpty)
            buildEmptyState(theme)
          else if (recommendedTicket == null)
            ...buildNoRecommendationState(theme, tickets, ineligibleReasons)
          else
            ...buildRecommendationState(
              theme,
              recommendedTicket,
              otherTickets,
              eligibleTickets,
              ineligibleReasons,
            ),
          const SizedBox(height: MinglitSpacing.large),
          if (_selectedTicketId != null) ...buildQuantitySection(theme),
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
