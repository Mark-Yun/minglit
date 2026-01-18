import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:minglit_kit/src/features/auth/logic/staff_guard_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

class StaffGuardWrapper extends ConsumerStatefulWidget {
  const StaffGuardWrapper({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<StaffGuardWrapper> createState() => _StaffGuardWrapperState();
}

class _StaffGuardWrapperState extends ConsumerState<StaffGuardWrapper> {
  StreamSubscription<AuthState>? _authSubscription;

  bool get _isLocalhost {
    if (!kIsWeb) return false;
    final hostname = web.window.location.hostname;
    return hostname == 'localhost' || hostname == '127.0.0.1';
  }

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
    // Automatically bypass for local development
    if (_isLocalhost) {
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
