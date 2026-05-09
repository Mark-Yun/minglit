import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show InkWell;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:minglit_kit/minglit_core.dart';

/// Captures the current Widget Tree and Render Tree as a text dump.
/// Returns null if running on web, if capture fails, or if result is empty.
/// This is a best-effort utility — failures do not affect the caller.
Future<String?> captureLayoutDump() async {
  if (kIsWeb) return null;
  try {
    final widgetTree =
        WidgetsBinding.instance.rootElement?.toStringDeep() ?? '';

    final renderTreeParts = <String>[];
    for (final renderView in RendererBinding.instance.renderViews) {
      renderTreeParts.add(renderView.toStringDeep());
    }
    final renderTree = renderTreeParts.join('\n\n');

    if (widgetTree.isEmpty && renderTree.isEmpty) return null;

    final buffer = StringBuffer()
      ..writeln('=== WIDGET TREE ===')
      ..writeln(widgetTree)
      ..writeln()
      ..writeln('=== RENDER TREE ===')
      ..writeln(renderTree);

    return buffer.toString();
  } on Exception catch (e, st) {
    Log.e('[LayoutDump] captureLayoutDump failed', e, st);
    return null;
  }
}

/// Captures a structured JSON layout dump for non-visual worker navigation.
///
/// Walks the live element tree and collects all nodes that carry text,
/// semantics labels, or tap interactions, together with their global
/// bounding rects in logical pixels.
///
/// Returns null on web or if capture fails (best-effort — never throws).
Future<String?> captureLayoutDumpJson() async {
  if (kIsWeb) return null;
  try {
    final rootElement = WidgetsBinding.instance.rootElement;
    if (rootElement == null) return null;

    final renderViews = RendererBinding.instance.renderViews;
    if (renderViews.isEmpty) return null;
    final viewSize = renderViews.first.size;

    final nodes = <Map<String, dynamic>>[];
    _collectNodes(rootElement, nodes);

    return jsonEncode({
      'capturedAt': DateTime.now().toIso8601String(),
      'viewportSize': {
        'width': viewSize.width.round(),
        'height': viewSize.height.round(),
      },
      'nodes': nodes,
    });
  } on Exception catch (e, st) {
    Log.e('[LayoutDump] captureLayoutDumpJson failed', e, st);
    return null;
  }
}

void _collectNodes(Element element, List<Map<String, dynamic>> out) {
  final widget = element.widget;

  String? text;
  String? semanticsLabel;
  bool? onTap;

  if (widget is Text) {
    text = widget.data;
  } else if (widget is RichText) {
    text = widget.text.toPlainText();
  }

  if (widget is Semantics) {
    final label = widget.properties.label;
    if (label != null && label.isNotEmpty) semanticsLabel = label;
  }

  if (widget is GestureDetector && widget.onTap != null) onTap = true;
  if (widget is InkWell && widget.onTap != null) onTap = true;

  final isInteresting = text != null || semanticsLabel != null || onTap != null;

  if (isInteresting) {
    final ro = element.renderObject;
    if (ro is RenderBox && ro.hasSize) {
      try {
        final tl = ro.localToGlobal(Offset.zero);
        final size = ro.size;
        final node = <String, dynamic>{
          'type': widget.runtimeType.toString(),
          'rect': [
            tl.dx.round(),
            tl.dy.round(),
            (tl.dx + size.width).round(),
            (tl.dy + size.height).round(),
          ],
        };
        final key = widget.key;
        if (key != null) node['key'] = key.toString();
        if (text != null && text.isNotEmpty) node['text'] = text;
        if (semanticsLabel != null) node['semanticsLabel'] = semanticsLabel;
        if (onTap != null) node['onTap'] = onTap;
        out.add(node);
      } on Exception catch (_) {}
    }
  }

  element.visitChildren((child) => _collectNodes(child, out));
}
