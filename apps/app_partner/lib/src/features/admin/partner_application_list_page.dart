import 'package:app_partner/src/features/admin/partner_application_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerApplicationListPage extends StatefulWidget {
  const PartnerApplicationListPage({super.key});

  @override
  State<PartnerApplicationListPage> createState() =>
      _PartnerApplicationListPageState();
}

class _PartnerApplicationListPageState
    extends State<PartnerApplicationListPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() {
    context.read<PartnerBloc>().add(
      PartnerEvent.loadAllApplications(
        status: _selectedStatus,
        searchTerm: _searchController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('입점 신청 관리')),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: BlocBuilder<PartnerBloc, PartnerState>(
              builder: (context, state) {
                return state.maybeWhen(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  applicationsLoaded: (List<PartnerApplication> applications) {
                    if (applications.isEmpty) {
                      return const Center(child: Text('신청 내역이 없습니다.'));
                    }
                    return RefreshIndicator(
                      onRefresh: () async {
                        unawaited(_loadApplications());
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: applications.length,
                        itemBuilder:
                            (context, index) =>
                                _buildApplicationCard(applications[index]),
                      ),
                    );
                  },
                  failure:
                      (msg) => Center(child: Text('Error loading data: $msg')),
                  orElse: () => const Center(child: Text('데이터를 불러오는 중입니다...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '브랜드명 또는 사업자명 검색',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: _loadApplications,
              ),
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            onSubmitted: (_) {
              unawaited(_loadApplications());
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('전체', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('대기', 'pending'),
                const SizedBox(width: 8),
                _buildFilterChip('승인', 'approved'),
                const SizedBox(width: 8),
                _buildFilterChip('반려', 'rejected'),
                const SizedBox(width: 8),
                _buildFilterChip('보완', 'needs_correction'),
              ],
            ),
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
          unawaited(_loadApplications());
        }
      },
    );
  }

  Widget _buildApplicationCard(PartnerApplication app) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          app.brandName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${app.bizName} / ${app.representativeName}'),
        trailing: _buildStatusBadge(app.status),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder:
                  (context) => PartnerApplicationDetailPage(application: app),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    var label = status;
    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = '대기';
      case 'approved':
        color = Colors.green;
        label = '승인';
      case 'rejected':
        color = Colors.red;
        label = '반려';
      case 'needs_correction':
        color = Colors.blue;
        label = '보완';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
