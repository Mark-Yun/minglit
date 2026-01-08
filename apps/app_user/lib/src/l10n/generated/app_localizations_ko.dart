// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get common_button_confirm => '확인';

  @override
  String get common_button_cancel => '취소';

  @override
  String get common_error_system => '일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
}
