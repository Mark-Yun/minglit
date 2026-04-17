import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// KEEP IN SYNC WITH apps/app_user/test/visual_qa/visual_qa_helper.dart

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

  /// Clears all step counters. Call in `tearDown` if needed.
  static void resetCounters() => _stepCounters.clear();

  /// Returns the base output directory for the current test.
  ///
  /// Path: `test/visual_qa/captures/ci/{sanitized_test_name}/`
  String get _captureDir {
    final sanitized = testDescription
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')
        .replaceAll(RegExp('_+'), '_')
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

  /// Captures a screenshot (PNG) and widget tree dump (.txt) of the current
  /// screen state.
  ///
  /// Files are saved as:
  /// - `{captureDir}/{step}_{label}.png`
  /// - `{captureDir}/{step}_{label}.txt`
  ///
  /// Capture failures (including invalid labels) are caught and printed —
  /// they never fail the test.
  Future<void> capture(String label) async {
    try {
      if (!_labelPattern.hasMatch(label)) {
        // ignore: avoid_print
        print('[VisualQA] invalid label "$label" — skipping capture');
        return;
      }
      final step = _nextStep();
      // Widget tree dump is synchronous — do it before the async image capture.
      _captureWidgetTree(step, label);
      // Image capture uses real async I/O and GPU rendering; must use runAsync.
      // Fix #1536: runAsync can hang in headless CI (GPU unavailable). Timeout
      // after 30 s and swallow — capture failure must never block the test.
      await runAsync(() async {
        await _captureScreenshot(step, label);
      }).timeout(
        const Duration(seconds: 30),
        onTimeout: () => null,
      );
    } catch (e, st) {
      // ignore: avoid_print
      print('[VisualQA] capture("$label") failed: $e\n$st');
    }
  }

  /// Captures before, taps [finder], settles, then captures after.
  ///
  /// tap/settle exceptions propagate — only capture failures are swallowed.
  Future<void> tapAndCapture(Finder finder, String label) async {
    await capture('${label}_before');
    Object? tapError;
    StackTrace? tapStack;
    try {
      await tap(finder);
      await pumpAndSettle();
    } catch (e, st) {
      tapError = e;
      tapStack = st;
    }
    await capture('${label}_after');
    if (tapError != null) Error.throwWithStackTrace(tapError, tapStack!);
  }

  /// Taps [finder], settles, then captures the resulting screen.
  ///
  /// tap/settle exceptions propagate — only capture failures are swallowed.
  Future<void> navigateAndCapture(Finder finder, String label) async {
    Object? tapError;
    StackTrace? tapStack;
    try {
      await tap(finder);
      await pumpAndSettle();
    } catch (e, st) {
      tapError = e;
      tapStack = st;
    }
    await capture(label);
    if (tapError != null) Error.throwWithStackTrace(tapError, tapStack!);
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
