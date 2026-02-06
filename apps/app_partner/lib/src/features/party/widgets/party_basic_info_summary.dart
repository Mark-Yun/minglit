import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyBasicInfoSummary extends StatefulWidget {
  const PartyBasicInfoSummary({
    required this.title,
    required this.description,
    this.imageFiles = const [],
    this.imageUrls = const [],
    this.status,
    this.showFullDescription = false,
    this.showTitle = true,
    this.viewOnly = true,
    this.collapsible = false,
    super.key,
  });

  final String title;
  final Map<String, dynamic> description;
  final List<XFile> imageFiles;
  final List<String> imageUrls;
  final String? status;
  final bool showFullDescription;
  final bool showTitle;
  final bool viewOnly;
  final bool collapsible;

  @override
  State<PartyBasicInfoSummary> createState() => _PartyBasicInfoSummaryState();
}

class _PartyBasicInfoSummaryState extends State<PartyBasicInfoSummary> {
  late bool _isExpanded;
  quill.QuillController? _quillController;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.collapsible || widget.showFullDescription;
  }

  @override
  void dispose() {
    _quillController?.dispose();
    super.dispose();
  }

  quill.QuillController _getController(List<dynamic> ops) {
    return _quillController ??= quill.QuillController(
      document: quill.Document.fromJson(ops),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: widget.viewOnly,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final ops = widget.description['ops'] as List?;
    final isDescriptionEmpty =
        ops == null ||
        ops.isEmpty ||
        (ops.length == 1 && (ops[0] as Map<String, dynamic>)['insert'] == '\n');

    final combinedPaths = [
      ...widget.imageUrls,
      ...widget.imageFiles.map((f) => f.path),
    ];

    String? statusLabel;
    Color? statusColor;
    if (widget.status != null) {
      switch (widget.status) {
        case 'active':
          statusLabel = '운영중';
          statusColor = MinglitColors.primary;
        case 'draft':
          statusLabel = '임시저장';
          statusColor = colorScheme.outline;
        case 'closed':
          statusLabel = '종료됨';
          statusColor = MinglitColors.error;
      }
    }
    final resolvedStatusColor = statusColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (combinedPaths.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              child: MinglitImageCarousel(
                imageUrls: combinedPaths,
                height: 200,
              ),
            ),
          ),

        if (widget.showTitle)
          Row(
            children: [
              if (statusLabel != null && resolvedStatusColor != null)
                Padding(
                  padding: const EdgeInsets.only(right: MinglitSpacing.small),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: resolvedStatusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(MinglitRadius.small),
                      border: Border.all(
                        color: resolvedStatusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: resolvedStatusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  widget.title.isEmpty
                      ? context.l10n.wizard_review_noTitle
                      : widget.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: widget.title.isEmpty
                        ? colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
              ),
            ],
          ),
        if (widget.showTitle) const SizedBox(height: MinglitSpacing.small),

        if (isDescriptionEmpty)
          Text(
            context.l10n.wizard_review_noDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          if (widget.collapsible)
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(MinglitRadius.small),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: MinglitSpacing.xsmall,
                ),
                child: Row(
                  children: [
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isExpanded ? '상세 설명 접기' : '상세 설명 보기',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_isExpanded)
            Container(
              margin: const EdgeInsets.only(top: MinglitSpacing.xsmall),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(MinglitRadius.card),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                children: [
                  if (!widget.viewOnly)
                    quill.QuillSimpleToolbar(
                      controller: _getController(ops),
                      config: MinglitQuillTheme.toolbarConfig(context),
                    ),
                  if (!widget.viewOnly) const Divider(height: 1),
                  quill.QuillEditor.basic(
                    controller: _getController(ops),
                    config: MinglitQuillTheme.editorConfig(
                      context,
                      placeholder: '',
                    ).copyWith(autoFocus: false, expands: false),
                  ),
                ],
              ),
            )
          else if (!widget.collapsible)
            Text(
              context.l10n.wizard_review_descriptionDone,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ],
    );
  }
}
