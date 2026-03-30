import 'package:supabase_flutter/supabase_flutter.dart';

/// Returns whether the current user has a password credential configured.
bool hasPasswordCredential(User user) {
  final hasPassword = user.appMetadata['has_password'];
  if (hasPassword is bool) {
    return hasPassword;
  }

  if (hasPassword is String) {
    return hasPassword.toLowerCase() == 'true';
  }

  return false;
}
