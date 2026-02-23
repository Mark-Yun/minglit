import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/repositories/auth_repository.dart';
import 'package:minglit_kit/src/features/notification/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens to authentication state changes and initializes notifications on
/// sign-in.
///
/// This provider automatically calls [NotificationService.initialize()] when
/// the user signs in, ensuring that FCM tokens, local notifications, and deep
/// link handlers are properly set up.
final notificationInitializerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<AuthState>>(
    authStateChangesProvider,
    (prev, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedIn) {
          unawaited(ref.read(notificationServiceProvider).initialize());
        }
      });
    },
  );
});
