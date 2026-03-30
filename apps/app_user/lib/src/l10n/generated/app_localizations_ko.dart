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

  @override
  String get reportReasonSexualContent => '선정적인 콘텐츠';

  @override
  String get reportReasonFalseInformation => '허위 또는 과장된 정보';

  @override
  String get reportReasonNoShow => '노쇼 / 이벤트 미진행';

  @override
  String get reportReasonFraud => '사기 또는 부당 청구';

  @override
  String get reportReasonOther => '기타';

  @override
  String get blockPartnerTitle => '차단하기';

  @override
  String get blockPartnerConfirm =>
      '이 파트너를 차단하시겠습니까?\n이 파트너의 이벤트가 더 이상 표시되지 않습니다.';

  @override
  String get blockPartnerSuccess => '파트너가 차단되었습니다';

  @override
  String get reportPartnerTitle => '신고하기';

  @override
  String get reportPartnerDescription => '신고 이유를 선택해주세요';

  @override
  String get reportSuccess => '신고가 접수되었습니다';

  @override
  String get blockedPartnersTitle => '차단 목록';

  @override
  String get unblockPartner => '차단 해제';

  @override
  String get unblockPartnerConfirm => '이 파트너의 차단을 해제하시겠습니까?';

  @override
  String get blockedPartnersEmpty => '차단된 파트너가 없습니다';

  @override
  String get reportReasonOtherHint => '상세 사유를 입력해주세요';
}
