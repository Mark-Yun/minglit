// This file is specific to Web and requires JS interop.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:js' as js;

import 'package:minglit_kit/minglit_kit.dart';

/// Web implementation using dart:js.
void requestCertificationWeb({
  required String userCode,
  required Map<String, dynamic> data,
  required void Function(Map<String, String>) onResult,
}) {
  final callbackName =
      'onIamportResult_${DateTime.now().millisecondsSinceEpoch}';

  // 1. Register global callback for JS to call Dart
  // ignore: undefined_function
  js.context[callbackName] = js.allowInterop((String jsonResult) {
    final decoded = jsonDecode(jsonResult) as Map<String, dynamic>;

    // Convert all values to String to match iamport_flutter's expected type
    final stringMap = decoded.map((key, value) {
      return MapEntry(key, value?.toString() ?? '');
    });

    onResult(stringMap);
  });

  // 2. Call the helper function in index.html
  final minglitIamport = js.context['MinglitIamport'];
  if (minglitIamport != null) {
    // The MinglitIamport object is defined in index.html as a
    // dynamic JS object.
    // ignore: avoid_dynamic_calls
    minglitIamport.callMethod('certification', [
      userCode,
      jsonEncode(data),
      callbackName,
    ]);
  } else {
    Log.e('MinglitIamport JS object not found in index.html');
  }
}
