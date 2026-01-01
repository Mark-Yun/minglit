import 'package:app_partner/src/features/search/location/location_search_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class LocationSearchPage extends ConsumerStatefulWidget {
  const LocationSearchPage({super.key});

  @override
  ConsumerState<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends ConsumerState<LocationSearchPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(locationSearchControllerProvider);
    final controller = ref.read(locationSearchControllerProvider.notifier);

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
              onChanged: controller.onSearchChanged,
              autofocus: true,
            ),
          ),
          if (searchAsync.isLoading) const LinearProgressIndicator(),
          Expanded(
            child: searchAsync.when(
              data: (results) {
                if (results.isEmpty && _searchController.text.isNotEmpty) {
                  return const Center(child: Text('검색 결과가 없습니다.'));
                }
                return ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final location = results[index];
                    return ListTile(
                      title: Text(location.name),
                      subtitle: Text(location.address),
                      onTap: () => Navigator.of(context).pop(location),
                    );
                  },
                );
              },
              error: (e, st) => Center(child: Text('에러 발생: $e')),
              loading: () =>
                  const SizedBox.shrink(), // handled by LinearProgressIndicator
            ),
          ),
        ],
      ),
    );
  }
}
