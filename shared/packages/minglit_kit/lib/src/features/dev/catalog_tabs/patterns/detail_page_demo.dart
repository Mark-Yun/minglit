import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/src/features/dev/catalog_tabs/patterns/mock_data.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_content_card.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_empty_state.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_error_state.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_section.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_skeleton.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_tag.dart';

/// Demo states for pattern preview.
enum DemoState { data, loading, error, empty }

/// P1 — Detail Page Pattern Demo.
///
/// Demonstrates Hero + TabBar + CTA structure with a full-screen push.
/// Includes [DemoState] toggle (data / loading / error / empty).
///
/// Launch via [Navigator.push]:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailPageDemo()));
/// ```
class DetailPageDemo extends StatefulWidget {
  /// Creates a [DetailPageDemo].
  const DetailPageDemo({super.key});

  @override
  State<DetailPageDemo> createState() => _DetailPageDemoState();
}

class _DetailPageDemoState extends State<DetailPageDemo>
    with SingleTickerProviderStateMixin {
  DemoState _state = DemoState.data;
  late final TabController _tabController;

  static const _tabs = ['개요', '참여자', '일정'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          // State toggle
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: SegmentedButton<DemoState>(
                segments: const [
                  ButtonSegment(value: DemoState.data, label: Text('Data')),
                  ButtonSegment(
                    value: DemoState.loading,
                    label: Text('Loading'),
                  ),
                  ButtonSegment(value: DemoState.error, label: Text('Error')),
                  ButtonSegment(value: DemoState.empty, label: Text('Empty')),
                ],
                selected: {_state},
                onSelectionChanged: (s) => setState(() => _state = s.first),
              ),
            ),
          ),
          // Preview area
          Expanded(child: _buildPreview(theme)),
        ],
      ),
    );
  }

  Widget _buildPreview(ThemeData theme) {
    return switch (_state) {
      DemoState.loading => _DetailPageLoading(tabController: _tabController),
      DemoState.error => _DetailPageError(
        onRetry: () => setState(() => _state = DemoState.data),
      ),
      DemoState.empty => const _DetailPageEmpty(),
      DemoState.data => _DetailPageData(
        event: mockEvents.first,
        tabController: _tabController,
        tabs: _tabs,
        onAction: () {
          unawaited(
            showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('참여 신청'),
                content: const Text('이벤트에 참여 신청하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('신청'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    };
  }
}

// ---------------------------------------------------------------------------
// Data state
// ---------------------------------------------------------------------------

class _DetailPageData extends StatelessWidget {
  const _DetailPageData({
    required this.event,
    required this.tabController,
    required this.tabs,
    required this.onAction,
  });

  final MockEventData event;
  final TabController tabController;
  final List<String> tabs;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  event.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                background: ColoredBox(
                  color: MinglitColors.primary,
                  child: Center(
                    child: Icon(
                      Icons.event,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: tabController,
                tabs: tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ],
          body: TabBarView(
            controller: tabController,
            children: [
              _OverviewTab(event: event),
              _ParticipantsTab(count: event.currentParticipants),
              const _ScheduleTab(),
            ],
          ),
        ),
        // CTA
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _CtaBar(
            label:
                '참여 신청 (${event.currentParticipants}/${event.maxParticipants})',
            onTap: onAction,
          ),
        ),
      ],
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.event});

  final MockEventData event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.medium,
        MinglitSpacing.medium,
        MinglitSpacing.medium,
        MinglitSpacing.xlarge * 2,
      ),
      children: [
        MinglitTag(label: event.categoryLabel, color: MinglitColors.primary),
        const SizedBox(height: MinglitSpacing.small),
        Text(event.subtitle, style: theme.textTheme.bodyLarge),
        const SizedBox(height: MinglitSpacing.medium),
        MinglitContentCard(
          child: Column(
            children: [
              _InfoRow(icon: Icons.calendar_today, text: event.dateLabel),
              const SizedBox(height: MinglitSpacing.small),
              _InfoRow(icon: Icons.location_on, text: event.locationLabel),
              const SizedBox(height: MinglitSpacing.small),
              _InfoRow(icon: Icons.person, text: '주최: ${event.hostName}'),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: MinglitIconSize.small),
        const SizedBox(width: MinglitSpacing.small),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _ParticipantsTab extends StatelessWidget {
  const _ParticipantsTab({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: count,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, i) => ListTile(
        leading: CircleAvatar(child: Text('${i + 1}')),
        title: Text('참여자 ${i + 1}', style: theme.textTheme.bodyMedium),
        subtitle: Text('승인됨', style: theme.textTheme.bodySmall),
      ),
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: mockSectionItems.length,
      itemBuilder: (context, i) => MinglitSection(
        title: mockSectionItems[i],
        child: Text(
          '${mockSectionItems[i]} 상세 내용이 여기에 표시됩니다.',
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _CtaBar extends StatelessWidget {
  const _CtaBar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.medium,
        MinglitSpacing.small,
        MinglitSpacing.medium,
        MinglitSpacing.large,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          child: Text(label),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading state
// ---------------------------------------------------------------------------

class _DetailPageLoading extends StatelessWidget {
  const _DetailPageLoading({required this.tabController});

  final TabController tabController;

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, _) => [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: const FlexibleSpaceBar(
            background: MinglitSkeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.zero,
            ),
          ),
          bottom: TabBar(
            controller: tabController,
            tabs: const [
              Tab(text: '개요'),
              Tab(text: '참여자'),
              Tab(text: '일정'),
            ],
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        children: [
          const MinglitSkeleton(width: 80, height: 24),
          const SizedBox(height: MinglitSpacing.small),
          const MinglitSkeleton(width: double.infinity, height: 20),
          const SizedBox(height: MinglitSpacing.xsmall),
          const MinglitSkeleton(width: 200, height: 20),
          const SizedBox(height: MinglitSpacing.medium),
          MinglitSkeleton(
            width: double.infinity,
            height: 100,
            borderRadius: BorderRadius.circular(MinglitRadius.card),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _DetailPageError extends StatelessWidget {
  const _DetailPageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MinglitErrorState(
        title: '이벤트 정보를 불러올 수 없습니다',
        subtitle: '잠시 후 다시 시도해주세요',
        onRetry: onRetry,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _DetailPageEmpty extends StatelessWidget {
  const _DetailPageEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: MinglitEmptyState(
        title: '표시할 이벤트가 없습니다',
        subtitle: '새로운 이벤트를 찾아보세요',
      ),
    );
  }
}
