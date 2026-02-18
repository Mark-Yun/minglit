import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/features/auth/logic/staff_guard_provider.dart';
import 'package:minglit_kit/src/features/auth/ui/staff_gate_screen.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/utils/platform_utils.dart';
import 'package:minglit_kit/src/utils/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps [child] with staff-only access checks.
class StaffGuardWrapper extends ConsumerStatefulWidget {
  /// Creates a wrapper that enforces staff verification.
  const StaffGuardWrapper({required this.child, super.key});

  /// The widget displayed once staff access is verified.
  final Widget child;

  /// Creates the state for the staff guard wrapper.
  @override
  ConsumerState<StaffGuardWrapper> createState() => _StaffGuardWrapperState();
}

class _StaffGuardWrapperState extends ConsumerState<StaffGuardWrapper> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to auth changes to catch Magic Link login completion
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        unawaited(_handleAuthChange(data));
      },
    );
  }

  Future<void> _handleAuthChange(AuthState data) async {
    final session = data.session;
    if (session != null &&
        (session.user.email?.endsWith('@minglit.com') ?? false)) {
      await ref.read(staffGuardProvider.notifier).setVerified(session);
    }
  }

  @override
  void dispose() {
    // ignore: discarded_futures - Dispose must be synchronous, so we cannot await the cancel future.
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Staff guard only applies to web deployments.
    // Mobile apps are not publicly distributed, so no protection needed.
    if (!kIsWeb || isLocalhost) {
      return widget.child;
    }

    final staffStatus = ref.watch(staffGuardProvider);

    // ignore: use_minglit_async_value_widget - Specific splash logic required
    return staffStatus.when(
      data: (user) {
        if (user != null) {
          // Staff verified! Show the actual app.
          return widget.child;
        }
        // Not verified. Show the gate.
        return const StaffGateScreen();
      },
      loading: () => const MinglitSplashScreen(
        appName: 'Security',
      ),
      error: (e, st) => Scaffold(
        backgroundColor: MinglitColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(MinglitSpacing.large),
            child: Text(
              'Security Initialization Error: $e',
              style: MinglitTextStyles.infoText(context).copyWith(
                color: MinglitColors.error,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
