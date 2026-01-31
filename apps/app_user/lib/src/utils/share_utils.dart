import 'package:share_plus/share_plus.dart';

class ShareUtils {
  const ShareUtils._();

  static const String defaultBaseUrl = 'https://minglit.app';

  static Uri eventUrl({required String eventId, String? baseUrl}) {
    final origin = _normalizeBaseUrl(baseUrl);
    return Uri.parse('$origin/events/$eventId');
  }

  static String eventShareText({
    required String eventTitle,
    required String eventId,
    String? baseUrl,
  }) {
    final title = eventTitle.trim().isEmpty ? '이벤트' : eventTitle.trim();
    final url = eventUrl(eventId: eventId, baseUrl: baseUrl).toString();
    return '$title\n$url';
  }

  static Future<void> shareEvent({
    required String eventTitle,
    required String eventId,
    String? baseUrl,
  }) {
    final text = eventShareText(
      eventTitle: eventTitle,
      eventId: eventId,
      baseUrl: baseUrl,
    );
    return SharePlus.instance.share(ShareParams(text: text));
  }

  static String _normalizeBaseUrl(String? baseUrl) {
    final resolved = (baseUrl?.trim().isNotEmpty ?? false)
        ? baseUrl!.trim()
        : defaultBaseUrl;
    if (resolved.endsWith('/')) {
      return resolved.substring(0, resolved.length - 1);
    }
    return resolved;
  }
}
