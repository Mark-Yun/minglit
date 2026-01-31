import 'dart:async';

import 'package:app_user/src/features/event/admission/event_admission_controller.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

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
          context,
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
              (ticket) => _buildTicketOption(
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
            _buildTicketOption(
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
                return _buildTicketOption(
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
                _buildQuantityStepper(),
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
                  _calculateTotal(),
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

  Widget _buildTicketOption(
    Ticket ticket, {
    required bool isLocked,
    required bool isRecommended,
    required String? ineligibleReason,
  }) {
    final isSelected = _selectedTicketId == ticket.id;
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,###');
    final nameColor = isLocked
        ? theme.colorScheme.onSurfaceVariant
        : isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    final priceColor = isLocked ? theme.colorScheme.onSurfaceVariant : null;

    return GestureDetector(
      onTap: isLocked
          ? null
          : () {
              setState(() {
                _selectedTicketId = ticket.id;
                _quantity = 1; // Reset quantity on change
              });
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: MinglitSpacing.small),
        child: Stack(
          children: [
            Opacity(
              opacity: isLocked ? 0.5 : 1,
              child: Container(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(MinglitRadius.input),
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.05)
                      : theme.colorScheme.surface,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: nameColor,
                            ),
                          ),
                          if (ticket.description != null)
                            Text(
                              ticket.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (isLocked && ineligibleReason != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: MinglitSpacing.xsmall,
                              ),
                              child: Text(
                                ineligibleReason,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${formatter.format(ticket.price)}원',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: priceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLocked)
              Positioned(
                top: MinglitSpacing.small,
                right: MinglitSpacing.small,
                child: _buildBalanceBadge(theme),
              ),
            if (!isLocked && isRecommended)
              Positioned(
                top: MinglitSpacing.small,
                right: MinglitSpacing.small,
                child: _buildRecommendedBadge(theme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(MinglitRadius.small),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        '성비 조절 중',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecommendedBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(MinglitRadius.small),
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Text(
        '추천',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildQuantityStepper() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: Row(
        children: [
          const IconButton(
            onPressed: null,
            icon: Icon(Icons.remove, size: MinglitIconSize.xsmall),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text(
            '$_quantity',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () =>
                context.showMinglitInfo('친구와 함께 참가하기 기능은 준비 중입니다.'),
            icon: const Icon(Icons.add, size: MinglitIconSize.xsmall),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  String _calculateTotal() {
    if (_selectedTicketId == null) return '0원';
    final ticket = widget.event.tickets!.firstWhere(
      (t) => t.id == _selectedTicketId,
    );
    return '${NumberFormat('#,###').format(ticket.price * _quantity)}원';
  }
}
