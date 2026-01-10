import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'url_config.g.dart';

/// Defines base domains for different environments.
class MinglitDomains {
  const MinglitDomains({
    required this.userWeb,
    required this.partnerWeb,
  });

  /// Production environment (Default)
  /// User: https://minglit.com
  /// Partner: https://partner.minglit.com
  const MinglitDomains.production()
      : userWeb = 'https://minglit.com',
        partnerWeb = 'https://partner.minglit.com';

  /// Development environment
  /// User: https://dev.minglit.com
  /// Partner: https://dev.partner.minglit.com
  const MinglitDomains.dev()
      : userWeb = 'https://dev.minglit.com',
        partnerWeb = 'https://dev.partner.minglit.com';

  /// Local environment (connecting to local Next.js servers)
  /// User: http://localhost:3000
  /// Partner: http://localhost:3001
  const MinglitDomains.local()
      : userWeb = 'http://localhost:3000',
        partnerWeb = 'http://localhost:3001';

  final String userWeb;
  final String partnerWeb;
}

/// Provides specific URLs based on the current [MinglitDomains].
class MinglitUrlConfig {
  const MinglitUrlConfig(this._domains);

  final MinglitDomains _domains;

  // --- User Side URLs ---

  /// Main Landing Page
  String get landingHome => _domains.userWeb;

  /// Terms of Service
  String get termsUrl => '${_domains.userWeb}/terms';

  /// Privacy Policy
  String get privacyUrl => '${_domains.userWeb}/privacy';

  // --- Partner Side URLs ---

  /// Partner Landing Page
  String get partnerHome => _domains.partnerWeb;

  /// Partner Inquiry / Intro
  String get partnerInquiryUrl => _domains.partnerWeb;
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
  return MinglitUrlConfig(domains);
}
