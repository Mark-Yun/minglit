import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_content_card.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_image.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_key_value_row.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_participant_gauge.dart';

/// Design catalog tab displaying data display widgets.
class DataSection extends StatelessWidget {
  /// Creates a [DataSection].
  const DataSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // MinglitParticipantGauge
        Text('MinglitParticipantGauge', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Row(
          children: [
            Expanded(
              child: MinglitContentCard(
                child: Column(
                  children: [
                    Text('25%'),
                    SizedBox(height: MinglitSpacing.small),
                    MinglitParticipantGauge(current: 5, max: 20),
                  ],
                ),
              ),
            ),
            SizedBox(width: MinglitSpacing.small),
            Expanded(
              child: MinglitContentCard(
                child: Column(
                  children: [
                    Text('50%'),
                    SizedBox(height: MinglitSpacing.small),
                    MinglitParticipantGauge(current: 10, max: 20),
                  ],
                ),
              ),
            ),
            SizedBox(width: MinglitSpacing.small),
            Expanded(
              child: MinglitContentCard(
                child: Column(
                  children: [
                    Text('90%'),
                    SizedBox(height: MinglitSpacing.small),
                    MinglitParticipantGauge(current: 18, max: 20),
                  ],
                ),
              ),
            ),
          ],
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitKeyValueRow (cross-ref from Layout)
        Text('MinglitKeyValueRow', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitContentCard(
          child: Column(
            children: [
              MinglitKeyValueRow(label: '주최', value: '밍글릿'),
              MinglitKeyValueRow(label: '장소', value: '강남 스퀘어'),
              MinglitKeyValueRow(label: '참가비', value: '₩15,000'),
            ],
          ),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitImage
        Text('MinglitImage', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Network image with automatic placeholder/error handling.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitContentCard(
          child: MinglitImage(
            path: 'https://picsum.photos/400/200',
            height: 150,
          ),
        ),
      ],
    );
  }
}
