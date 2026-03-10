import 'package:flutter/foundation.dart';
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
