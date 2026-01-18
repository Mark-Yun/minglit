import 'package:web/web.dart' as web;

bool get isLocalhost {
  final hostname = web.window.location.hostname;
  return hostname == 'localhost' || hostname == '127.0.0.1';
}
