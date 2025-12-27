import 'dart:async';

import 'package:app_partner/src/features/admin/partner_application_detail_page.dart'; // 수정됨
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
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadApplications());
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final repository = locator<PartnerRepository>();
      final apps = await repository.getAllApplications(
        status: _selectedStatus,
        searchTerm: _searchController.text,
      );
      setState(() {
        _applications =
            apps
                .map((a) => a.toJson())
                .toList(); // 기존 Map 기반 코드 호환성을 위해 toJson 사용
        _isLoading = false;
      });
    } on Exception catch (e) {
      Log.e('Load applications error', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('입점 신청 관리')),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _applications.isEmpty
                    ? const Center(child: Text('신청 내역이 없습니다.'))
                    : RefreshIndicator(
                      onRefresh: () async => _loadApplications(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _applications.length,
                        itemBuilder:
                            (context, index) =>
                                _buildApplicationCard(_applications[index]),
                      ),
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
                icon: const Icon(Icons.send),
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
          Row(
            children: [
              _buildFilterChip('전체', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('대기', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('승인', 'approved'),
              const SizedBox(width: 8),
              _buildFilterChip('반려', 'rejected'),
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
          unawaited(_loadApplications());
        }
      },
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          app['brand_name'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${app['biz_name'] as String} / ${app['representative_name'] as String}',
        ),
        trailing: _buildStatusBadge(app['status'] as String),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute<bool>(
              builder:
                  (context) => PartnerApplicationDetailPage(application: app),
            ),
          );
          if (result ?? false) await _loadApplications();
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
