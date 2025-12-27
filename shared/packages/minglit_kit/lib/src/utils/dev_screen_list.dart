import 'dart:async';

import 'package:flutter/material.dart';

/// Item representing a screen in the Dev Map.
class DevScreenItem {
  /// Creates a [DevScreenItem].
  DevScreenItem({
    required this.title,
    required this.screenBuilder,
    this.description,
  });

  /// The title of the screen.
  final String title;

  /// Builder for the screen widget.
  final WidgetBuilder screenBuilder;

  /// Optional description of the screen.
  final String? description;
}

/// A list view for displaying and navigating to development screens.
class DevScreenList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$appName Dev Map 🛠️'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final item = items[index];
          return ListTile(
            title: Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: item.description != null ? Text(item.description!) : null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              unawaited(
                Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: item.screenBuilder),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
