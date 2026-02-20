import 'dart:async';

import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class ExploreSearchBar extends ConsumerStatefulWidget {
  const ExploreSearchBar({super.key});

  @override
  ConsumerState<ExploreSearchBar> createState() => _ExploreSearchBarState();
}

class _ExploreSearchBarState extends ConsumerState<ExploreSearchBar> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).update(value.trim());
    });
  }

  void _onClear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = ref.watch(searchQueryProvider);

    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      decoration: InputDecoration(
        hintText: '이벤트 검색',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _onClear,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: MinglitColors.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.small,
        ),
      ),
    );
  }
}
