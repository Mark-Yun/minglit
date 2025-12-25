import 'package:flutter/material.dart';

class DevScreenItem {
  final String title;
  final WidgetBuilder screenBuilder;
  final String? description;

  DevScreenItem({
    required this.title,
    required this.screenBuilder,
    this.description,
  });
}

class DevScreenList extends StatelessWidget {
  final String appName;
  final List<DevScreenItem> items;

  const DevScreenList({
    super.key,
    required this.appName,
    required this.items,
  });

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
              Navigator.push(
                context,
                MaterialPageRoute(builder: item.screenBuilder),
              );
            },
          );
        },
      ),
    );
  }
}
