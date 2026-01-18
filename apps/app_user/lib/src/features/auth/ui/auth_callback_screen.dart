import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  String _statusMessage = '로그인 처리 중입니다...';
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    unawaited(_handleAuthCallback());
  }

  Future<void> _handleAuthCallback() async {
    // 1. Wait briefly for Supabase to process the hash fragment
    // Supabase SDK handles the token parsing automatically upon app start/redirect.
    // We just need to wait for the auth state to become 'signed in'.

    // Safety timeout
    Timer(const Duration(seconds: 10), () {
      if (mounted && _isProcessing) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '로그인 시간이 초과되었습니다.\n다시 시도해주세요.';
        });
      }
    });

    // Check if already logged in (Supabase might have processed it instantly)
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      await _redirectUser();
      return;
    }
  }

  Future<void> _redirectUser() async {
    if (!mounted) return;

    setState(() {
      _statusMessage = '인증 성공! 이동 중...';
    });

    // Retrieve saved return URL
    final prefs = await SharedPreferences.getInstance();
    final returnUrl = prefs.getString('auth_return_url');
    await prefs.remove('auth_return_url');

    if (!mounted) return;

    Log.d('✅ [AuthCallback] Redirecting to: ${returnUrl ?? "/"}');
    context.go(returnUrl ?? '/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Listen for auth state changes
    ref.listen(currentUserProvider, (prev, next) {
      if (next != null) {
        unawaited(_redirectUser());
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing)
              const MinglitCircularProgressIndicator()
            else
              Icon(
                Icons.error_outline,
                size: MinglitIconSize.xlarge * 1.5,
                color: theme.colorScheme.error,
              ),
            const SizedBox(height: MinglitSpacing.large),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (!_isProcessing) ...[
              const SizedBox(height: MinglitSpacing.large),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('로그인 화면으로 돌아가기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
