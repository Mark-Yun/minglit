import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/debug/user_session_info.dart';

/// Item representing a screen in the Dev Map.
class DevScreenItem {
  /// Creates a [DevScreenItem].
  ///
  /// Either [screenBuilder] or [onTap] must be provided.
  DevScreenItem({
    required this.title,
    this.screenBuilder,
    this.onTap,
    this.category,
    this.description,
  }) : assert(
         screenBuilder != null || onTap != null,
         'Either screenBuilder or onTap must be provided',
       );

  /// The title of the screen.
  final String title;

  /// Builder for the screen widget.
  final WidgetBuilder? screenBuilder;

  /// Optional callback to execute directly instead of navigation.
  final void Function(BuildContext context, WidgetRef ref)? onTap;

  /// Category of the screen for grouping.
  final String? category;

  /// Optional description of the screen.
  final String? description;
}

/// A list view for displaying and navigating to development screens.
class DevScreenList extends ConsumerWidget {
  /// Creates a [DevScreenList].
  const DevScreenList({
    required this.appName,
    required this.items,
    super.key,
  });

  /// The name of the app.
  final String appName;

  /// List of items to display.
  final List<DevScreenItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Group items by category
    final groupedItems = <String, List<DevScreenItem>>{};
    for (final item in items) {
      final category = item.category ?? 'Uncategorized';
      groupedItems.putIfAbsent(category, () => []).add(item);
    }

    final categories = groupedItems.keys.toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          MinglitTheme.sliverAppBar(title: '$appName Dev Map 🛠️'),
          const SliverToBoxAdapter(
            child: UserSessionInfo(),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, catIndex) {
                final category = categories[catIndex];
                final categoryItems = groupedItems[category]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: MinglitSpacing.medium,
                        vertical: MinglitSpacing.sm,
                      ),
                      color: theme.colorScheme.surfaceContainerLowest,
                      child: Text(
                        category.toUpperCase(),
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: MinglitColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...categoryItems.map((item) {
                      final isAction = item.onTap != null;
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: MinglitSpacing.large,
                              vertical: MinglitSpacing.xsmall,
                            ),
                            title: Text(
                              item.title,
                              style: theme.textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: item.description != null
                                ? Text(
                                    item.description!,
                                    style: theme.textTheme.bodyMedium!.copyWith(
                                      color: MinglitColors.textSecondary,
                                    ),
                                  )
                                : null,
                            trailing: Icon(
                              isAction
                                  ? Icons.touch_app
                                  : Icons.arrow_forward_ios,
                              size: 14,
                            ),
                            onTap: () {
                              if (item.onTap != null) {
                                item.onTap!(context, ref);
                              } else if (item.screenBuilder != null) {
                                unawaited(
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute(
                                      builder: item.screenBuilder!,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                          if (item != categoryItems.last)
                            const Divider(height: 1, indent: 20, endIndent: 20),
                        ],
                      );
                    }),
                  ],
                );
              },
              childCount: categories.length,
            ),
          ),
        ],
      ),
    );
  }
}
