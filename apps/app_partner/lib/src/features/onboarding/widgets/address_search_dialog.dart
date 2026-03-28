import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class AddressSearchDialog extends StatefulWidget {
  const AddressSearchDialog({super.key});

  @override
  State<AddressSearchDialog> createState() => _AddressSearchDialogState();
}

class _AddressSearchDialogState extends State<AddressSearchDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final keyword = _searchController.text.trim();
    if (keyword.length < 2) {
      setState(() {
        _errorMessage = '두 글자 이상 입력해주세요';
        _results = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _results = [];
    });

    try {
      const confmKey = String.fromEnvironment('JUSO_CONFIRM_KEY');
      final uri = Uri.https(
        'www.juso.go.kr',
        '/addrlink/addrLinkApi.do',
        {
          'confmKey': confmKey,
          'keyword': keyword,
          'currentPage': '1',
          'countPerPage': '20',
          'resultType': 'json',
        },
      );

      final client = HttpClient();
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      // Fix #270: 외부 API 응답 안전 캐스팅 — API 변경 시 TypeError 방지
      final results = decoded['results'];
      if (results is! Map<String, dynamic>) {
        if (mounted) {
          setState(() {
            _errorMessage = '주소 검색 응답 형식이 올바르지 않습니다';
            _results = [];
            _isLoading = false;
          });
        }
        return;
      }
      final common = results['common'];
      if (common is! Map<String, dynamic>) {
        if (mounted) {
          setState(() {
            _errorMessage = '주소 검색 응답 형식이 올바르지 않습니다';
            _results = [];
            _isLoading = false;
          });
        }
        return;
      }
      final errorCode = common['errorCode'] as String? ?? '';

      if (errorCode != '0') {
        setState(() {
          _errorMessage = common['errorMessage'] as String? ?? '오류가 발생했습니다';
          _results = [];
          _isLoading = false;
        });
        return;
      }

      final juso = results['juso'] as List<dynamic>?;
      if (juso == null || juso.isEmpty) {
        setState(() {
          _errorMessage = '검색 결과가 없습니다';
          _results = [];
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _results = juso.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } on Exception catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '네트워크 연결을 확인해주세요';
        _results = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주소 검색'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MinglitSpacing.medium,
              MinglitSpacing.sm,
              MinglitSpacing.medium,
              MinglitSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '도로명 또는 지번 주소를 입력하세요',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: MinglitSpacing.small),
                IconButton.filled(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (_isLoading)
            const Expanded(
              child: Center(child: MinglitCircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else if (_results.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  '위 검색창에 주소를 입력하고 검색 버튼을 눌러주세요',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _results.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _results[index];
                  final roadAddr = item['roadAddr'] as String? ?? '';
                  final jibunAddr = item['jibunAddr'] as String? ?? '';
                  return ListTile(
                    title: Text(roadAddr),
                    subtitle: Text(
                      jibunAddr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    onTap: () => Navigator.of(context).pop(roadAddr),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
