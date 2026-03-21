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

  /// No description provided for @common_button_confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get common_button_confirm;

  /// No description provided for @common_button_cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get common_button_cancel;

  /// No description provided for @common_error_system.
  ///
  /// In ko, this message translates to:
  /// **'일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'**
  String get common_error_system;

  /// No description provided for @reportReasonSexualContent.
  ///
  /// In ko, this message translates to:
  /// **'선정적인 콘텐츠'**
  String get reportReasonSexualContent;

  /// No description provided for @reportReasonFalseInformation.
  ///
  /// In ko, this message translates to:
  /// **'허위 또는 과장된 정보'**
  String get reportReasonFalseInformation;

  /// No description provided for @reportReasonNoShow.
  ///
  /// In ko, this message translates to:
  /// **'노쇼 / 이벤트 미진행'**
  String get reportReasonNoShow;

  /// No description provided for @reportReasonFraud.
  ///
  /// In ko, this message translates to:
  /// **'사기 또는 부당 청구'**
  String get reportReasonFraud;

  /// No description provided for @reportReasonOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get reportReasonOther;

  /// No description provided for @blockPartnerTitle.
  ///
  /// In ko, this message translates to:
  /// **'차단하기'**
  String get blockPartnerTitle;

  /// No description provided for @blockPartnerConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 파트너를 차단하시겠습니까?\n이 파트너의 이벤트가 더 이상 표시되지 않습니다.'**
  String get blockPartnerConfirm;

  /// No description provided for @blockPartnerSuccess.
  ///
  /// In ko, this message translates to:
  /// **'파트너가 차단되었습니다'**
  String get blockPartnerSuccess;

  /// No description provided for @reportPartnerTitle.
  ///
  /// In ko, this message translates to:
  /// **'신고하기'**
  String get reportPartnerTitle;

  /// No description provided for @reportPartnerDescription.
  ///
  /// In ko, this message translates to:
  /// **'신고 이유를 선택해주세요'**
  String get reportPartnerDescription;

  /// No description provided for @reportSuccess.
  ///
  /// In ko, this message translates to:
  /// **'신고가 접수되었습니다'**
  String get reportSuccess;

  /// No description provided for @blockedPartnersTitle.
  ///
  /// In ko, this message translates to:
  /// **'차단 목록'**
  String get blockedPartnersTitle;

  /// No description provided for @unblockPartner.
  ///
  /// In ko, this message translates to:
  /// **'차단 해제'**
  String get unblockPartner;

  /// No description provided for @unblockPartnerConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 파트너의 차단을 해제하시겠습니까?'**
  String get unblockPartnerConfirm;

  /// No description provided for @blockedPartnersEmpty.
  ///
  /// In ko, this message translates to:
  /// **'차단된 파트너가 없습니다'**
  String get blockedPartnersEmpty;

  /// No description provided for @reportReasonOtherHint.
  ///
  /// In ko, this message translates to:
  /// **'상세 사유를 입력해주세요'**
  String get reportReasonOtherHint;
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
