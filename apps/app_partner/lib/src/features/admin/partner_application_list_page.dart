import 'package:app_partner/src/features/admin/admin_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'partner_application_list_page.g.dart';

@riverpod
Future<List<PartnerApplication>> partnerApplications(
  Ref ref, {
  String status = 'all',
  String? searchTerm,
}) async {
  return ref
      .read(partnerRepositoryProvider)
      .getAllApplications(status: status, searchTerm: searchTerm);
}

class PartnerApplicationListPage extends ConsumerStatefulWidget {
  const PartnerApplicationListPage({super.key});

  @override
  ConsumerState<PartnerApplicationListPage> createState() =>
      _PartnerApplicationListPageState();
}

class _PartnerApplicationListPageState
    extends ConsumerState<PartnerApplicationListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(
      partnerApplicationsProvider(
        status: _selectedStatus,
        searchTerm: _searchController.text,
      ),
    );

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '입점 신청 관리'),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: MinglitAsyncValueWidget(
              value: appsAsync,
              data: (apps) {
                if (apps.isEmpty) {
                  return const Center(child: Text('신청 내역이 없습니다.'));
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(
                    partnerApplicationsProvider(
                      status: _selectedStatus,
                      searchTerm: _searchController.text,
                    ).future,
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(MinglitSpacing.medium),
                    itemCount: apps.length,
                    itemBuilder: (context, index) =>
                        _buildApplicationCard(apps[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '브랜드명 또는 사업자명 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {}); // Trigger rebuild to update provider params
                },
              ),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onSubmitted: (_) {
              setState(() {});
            },
          ),
          const SizedBox(height: MinglitSpacing.small),
          // Fix #477: Container already has horizontal padding — zero out ChipGroup default padding
          MinglitChipGroup(
            padding: EdgeInsets.zero,
            children: [
              _buildFilterChip('전체', 'all'),
              _buildFilterChip('대기', 'pending'),
              _buildFilterChip('승인', 'approved'),
              _buildFilterChip('반려', 'rejected'),
              _buildFilterChip('보완', 'needs_correction'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedStatus = value);
        }
      },
    );
  }

  Widget _buildApplicationCard(PartnerApplication app) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: MinglitSpacing.small),
      child: ListTile(
        title: Text(
          app.brandName ?? '-',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${app.bizName ?? '-'} / ${app.representativeName ?? '-'}',
        ),
        trailing: _buildStatusBadge(app.status),
        onTap: () {
          ref
              .read(adminCoordinatorProvider.notifier)
              .goToApplicationDetail(app.id);
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final theme = Theme.of(context);
    var color = theme.colorScheme.outline;
    var label = status;
    switch (status) {
      case 'pending':
        color = theme.colorScheme.secondary;
        label = '대기';
      case 'approved':
        color = theme.colorScheme.tertiary;
        label = '승인';
      case 'rejected':
        color = theme.colorScheme.error;
        label = '반려';
      case 'needs_correction':
        color = theme.colorScheme.primary;
        label = '보완';
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xxsmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MinglitSpacing.xxsmall),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
