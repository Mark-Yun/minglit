import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class LocationSearchPage extends ConsumerStatefulWidget {
  const LocationSearchPage({super.key});

  @override
  ConsumerState<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends ConsumerState<LocationSearchPage> {
  final _searchController = TextEditingController();
  List<PartyLocation> _results = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      unawaited(_performSearch(query));
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results =
          await ref.read(kakaoLocationRepositoryProvider).searchKeyword(query);
      setState(() => _results = results);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장소 검색'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '장소명이나 주소를 입력하세요 (예: 강남역)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
              autofocus: true,
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator()
          else if (_results.isEmpty && _searchController.text.isNotEmpty)
            const Expanded(child: Center(child: Text('검색 결과가 없습니다.'))),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final location = _results[index];
                return ListTile(
                  title: Text(location.placeName),
                  subtitle: Text(location.address),
                  onTap: () => Navigator.of(context).pop(location),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
