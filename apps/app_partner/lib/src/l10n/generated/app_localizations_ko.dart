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
  String get common_button_save => '저장하기';

  @override
  String get common_error_system => '일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';

  @override
  String get partyDetail_section_entranceCondition => '입장 조건 (기본)';

  @override
  String get partyDetail_section_verification => '참가 자격 (인증)';

  @override
  String get partyDetail_section_location => '장소 정보';

  @override
  String get partyDetail_section_locationDetail => '장소 상세';

  @override
  String get partyDetail_section_events => '개설된 회차 (이벤트)';

  @override
  String get partyDetail_section_tickets => '등록된 티켓 현황';

  @override
  String get partyDetail_message_activated => '파티가 활성화되었습니다.';

  @override
  String get partyDetail_message_deactivated => '파티가 비활성화(보관)되었습니다.';

  @override
  String get partyDetail_menu_edit => '파티 정보 수정';

  @override
  String get partyDetail_menu_activate => '파티 다시 활성화';

  @override
  String get partyDetail_menu_deactivate => '파티 비활성화 (보관)';

  @override
  String get partyDetail_button_createEvent => '새로운 회차 개설하기';

  @override
  String get partyDetail_subtitle_createEvent => '새로운 날짜와 시간에 파티를 열어보세요.';

  @override
  String get partyDetail_message_ticketAdded => '티켓 템플릿이 추가되었습니다.';

  @override
  String partyDetail_error_eventLoad(String error) {
    return '이벤트 로드 실패: $error';
  }

  @override
  String partyDetail_error_ticketLoad(String error) {
    return '티켓 로드 실패: $error';
  }

  @override
  String partyDetail_error_partyLoad(String error) {
    return '파티 로드 실패: $error';
  }

  @override
  String get reviewVerification_title_pending => '인증 심사 대기열';

  @override
  String get reviewVerification_message_empty => '모든 심사가 완료되었습니다! 🎉';

  @override
  String get reviewVerification_button_correction => '보완 요청';

  @override
  String get reviewVerification_button_approve => '최종 승인';

  @override
  String get reviewVerification_button_chat => '대화 내역 확인';

  @override
  String get reviewVerification_dialog_correction_title => '보완 요청';

  @override
  String get reviewVerification_dialog_correction_reasonLabel => '반려 사유 (요약)';

  @override
  String get reviewVerification_dialog_correction_reasonHint => '예: 서류 식별 불가';

  @override
  String get reviewVerification_dialog_correction_commentLabel => '상세 안내 (코멘트)';

  @override
  String get reviewVerification_dialog_correction_commentHint =>
      '유저에게 전달할 자세한 내용을 적어주세요.';

  @override
  String get reviewVerification_dialog_correction_send => '보완 요청 전송';

  @override
  String get reviewVerification_chat_title => '유저와 대화';

  @override
  String get reviewVerification_message_processComplete => '처리가 완료되었습니다.';

  @override
  String get partnerApplication_title => '파트너 입점 신청';

  @override
  String get partnerApplication_status_dialogTitle => '신청 현황';

  @override
  String partnerApplication_status_dialogContent(String status) {
    return '현재 가입 신청이 [$status] 상태입니다. 심사가 완료될 때까지 기다려 주세요.';
  }

  @override
  String get partnerApplication_message_missingFiles => '필수 서류를 모두 업로드해 주세요.';

  @override
  String get partnerApplication_dialog_successTitle => '신청 완료';

  @override
  String get partnerApplication_dialog_successContent =>
      '입점 신청이 제출되었습니다. 심사 결과는 이메일로 안내해 드립니다.';

  @override
  String get partnerApplication_button_submit => '입점 신청하기';

  @override
  String get partnerApplication_section_brand => '1. 브랜드 정보';

  @override
  String get partnerApplication_field_brandName => '브랜드/매장명';

  @override
  String get partnerApplication_hint_brandName => '예: 밍글릿 강남점';

  @override
  String get partnerApplication_field_intro => '소개글';

  @override
  String get partnerApplication_hint_intro => '사장님과 매장을 소개해 주세요.';

  @override
  String get partnerApplication_field_address => '주소';

  @override
  String get partnerApplication_hint_address => '파티가 열릴 매장 주소';

  @override
  String get partnerApplication_field_phone => '연락처';

  @override
  String get partnerApplication_hint_phone => '010-0000-0000';

  @override
  String get partnerApplication_field_email => '이메일';

  @override
  String get partnerApplication_hint_email => 'partner@example.com';

  @override
  String get partnerApplication_section_biz => '2. 사업자 정보';

  @override
  String get partnerApplication_field_bizType => '사업자 유형';

  @override
  String get partnerApplication_option_individual => '개인 사업자';

  @override
  String get partnerApplication_option_corporate => '법인 사업자';

  @override
  String get partnerApplication_field_bizName => '사업자명';

  @override
  String get partnerApplication_hint_bizName => '사업자 등록증상 이름';

  @override
  String get partnerApplication_field_bizNumber => '사업자 번호';

  @override
  String get partnerApplication_hint_bizNumber => '000-00-00000';

  @override
  String get partnerApplication_field_repName => '대표자명';

  @override
  String get partnerApplication_hint_repName => '성함';

  @override
  String get partnerApplication_section_account => '3. 정산 계좌 정보';

  @override
  String get partnerApplication_field_bankName => '은행명';

  @override
  String get partnerApplication_hint_bankName => '예: 신한은행';

  @override
  String get partnerApplication_field_accountNum => '계좌번호';

  @override
  String get partnerApplication_hint_accountNum => '숫자만 입력';

  @override
  String get partnerApplication_field_holder => '예금주';

  @override
  String get partnerApplication_section_files => '4. 서류 첨부';

  @override
  String get partnerApplication_label_bizReg => '사업자등록증';

  @override
  String get partnerApplication_label_bankbook => '통장 사본';

  @override
  String get partnerApplication_hint_fileSelect => '파일을 선택해 주세요.';

  @override
  String get partnerApplication_error_required => '필수 입력 항목입니다.';

  @override
  String get memberPermission_title => '권한 상세 설정';

  @override
  String get memberPermission_message_notFound => '멤버를 찾을 수 없습니다.';

  @override
  String get memberPermission_defaultName => '멤버 정보';

  @override
  String get memberPermission_section_role => '역할(Role) 선택';

  @override
  String get memberPermission_role_owner => 'Owner (모든 권한)';

  @override
  String get memberPermission_role_manager => 'Manager (운영 및 심사)';

  @override
  String get memberPermission_role_staff => 'Staff (단순 업무)';

  @override
  String get memberPermission_section_permission => '상세 기능 권한(Permissions)';

  @override
  String get memberPermission_message_roleWarning =>
      '역할을 변경하면 권한 배열이 기본값으로 초기화됩니다.';

  @override
  String get memberPermission_button_save => '변경 사항 저장';

  @override
  String get memberPermission_message_saved => '저장되었습니다.';

  @override
  String get memberPermission_error_saveFailed => '권한 설정 저장 중 오류가 발생했습니다.';

  @override
  String get permission_PARTNER_EDIT => '파트너 정보 수정';

  @override
  String get permission_SETTLEMENT_VIEW => '정산 정보 조회';

  @override
  String get permission_SETTLEMENT_EDIT => '정산 계좌 수정';

  @override
  String get permission_MEMBER_MANAGE => '멤버 초대 및 권한 관리';

  @override
  String get permission_PARTY_MANAGE => '파티 생성 및 관리';

  @override
  String get permission_VERIFY_LIST_VIEW => '유저 심사 목록 조회';

  @override
  String get permission_USER_DATA_VIEW => '유저 증빙 서류 열람';

  @override
  String get permission_VERIFY_REVIEW => '유저 심사 승인/반려';

  @override
  String get permission_COMMENT_MANAGE => '유저 코멘트 대화';

  @override
  String get appDetail_title => '상세 정보';

  @override
  String get appDetail_message_notFound => '신청 정보를 찾을 수 없습니다.';

  @override
  String get appDetail_section_basic => '기본 정보';

  @override
  String get appDetail_section_files => '첨부 서류';

  @override
  String get appDetail_label_bizReg => '사업자등록증';

  @override
  String get appDetail_label_bankbook => '통장사본';

  @override
  String get appDetail_section_review => '심사 처리';

  @override
  String get appDetail_label_adminComment => '관리자 코멘트 (선택)';

  @override
  String get appDetail_button_approve => '승인';

  @override
  String get appDetail_button_correction => '보완 요청';

  @override
  String get appDetail_button_reject => '반려';

  @override
  String get appDetail_section_result => '심사 결과';

  @override
  String get appDetail_label_status => '상태';

  @override
  String get appDetail_label_comment => '코멘트';

  @override
  String get appDetail_label_download => '다운로드/보기';

  @override
  String get appDetail_message_downloadNotImpl => '파일 다운로드 기능 구현 필요';

  @override
  String appDetail_message_processed(String status) {
    return '처리되었습니다 ($status)';
  }

  @override
  String get appDetail_error_processFailed => '신청서 상태 변경에 실패했습니다.';
}
