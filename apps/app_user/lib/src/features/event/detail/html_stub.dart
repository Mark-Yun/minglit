// Stub for dart:html when not on web platform
class Window {
  final String userAgent = '';
  final Navigator navigator = Navigator();
}

class Navigator {
  final String userAgent = '';
}

final Window window = Window();
