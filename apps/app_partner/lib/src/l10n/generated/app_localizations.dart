import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('ko')];

  /// 공용 확인 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get common_button_confirm;

  /// 공용 취소 버튼 텍스트
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get common_button_cancel;

  /// No description provided for @common_button_save.
  ///
  /// In ko, this message translates to:
  /// **'저장하기'**
  String get common_button_save;

  /// No description provided for @common_error_system.
  ///
  /// In ko, this message translates to:
  /// **'일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'**
  String get common_error_system;

  /// No description provided for @partyDetail_section_entranceCondition.
  ///
  /// In ko, this message translates to:
  /// **'입장 조건 (기본)'**
  String get partyDetail_section_entranceCondition;

  /// No description provided for @partyDetail_section_verification.
  ///
  /// In ko, this message translates to:
  /// **'참가 자격 (인증)'**
  String get partyDetail_section_verification;

  /// No description provided for @partyDetail_section_location.
  ///
  /// In ko, this message translates to:
  /// **'장소 정보'**
  String get partyDetail_section_location;

  /// No description provided for @partyDetail_section_locationDetail.
  ///
  /// In ko, this message translates to:
  /// **'장소 상세'**
  String get partyDetail_section_locationDetail;

  /// No description provided for @partyDetail_section_events.
  ///
  /// In ko, this message translates to:
  /// **'개설된 회차 (이벤트)'**
  String get partyDetail_section_events;

  /// No description provided for @partyDetail_section_tickets.
  ///
  /// In ko, this message translates to:
  /// **'등록된 티켓 현황'**
  String get partyDetail_section_tickets;

  /// No description provided for @partyDetail_message_activated.
  ///
  /// In ko, this message translates to:
  /// **'파티가 활성화되었습니다.'**
  String get partyDetail_message_activated;

  /// No description provided for @partyDetail_message_deactivated.
  ///
  /// In ko, this message translates to:
  /// **'파티가 비활성화(보관)되었습니다.'**
  String get partyDetail_message_deactivated;

  /// No description provided for @partyDetail_menu_edit.
  ///
  /// In ko, this message translates to:
  /// **'파티 정보 수정'**
  String get partyDetail_menu_edit;

  /// No description provided for @partyDetail_menu_activate.
  ///
  /// In ko, this message translates to:
  /// **'파티 다시 활성화'**
  String get partyDetail_menu_activate;

  /// No description provided for @partyDetail_menu_deactivate.
  ///
  /// In ko, this message translates to:
  /// **'파티 비활성화 (보관)'**
  String get partyDetail_menu_deactivate;

  /// No description provided for @partyDetail_button_createEvent.
  ///
  /// In ko, this message translates to:
  /// **'새로운 회차 개설하기'**
  String get partyDetail_button_createEvent;

  /// No description provided for @partyDetail_subtitle_createEvent.
  ///
  /// In ko, this message translates to:
  /// **'새로운 날짜와 시간에 파티를 열어보세요.'**
  String get partyDetail_subtitle_createEvent;

  /// No description provided for @partyDetail_message_ticketAdded.
  ///
  /// In ko, this message translates to:
  /// **'티켓 템플릿이 추가되었습니다.'**
  String get partyDetail_message_ticketAdded;

  /// No description provided for @partyDetail_error_eventLoad.
  ///
  /// In ko, this message translates to:
  /// **'이벤트 로드 실패: {error}'**
  String partyDetail_error_eventLoad(String error);

  /// No description provided for @partyDetail_error_ticketLoad.
  ///
  /// In ko, this message translates to:
  /// **'티켓 로드 실패: {error}'**
  String partyDetail_error_ticketLoad(String error);

  /// No description provided for @partyDetail_error_partyLoad.
  ///
  /// In ko, this message translates to:
  /// **'파티 로드 실패: {error}'**
  String partyDetail_error_partyLoad(String error);

  /// No description provided for @partyList_badge_active.
  ///
  /// In ko, this message translates to:
  /// **'운영중'**
  String get partyList_badge_active;

  /// No description provided for @partyList_badge_closed.
  ///
  /// In ko, this message translates to:
  /// **'종료됨'**
  String get partyList_badge_closed;

  /// No description provided for @partyList_badge_draft.
  ///
  /// In ko, this message translates to:
  /// **'임시저장'**
  String get partyList_badge_draft;

  /// No description provided for @partyList_chip_maxParticipants.
  ///
  /// In ko, this message translates to:
  /// **'최대 {count}명'**
  String partyList_chip_maxParticipants(int count);

  /// No description provided for @partyList_chip_requiredVerifications.
  ///
  /// In ko, this message translates to:
  /// **'인증 {count}개 필요'**
  String partyList_chip_requiredVerifications(int count);

  /// No description provided for @partyList_chip_noVerification.
  ///
  /// In ko, this message translates to:
  /// **'인증 불필요'**
  String get partyList_chip_noVerification;

  /// No description provided for @partyList_message_noLocation.
  ///
  /// In ko, this message translates to:
  /// **'지정된 장소 없음'**
  String get partyList_message_noLocation;

  /// No description provided for @reviewVerification_title_pending.
  ///
  /// In ko, this message translates to:
  /// **'인증 심사 대기열'**
  String get reviewVerification_title_pending;

  /// No description provided for @reviewVerification_message_empty.
  ///
  /// In ko, this message translates to:
  /// **'모든 심사가 완료되었습니다! 🎉'**
  String get reviewVerification_message_empty;

  /// No description provided for @reviewVerification_button_correction.
  ///
  /// In ko, this message translates to:
  /// **'보완 요청'**
  String get reviewVerification_button_correction;

  /// No description provided for @reviewVerification_button_approve.
  ///
  /// In ko, this message translates to:
  /// **'최종 승인'**
  String get reviewVerification_button_approve;

  /// No description provided for @reviewVerification_button_chat.
  ///
  /// In ko, this message translates to:
  /// **'대화 내역 확인'**
  String get reviewVerification_button_chat;

  /// No description provided for @reviewVerification_dialog_correction_title.
  ///
  /// In ko, this message translates to:
  /// **'보완 요청'**
  String get reviewVerification_dialog_correction_title;

  /// No description provided for @reviewVerification_dialog_correction_reasonLabel.
  ///
  /// In ko, this message translates to:
  /// **'반려 사유 (요약)'**
  String get reviewVerification_dialog_correction_reasonLabel;

  /// No description provided for @reviewVerification_dialog_correction_reasonHint.
  ///
  /// In ko, this message translates to:
  /// **'예: 서류 식별 불가'**
  String get reviewVerification_dialog_correction_reasonHint;

  /// No description provided for @reviewVerification_dialog_correction_commentLabel.
  ///
  /// In ko, this message translates to:
  /// **'상세 안내 (코멘트)'**
  String get reviewVerification_dialog_correction_commentLabel;

  /// No description provided for @reviewVerification_dialog_correction_commentHint.
  ///
  /// In ko, this message translates to:
  /// **'유저에게 전달할 자세한 내용을 적어주세요.'**
  String get reviewVerification_dialog_correction_commentHint;

  /// No description provided for @reviewVerification_dialog_correction_send.
  ///
  /// In ko, this message translates to:
  /// **'보완 요청 전송'**
  String get reviewVerification_dialog_correction_send;

  /// No description provided for @reviewVerification_chat_title.
  ///
  /// In ko, this message translates to:
  /// **'유저와 대화'**
  String get reviewVerification_chat_title;

  /// No description provided for @reviewVerification_message_processComplete.
  ///
  /// In ko, this message translates to:
  /// **'처리가 완료되었습니다.'**
  String get reviewVerification_message_processComplete;

  /// No description provided for @partnerApplication_title.
  ///
  /// In ko, this message translates to:
  /// **'파트너 입점 신청'**
  String get partnerApplication_title;

  /// No description provided for @partnerApplication_status_dialogTitle.
  ///
  /// In ko, this message translates to:
  /// **'신청 현황'**
  String get partnerApplication_status_dialogTitle;

  /// No description provided for @partnerApplication_status_dialogContent.
  ///
  /// In ko, this message translates to:
  /// **'현재 가입 신청이 [{status}] 상태입니다. 심사가 완료될 때까지 기다려 주세요.'**
  String partnerApplication_status_dialogContent(String status);

  /// No description provided for @partnerApplication_message_missingFiles.
  ///
  /// In ko, this message translates to:
  /// **'필수 서류를 모두 업로드해 주세요.'**
  String get partnerApplication_message_missingFiles;

  /// No description provided for @partnerApplication_dialog_successTitle.
  ///
  /// In ko, this message translates to:
  /// **'신청 완료'**
  String get partnerApplication_dialog_successTitle;

  /// No description provided for @partnerApplication_dialog_successContent.
  ///
  /// In ko, this message translates to:
  /// **'입점 신청이 제출되었습니다. 심사 결과는 이메일로 안내해 드립니다.'**
  String get partnerApplication_dialog_successContent;

  /// No description provided for @partnerApplication_button_submit.
  ///
  /// In ko, this message translates to:
  /// **'입점 신청하기'**
  String get partnerApplication_button_submit;

  /// No description provided for @partnerApplication_section_brand.
  ///
  /// In ko, this message translates to:
  /// **'1. 브랜드 정보'**
  String get partnerApplication_section_brand;

  /// No description provided for @partnerApplication_field_brandName.
  ///
  /// In ko, this message translates to:
  /// **'브랜드/매장명'**
  String get partnerApplication_field_brandName;

  /// No description provided for @partnerApplication_hint_brandName.
  ///
  /// In ko, this message translates to:
  /// **'예: 밍글릿 강남점'**
  String get partnerApplication_hint_brandName;

  /// No description provided for @partnerApplication_field_intro.
  ///
  /// In ko, this message translates to:
  /// **'소개글'**
  String get partnerApplication_field_intro;

  /// No description provided for @partnerApplication_hint_intro.
  ///
  /// In ko, this message translates to:
  /// **'사장님과 매장을 소개해 주세요.'**
  String get partnerApplication_hint_intro;

  /// No description provided for @partnerApplication_field_address.
  ///
  /// In ko, this message translates to:
  /// **'주소'**
  String get partnerApplication_field_address;

  /// No description provided for @partnerApplication_hint_address.
  ///
  /// In ko, this message translates to:
  /// **'파티가 열릴 매장 주소'**
  String get partnerApplication_hint_address;

  /// No description provided for @partnerApplication_field_phone.
  ///
  /// In ko, this message translates to:
  /// **'연락처'**
  String get partnerApplication_field_phone;

  /// No description provided for @partnerApplication_hint_phone.
  ///
  /// In ko, this message translates to:
  /// **'010-0000-0000'**
  String get partnerApplication_hint_phone;

  /// No description provided for @partnerApplication_field_email.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get partnerApplication_field_email;

  /// No description provided for @partnerApplication_hint_email.
  ///
  /// In ko, this message translates to:
  /// **'partner@example.com'**
  String get partnerApplication_hint_email;

  /// No description provided for @partnerApplication_section_biz.
  ///
  /// In ko, this message translates to:
  /// **'2. 사업자 정보'**
  String get partnerApplication_section_biz;

  /// No description provided for @partnerApplication_field_bizType.
  ///
  /// In ko, this message translates to:
  /// **'사업자 유형'**
  String get partnerApplication_field_bizType;

  /// No description provided for @partnerApplication_option_individual.
  ///
  /// In ko, this message translates to:
  /// **'개인 사업자'**
  String get partnerApplication_option_individual;

  /// No description provided for @partnerApplication_option_corporate.
  ///
  /// In ko, this message translates to:
  /// **'법인 사업자'**
  String get partnerApplication_option_corporate;

  /// No description provided for @partnerApplication_field_bizName.
  ///
  /// In ko, this message translates to:
  /// **'사업자명'**
  String get partnerApplication_field_bizName;

  /// No description provided for @partnerApplication_hint_bizName.
  ///
  /// In ko, this message translates to:
  /// **'사업자 등록증상 이름'**
  String get partnerApplication_hint_bizName;

  /// No description provided for @partnerApplication_field_bizNumber.
  ///
  /// In ko, this message translates to:
  /// **'사업자 번호'**
  String get partnerApplication_field_bizNumber;

  /// No description provided for @partnerApplication_hint_bizNumber.
  ///
  /// In ko, this message translates to:
  /// **'000-00-00000'**
  String get partnerApplication_hint_bizNumber;

  /// No description provided for @partnerApplication_field_repName.
  ///
  /// In ko, this message translates to:
  /// **'대표자명'**
  String get partnerApplication_field_repName;

  /// No description provided for @partnerApplication_hint_repName.
  ///
  /// In ko, this message translates to:
  /// **'성함'**
  String get partnerApplication_hint_repName;

  /// No description provided for @partnerApplication_section_account.
  ///
  /// In ko, this message translates to:
  /// **'3. 정산 계좌 정보'**
  String get partnerApplication_section_account;

  /// No description provided for @partnerApplication_field_bankName.
  ///
  /// In ko, this message translates to:
  /// **'은행명'**
  String get partnerApplication_field_bankName;

  /// No description provided for @partnerApplication_hint_bankName.
  ///
  /// In ko, this message translates to:
  /// **'예: 신한은행'**
  String get partnerApplication_hint_bankName;

  /// No description provided for @partnerApplication_field_accountNum.
  ///
  /// In ko, this message translates to:
  /// **'계좌번호'**
  String get partnerApplication_field_accountNum;

  /// No description provided for @partnerApplication_hint_accountNum.
  ///
  /// In ko, this message translates to:
  /// **'숫자만 입력'**
  String get partnerApplication_hint_accountNum;

  /// No description provided for @partnerApplication_field_holder.
  ///
  /// In ko, this message translates to:
  /// **'예금주'**
  String get partnerApplication_field_holder;

  /// No description provided for @partnerApplication_section_files.
  ///
  /// In ko, this message translates to:
  /// **'4. 서류 첨부'**
  String get partnerApplication_section_files;

  /// No description provided for @partnerApplication_label_bizReg.
  ///
  /// In ko, this message translates to:
  /// **'사업자등록증'**
  String get partnerApplication_label_bizReg;

  /// No description provided for @partnerApplication_label_bankbook.
  ///
  /// In ko, this message translates to:
  /// **'통장 사본'**
  String get partnerApplication_label_bankbook;

  /// No description provided for @partnerApplication_hint_fileSelect.
  ///
  /// In ko, this message translates to:
  /// **'파일을 선택해 주세요.'**
  String get partnerApplication_hint_fileSelect;

  /// No description provided for @partnerApplication_error_required.
  ///
  /// In ko, this message translates to:
  /// **'필수 입력 항목입니다.'**
  String get partnerApplication_error_required;

  /// No description provided for @memberPermission_title.
  ///
  /// In ko, this message translates to:
  /// **'권한 상세 설정'**
  String get memberPermission_title;

  /// No description provided for @memberPermission_message_notFound.
  ///
  /// In ko, this message translates to:
  /// **'멤버를 찾을 수 없습니다.'**
  String get memberPermission_message_notFound;

  /// No description provided for @memberPermission_defaultName.
  ///
  /// In ko, this message translates to:
  /// **'멤버 정보'**
  String get memberPermission_defaultName;

  /// No description provided for @memberPermission_section_role.
  ///
  /// In ko, this message translates to:
  /// **'역할(Role) 선택'**
  String get memberPermission_section_role;

  /// No description provided for @memberPermission_role_owner.
  ///
  /// In ko, this message translates to:
  /// **'Owner (모든 권한)'**
  String get memberPermission_role_owner;

  /// No description provided for @memberPermission_role_manager.
  ///
  /// In ko, this message translates to:
  /// **'Manager (운영 및 심사)'**
  String get memberPermission_role_manager;

  /// No description provided for @memberPermission_role_staff.
  ///
  /// In ko, this message translates to:
  /// **'Staff (단순 업무)'**
  String get memberPermission_role_staff;

  /// No description provided for @memberPermission_section_permission.
  ///
  /// In ko, this message translates to:
  /// **'상세 기능 권한(Permissions)'**
  String get memberPermission_section_permission;

  /// No description provided for @memberPermission_message_roleWarning.
  ///
  /// In ko, this message translates to:
  /// **'역할을 변경하면 권한 배열이 기본값으로 초기화됩니다.'**
  String get memberPermission_message_roleWarning;

  /// No description provided for @memberPermission_button_save.
  ///
  /// In ko, this message translates to:
  /// **'변경 사항 저장'**
  String get memberPermission_button_save;

  /// No description provided for @memberPermission_message_saved.
  ///
  /// In ko, this message translates to:
  /// **'저장되었습니다.'**
  String get memberPermission_message_saved;

  /// No description provided for @memberPermission_error_saveFailed.
  ///
  /// In ko, this message translates to:
  /// **'권한 설정 저장 중 오류가 발생했습니다.'**
  String get memberPermission_error_saveFailed;

  /// No description provided for @permission_PARTNER_EDIT.
  ///
  /// In ko, this message translates to:
  /// **'파트너 정보 수정'**
  String get permission_PARTNER_EDIT;

  /// No description provided for @permission_SETTLEMENT_VIEW.
  ///
  /// In ko, this message translates to:
  /// **'정산 정보 조회'**
  String get permission_SETTLEMENT_VIEW;

  /// No description provided for @permission_SETTLEMENT_EDIT.
  ///
  /// In ko, this message translates to:
  /// **'정산 계좌 수정'**
  String get permission_SETTLEMENT_EDIT;

  /// No description provided for @permission_MEMBER_MANAGE.
  ///
  /// In ko, this message translates to:
  /// **'멤버 초대 및 권한 관리'**
  String get permission_MEMBER_MANAGE;

  /// No description provided for @permission_PARTY_MANAGE.
  ///
  /// In ko, this message translates to:
  /// **'파티 생성 및 관리'**
  String get permission_PARTY_MANAGE;

  /// No description provided for @permission_VERIFY_LIST_VIEW.
  ///
  /// In ko, this message translates to:
  /// **'유저 심사 목록 조회'**
  String get permission_VERIFY_LIST_VIEW;

  /// No description provided for @permission_USER_DATA_VIEW.
  ///
  /// In ko, this message translates to:
  /// **'유저 증빙 서류 열람'**
  String get permission_USER_DATA_VIEW;

  /// No description provided for @permission_VERIFY_REVIEW.
  ///
  /// In ko, this message translates to:
  /// **'유저 심사 승인/반려'**
  String get permission_VERIFY_REVIEW;

  /// No description provided for @permission_COMMENT_MANAGE.
  ///
  /// In ko, this message translates to:
  /// **'유저 코멘트 대화'**
  String get permission_COMMENT_MANAGE;

  /// No description provided for @appDetail_title.
  ///
  /// In ko, this message translates to:
  /// **'상세 정보'**
  String get appDetail_title;

  /// No description provided for @appDetail_message_notFound.
  ///
  /// In ko, this message translates to:
  /// **'신청 정보를 찾을 수 없습니다.'**
  String get appDetail_message_notFound;

  /// No description provided for @appDetail_section_basic.
  ///
  /// In ko, this message translates to:
  /// **'기본 정보'**
  String get appDetail_section_basic;

  /// No description provided for @appDetail_section_files.
  ///
  /// In ko, this message translates to:
  /// **'첨부 서류'**
  String get appDetail_section_files;

  /// No description provided for @appDetail_label_bizReg.
  ///
  /// In ko, this message translates to:
  /// **'사업자등록증'**
  String get appDetail_label_bizReg;

  /// No description provided for @appDetail_label_bankbook.
  ///
  /// In ko, this message translates to:
  /// **'통장사본'**
  String get appDetail_label_bankbook;

  /// No description provided for @appDetail_section_review.
  ///
  /// In ko, this message translates to:
  /// **'심사 처리'**
  String get appDetail_section_review;

  /// No description provided for @appDetail_label_adminComment.
  ///
  /// In ko, this message translates to:
  /// **'관리자 코멘트 (선택)'**
  String get appDetail_label_adminComment;

  /// No description provided for @appDetail_button_approve.
  ///
  /// In ko, this message translates to:
  /// **'승인'**
  String get appDetail_button_approve;

  /// No description provided for @appDetail_button_correction.
  ///
  /// In ko, this message translates to:
  /// **'보완 요청'**
  String get appDetail_button_correction;

  /// No description provided for @appDetail_button_reject.
  ///
  /// In ko, this message translates to:
  /// **'반려'**
  String get appDetail_button_reject;

  /// No description provided for @appDetail_section_result.
  ///
  /// In ko, this message translates to:
  /// **'심사 결과'**
  String get appDetail_section_result;

  /// No description provided for @appDetail_label_status.
  ///
  /// In ko, this message translates to:
  /// **'상태'**
  String get appDetail_label_status;

  /// No description provided for @appDetail_label_comment.
  ///
  /// In ko, this message translates to:
  /// **'코멘트'**
  String get appDetail_label_comment;

  /// No description provided for @appDetail_label_download.
  ///
  /// In ko, this message translates to:
  /// **'다운로드/보기'**
  String get appDetail_label_download;

  /// No description provided for @appDetail_message_downloadNotImpl.
  ///
  /// In ko, this message translates to:
  /// **'파일 다운로드 기능 구현 필요'**
  String get appDetail_message_downloadNotImpl;

  /// No description provided for @appDetail_message_processed.
  ///
  /// In ko, this message translates to:
  /// **'처리되었습니다 ({status})'**
  String appDetail_message_processed(String status);

  /// No description provided for @appDetail_error_processFailed.
  ///
  /// In ko, this message translates to:
  /// **'신청서 상태 변경에 실패했습니다.'**
  String get appDetail_error_processFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
