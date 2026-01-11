import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'url_config.g.dart';

/// Defines base domains for different environments.
class MinglitDomains {
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

  final String userWeb;
  final String partnerWeb;
  final String userApp;
  final String partnerApp;
}

/// Provides specific URLs based on the current [MinglitDomains].
class MinglitUrlConfig {
  const MinglitUrlConfig(this._domains, {this.currentOrigin});

  final MinglitDomains _domains;
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
