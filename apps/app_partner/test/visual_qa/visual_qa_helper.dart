import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// VisualQA helper extension for [WidgetTester].
///
/// Captures screenshots (PNG) and widget tree dumps (.txt) at key steps
/// during widget tests. All captures are stored under
/// `test/visual_qa/captures/ci/{testName}/{step}_{label}.{ext}`.
///
/// Capture failures are swallowed — they never cause a test to fail.
extension VisualQaTester on WidgetTester {
  // Per-tester step counters, keyed by testDescription.
  static final Map<String, int> _stepCounters = {};

  static final RegExp _labelPattern = RegExp(r'^[a-z0-9_]+$');

  /// Returns the base output directory for the current test.
  ///
  /// Path: `test/visual_qa/captures/ci/{sanitized_test_name}/`
  String get _captureDir {
    final sanitized = testDescription
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .toLowerCase();
    return 'test/visual_qa/captures/ci/$sanitized';
  }

  /// Returns and increments the step counter for the current test.
  int _nextStep() {
    final key = testDescription;
    final current = _stepCounters[key] ?? 0;
    _stepCounters[key] = current + 1;
    return current + 1;
  }

  /// Validates that [label] matches `^[a-z0-9_]+$`.
  void _validateLabel(String label) {
    if (!_labelPattern.hasMatch(label)) {
      throw ArgumentError(
        'VisualQA label must match ^[a-z0-9_]+\$, got: "$label"',
      );
    }
  }

  /// Captures a screenshot (PNG) and widget tree dump (.txt) of the current
  /// screen state.
  ///
  /// Files are saved as:
  /// - `{captureDir}/{step}_{label}.png`
  /// - `{captureDir}/{step}_{label}.txt`
  ///
  /// Capture failures are caught and printed — they never fail the test.
  Future<void> capture(String label) async {
    _validateLabel(label);
    final step = _nextStep();
    try {
      // Widget tree dump is synchronous — do it before the async image capture.
      _captureWidgetTree(step, label);
      // Image capture uses real async I/O and GPU rendering; must use runAsync.
      await runAsync(() async {
        await _captureScreenshot(step, label);
      });
    } catch (e, st) {
      // ignore: avoid_print
      print('[VisualQA] capture("$label") failed: $e\n$st');
    }
  }

  /// Captures before, taps [finder], settles, then captures after.
  Future<void> tapAndCapture(Finder finder, String label) async {
    _validateLabel(label);
    await capture('${label}_before');
    try {
      await tap(finder);
      await pumpAndSettle();
    } catch (e, st) {
      // ignore: avoid_print
      print('[VisualQA] tapAndCapture("$label") tap/settle failed: $e\n$st');
    }
    await capture('${label}_after');
  }

  /// Taps [finder], settles, then captures the resulting screen.
  Future<void> navigateAndCapture(Finder finder, String label) async {
    _validateLabel(label);
    try {
      await tap(finder);
      await pumpAndSettle();
    } catch (e, st) {
      // ignore: avoid_print
      print(
        '[VisualQA] navigateAndCapture("$label") tap/settle failed: $e\n$st',
      );
    }
    await capture(label);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<void> _captureScreenshot(int step, String label) async {
    final image = await _renderToImage();
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('toByteData returned null for step $step "$label"');
    }
    final bytes = Uint8List.view(byteData.buffer);
    final file = _ensureFile('${step}_$label.png');
    await file.writeAsBytes(bytes, flush: true);
  }

  void _captureWidgetTree(int step, String label) {
    final element = binding.rootElement;
    if (element == null) return;
    final dump = element.toStringDeep();
    final file = _ensureFile('${step}_$label.txt');
    file.writeAsStringSync(dump);
  }

  File _ensureFile(String filename) {
    final dir = Directory(_captureDir);
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return File('${dir.path}/$filename');
  }

  /// Renders the root render view to a [ui.Image].
  ///
  /// Uses [captureImage] from flutter_test when a root element is available.
  /// Falls back to the render view's layer tree otherwise.
  Future<ui.Image> _renderToImage() async {
    // Try flutter_test's built-in captureImage using the root element.
    final rootElement = binding.rootElement;
    if (rootElement != null) {
      // captureImage walks up to the nearest repaint boundary automatically.
      return captureImage(rootElement);
    }

    // Fallback: use the render view layer directly.
    final renderView = binding.renderViews.first;
    final layer = renderView.debugLayer;
    if (layer is OffsetLayer) {
      return layer.toImage(renderView.paintBounds);
    }

    throw StateError('Could not find a paintable layer to capture.');
  }
}
