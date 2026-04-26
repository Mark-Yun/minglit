import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

void main() => runApp(const MdsStorybookApp());

class MdsStorybookApp extends StatelessWidget {
  const MdsStorybookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        WidgetbookCategory(
          name: 'Placeholder',
          children: [
            WidgetbookComponent(
              name: 'PlaceholderText',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const Center(
                    child: Text(
                      'mds_storybook bootstrap — components coming soon',
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'PlaceholderButton',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => Center(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('MDS Button Placeholder'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
