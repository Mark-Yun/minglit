import 'dart:async' show unawaited;

import 'package:app_partner/src/features/home/guide/partner_guide_topic.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

const double _kGuideIntroIconBoxSize =
    MinglitIconSize.large + MinglitSpacing.medium;
const double _kGuideTopicIconBoxSize =
    MinglitIconSize.medium + MinglitSpacing.sm;

class PartnerGuidePage extends StatefulWidget {
  const PartnerGuidePage({
    super.key,
    this.initialTopicSlug,
  });

  final String? initialTopicSlug;

  @override
  State<PartnerGuidePage> createState() => _PartnerGuidePageState();
}

class _PartnerGuidePageState extends State<PartnerGuidePage> {
  bool _didOpenInitialTopic = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _openInitialTopicOnce();
  }

  void _openInitialTopicOnce() {
    if (_didOpenInitialTopic || widget.initialTopicSlug == null) {
      return;
    }

    final topic = partnerGuideTopicBySlug(widget.initialTopicSlug!);
    if (topic == null) {
      return;
    }

    _didOpenInitialTopic = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(showPartnerGuideTopicSheet(context, topic));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '도움말'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(
            top: MinglitSpacing.medium,
            bottom: MinglitSpacing.xxxlarge,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
              ),
              child: _GuideIntro(colorScheme: colorScheme, theme: theme),
            ),
            const SizedBox(height: MinglitSpacing.large),
            MinglitSettingsGroup(
              header: '토픽',
              children: [
                for (final topic in partnerGuideTopics)
                  _GuideTopicTile(
                    key: ValueKey(topic.routePath),
                    topic: topic,
                    onTap: () {
                      unawaited(showPartnerGuideTopicSheet(context, topic));
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideIntro extends StatelessWidget {
  const _GuideIntro({
    required this.colorScheme,
    required this.theme,
  });

  final ColorScheme colorScheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: MinglitOpacity.tintFill),
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: MinglitOpacity.subtle),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.large),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: _kGuideIntroIconBoxSize,
              height: _kGuideIntroIconBoxSize,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(
                  alpha: MinglitOpacity.highlight,
                ),
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                color: colorScheme.primary,
                size: MinglitIconSize.medium,
              ),
            ),
            const SizedBox(width: MinglitSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '밍글릿 파트너 가이드',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.xsmall),
                  Text(
                    '운영 중 자주 확인하는 항목을 토픽별로 모았어요.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideTopicTile extends StatelessWidget {
  const _GuideTopicTile({
    required this.topic,
    required this.onTap,
    super.key,
  });

  final PartnerGuideTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: _kGuideTopicIconBoxSize,
              height: _kGuideTopicIconBoxSize,
              decoration: BoxDecoration(
                color: topic.iconColor.withValues(
                  alpha: MinglitOpacity.tintFill,
                ),
                borderRadius: BorderRadius.circular(MinglitRadius.input),
              ),
              child: Icon(
                topic.icon,
                color: topic.iconColor,
                size: MinglitIconSize.small,
              ),
            ),
            const SizedBox(width: MinglitSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: MinglitSpacing.xxsmall),
                  Text(
                    topic.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: MinglitSpacing.small),
            Icon(
              Icons.chevron_right,
              size: MinglitIconSize.small,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
