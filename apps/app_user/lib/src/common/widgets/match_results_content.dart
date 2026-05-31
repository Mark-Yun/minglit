import 'dart:io';

import 'package:app_user/src/routing/app_coordinator.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Shared widget used by both home (EventNowBottomSheet) and
// event/admission (eventEndedWithResults CTA).
class MatchResultsContent extends ConsumerStatefulWidget {
  const MatchResultsContent({
    required this.activeEvent,
    super.key,
    this.onSaveContact,
    this.onNavigateHome,
  });

  final TodayActiveEvent activeEvent;
  final Future<void> Function(MatchPair match)? onSaveContact;
  final VoidCallback? onNavigateHome;

  @override
  ConsumerState<MatchResultsContent> createState() =>
      _MatchResultsContentState();
}

class _MatchResultsContentState extends ConsumerState<MatchResultsContent> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.activeEvent.event;
    final theme = Theme.of(context);
    final matchesAsync = ref.watch(myMatchesProvider(event.id));
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final hasMatches = matchesAsync.maybeWhen(
      data: (matches) => matches.isNotEmpty,
      orElse: () => false,
    );

    final animationDuration = reduceMotion
        ? Duration.zero
        : MinglitAnimation.medium;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _DragHandle(),
          SizedBox(
            height: hasMatches ? MinglitSpacing.xlarge : MinglitSpacing.medium,
          ),
          _MatchedHeroBadge(
            visible: hasMatches,
            reduceMotion: reduceMotion,
          ),
          SizedBox(height: hasMatches ? MinglitSpacing.medium : 0),
          Text(
            '매칭 결과',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            event.title ?? '이벤트',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MinglitColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.xlarge),
          AnimatedSwitcher(
            duration: animationDuration,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeOut,
            child: _buildResultSlot(
              context: context,
              theme: theme,
              matchesAsync: matchesAsync,
              reduceMotion: reduceMotion,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
        ],
      ),
    );
  }

  Widget _buildResultSlot({
    required BuildContext context,
    required ThemeData theme,
    required AsyncValue<List<MatchPair>> matchesAsync,
    required bool reduceMotion,
  }) {
    return matchesAsync.when(
      data: (matches) {
        if (matches.isEmpty) {
          return KeyedSubtree(
            key: const ValueKey('empty'),
            child: _buildEmptyResult(theme),
          );
        }

        return KeyedSubtree(
          key: const ValueKey('matched'),
          child: _buildMatchedResults(
            context: context,
            theme: theme,
            matches: matches,
            reduceMotion: reduceMotion,
          ),
        );
      },
      loading: () => const KeyedSubtree(
        key: ValueKey('loading'),
        child: SizedBox(
          height: 120,
          child: Center(child: MinglitCircularProgressIndicator()),
        ),
      ),
      error: (_, _) => KeyedSubtree(
        key: const ValueKey('error'),
        child: _buildEmptyResult(theme),
      ),
    );
  }

  Widget _buildEmptyResult(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.xlarge),
      child: Column(
        children: [
          Icon(
            Icons.sentiment_neutral,
            size: 48,
            color: MinglitColors.textSecondary.withValues(
              alpha: MinglitOpacity.strong,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '좋은 인연은 한번에 정해지지 않으니까요.\n다음 자리에서 더 나은 인연을 만나길 기원합니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MinglitColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.large),
          MinglitButton(
            label: '다음 이벤트 찾기',
            size: MinglitButtonSize.medium,
            expand: false,
            onPressed: _goToHome,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedResults({
    required BuildContext context,
    required ThemeData theme,
    required List<MatchPair> matches,
    required bool reduceMotion,
  }) {
    final duration = reduceMotion ? Duration.zero : MinglitAnimation.medium;

    return TweenAnimationBuilder<double>(
      duration: duration,
      curve: Curves.easeOut,
      tween: Tween(begin: 0, end: 1),
      builder: (context, t, _) {
        final copyOpacity = _segment(t, 0.2, 0.6);
        final cardsOpacity = _segment(t, 0.45, 1);

        return Column(
          children: [
            Text(
              '${matches.length}명과 매칭되었어요!',
              style: theme.textTheme.titleSmall?.copyWith(
                color: MinglitColors.primary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MinglitSpacing.small),
            Opacity(
              opacity: copyOpacity,
              child: Transform.translate(
                offset: Offset(0, (1 - copyOpacity) * 6),
                child: Text(
                  '매칭된 상대방에게 서로의 연락처가 공유되었습니다.\n오늘의 여운이 이어질 수 있게 편하게 연락해보세요.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: MinglitColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Opacity(
              opacity: cardsOpacity,
              child: Transform.translate(
                offset: Offset(0, (1 - cardsOpacity) * 10),
                child: _buildCards(matches),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCards(List<MatchPair> matches) {
    if (matches.length == 1) {
      return Align(
        child: SizedBox(
          width: 292,
          child: _MatchResultCard(
            match: matches.first,
            onSaveContact: () => _onSaveContactPressed(matches.first),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 198,
          child: PageView.builder(
            controller: _pageController,
            itemCount: matches.length,
            padEnds: false,
            onPageChanged: (index) {
              if (!mounted) return;
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index == matches.length - 1
                      ? 0
                      : MinglitSpacing.medium,
                ),
                child: _MatchResultCard(
                  match: matches[index],
                  onSaveContact: () => _onSaveContactPressed(matches[index]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: MinglitSpacing.small),
        _CarouselIndicator(
          itemCount: matches.length,
          currentIndex: _currentPage,
        ),
      ],
    );
  }

  Future<void> _onSaveContactPressed(MatchPair match) async {
    final saveContact = widget.onSaveContact ?? _saveContactToOs;
    try {
      await saveContact(match);
    } catch (error, stackTrace) {
      if (!mounted) return;
      handleMinglitError(context, error, stackTrace);
    }
  }

  Future<void> _saveContactToOs(MatchPair match) async {
    final phone = match.partnerContact?.trim();
    if (phone == null || phone.isEmpty) return;

    final name = (match.partnerName?.trim().isNotEmpty ?? false)
        ? match.partnerName!.trim()
        : '알 수 없음';

    final directory = await getTemporaryDirectory();
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣_-]+'), '_');
    final file = File(
      '${directory.path}/minglit_match_${match.partnerId}_$safeName.vcf',
    );

    await file.writeAsString(
      _buildVCard(name: name, phone: phone),
      flush: true,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(file.path, mimeType: 'text/vcard'),
        ],
        subject: '연락처 저장하기',
      ),
    );
  }

  void _goToHome() {
    if (widget.onNavigateHome != null) {
      widget.onNavigateHome!();
      return;
    }
    Navigator.of(context).maybePop();
    ref.read(appCoordinatorProvider).goToHome();
  }
}

class _MatchResultCard extends StatelessWidget {
  const _MatchResultCard({
    required this.match,
    required this.onSaveContact,
  });

  final MatchPair match;
  final Future<void> Function() onSaveContact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contact = match.partnerContact?.trim();

    return Container(
      constraints: const BoxConstraints(minHeight: 190),
      padding: const EdgeInsets.all(MinglitSpacing.large),
      decoration: BoxDecoration(
        color: MinglitColors.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MinglitAvatarImage(
                radius: 24,
                url: match.partnerProfileImage,
                backgroundColor: MinglitColors.tertiary.withValues(
                  alpha: MinglitOpacity.highlight,
                ),
                fallbackIconColor: MinglitColors.tertiary.withValues(
                  alpha: MinglitOpacity.mediumEmphasis,
                ),
              ),
              const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '공유된 연락처',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: MinglitColors.tertiary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.xxsmall),
                    Text(
                      match.partnerName ?? '알 수 없음',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (contact != null && contact.isNotEmpty) ...[
                      const SizedBox(height: MinglitSpacing.xsmall),
                      Text(
                        contact,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: MinglitColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.large),
          Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: MinglitColors.tertiary,
                onPrimary: MinglitColors.background,
              ),
            ),
            child: MinglitButton(
              label: '연락처 저장하기',
              size: MinglitButtonSize.medium,
              onPressed: (contact != null && contact.isNotEmpty)
                  ? () => onSaveContact()
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselIndicator extends StatelessWidget {
  const _CarouselIndicator({
    required this.itemCount,
    required this.currentIndex,
  });

  final int itemCount;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (index) {
        final active = index == currentIndex;
        return AnimatedContainer(
          duration: MinglitAnimation.fast,
          margin: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.xxsmall,
          ),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? MinglitColors.tertiary
                : MinglitColors.textSecondary.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _MatchedHeroBadge extends StatelessWidget {
  const _MatchedHeroBadge({
    required this.visible,
    required this.reduceMotion,
  });

  final bool visible;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final duration = reduceMotion ? Duration.zero : MinglitAnimation.medium;
    return AnimatedOpacity(
      duration: duration,
      curve: Curves.easeOut,
      opacity: visible ? 1 : 0,
      child: AnimatedScale(
        duration: duration,
        curve: Curves.easeOutBack,
        scale: visible ? 1 : 0.92,
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: MinglitColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: MinglitColors.background,
            size: 34,
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: MinglitColors.textSecondary.withValues(
          alpha: MinglitOpacity.muted,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

double _segment(double t, double start, double end) {
  if (t <= start) return 0;
  if (t >= end) return 1;
  return (t - start) / (end - start);
}

String _buildVCard({required String name, required String phone}) {
  final escapedName = name
      .replaceAll('\\', '\\\\')
      .replaceAll(';', r'\;')
      .replaceAll(',', r'\,')
      .replaceAll('\n', r'\n');

  return '''BEGIN:VCARD
VERSION:3.0
FN:$escapedName
TEL;TYPE=CELL:$phone
END:VCARD
''';
}
