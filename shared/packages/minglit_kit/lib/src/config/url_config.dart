import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'url_config.g.dart';

/// Defines base domains for different environments.
class MinglitDomains {
  /// Creates a [MinglitDomains] set for custom environments.
  const MinglitDomains({
    required this.userWeb,
    required this.partnerWeb,
    required this.userApp,
    required this.partnerApp,
  });

  /// Production environment (Default)
  const MinglitDomains.production()
      : userWeb = 'https://minglit.com',
        partnerWeb = 'https://partner.minglit.com',
        userApp = 'https://app.minglit.com',
        partnerApp = 'https://app.partner.minglit.com';

  /// Development environment
  const MinglitDomains.dev()
      : userWeb = 'https://dev.minglit.com',
        partnerWeb = 'https://dev.partner.minglit.com',
        userApp = 'https://dev.app.minglit.com',
        partnerApp = 'https://dev.app.partner.minglit.com';

  /// Local environment
  const MinglitDomains.local()
      : userWeb = 'http://localhost:3002',
        partnerWeb = 'http://localhost:3003',
        userApp = 'http://localhost:3000',
        partnerApp = 'http://localhost:3001';

  /// Base domain for the user-facing website.
  final String userWeb;

  /// Base domain for the partner-facing website.
  final String partnerWeb;

  /// Base domain for the user app.
  final String userApp;

  /// Base domain for the partner app.
  final String partnerApp;
}

/// Provides specific URLs based on the current [MinglitDomains].
class MinglitUrlConfig {
  /// Creates a [MinglitUrlConfig] for the given domains.
  const MinglitUrlConfig(this._domains, {this.currentOrigin});

  /// Domains used to compose URLs.
  final MinglitDomains _domains;

  /// Current web origin, if available.
  final String? currentOrigin;

  // --- User Side (Landing) URLs ---

  /// Main Landing Page
  String get landingHome => _domains.userWeb;

  /// Terms of Service
  String get termsUrl => '${_domains.userWeb}/terms';

  /// Privacy Policy
  String get privacyUrl => '${_domains.userWeb}/privacy';

  // --- Partner Side (Landing) URLs ---

  /// Partner Landing Page
  String get partnerHome => _domains.partnerWeb;

  /// Partner Inquiry / Intro
  String get partnerInquiryUrl => _domains.partnerWeb;

  // --- Auth & App URLs ---

  /// The redirect URL for authentication flows (Magic Link, OAuth).
  /// On Web, this prefers the current browser origin (to support Dev/Preview URLs).
  /// On Native, it falls back to the configured Partner App URL.
  String get authRedirectUrl {
    if (currentOrigin != null && currentOrigin!.startsWith('http')) {
      return currentOrigin!;
    }
    return _domains.partnerApp;
  }
}

/// Holds the current environment domains.
/// Override this provider in `dev_main.dart` to switch environments.
@Riverpod(keepAlive: true)
MinglitDomains minglitDomains(Ref ref) {
  return const MinglitDomains.production();
}

/// Computes the final URLs based on [minglitDomainsProvider].
@Riverpod(keepAlive: true)
MinglitUrlConfig minglitUrlConfig(Ref ref) {
  final domains = ref.watch(minglitDomainsProvider);

  String? origin;
  if (kIsWeb) {
    try {
      origin = Uri.base.origin;
    } on Object catch (_) {
      // Ignore if Uri.base fails (unlikely on web)
    }
  }

  return MinglitUrlConfig(domains, currentOrigin: origin);
}
