import 'package:web/web.dart' as web;

/// Whether the current host is localhost in web builds.
bool get isLocalhost {
  final hostname = web.window.location.hostname;
  return hostname == 'localhost' || hostname == '127.0.0.1';
}
