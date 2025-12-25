library;

export 'src/auth/login_screen.dart';
export 'src/auth/auth_service.dart';
export 'src/locator.dart'; // 서비스 로케이터
export 'package:get_it/get_it.dart'; // 앱에서 GetIt 직접 접근 가능하도록
export 'package:supabase_flutter/supabase_flutter.dart' show AuthException, AuthState; // 예외 처리 및 AuthState 편의성