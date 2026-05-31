// MDS render catalog registry — app_partner.
//
// 등록된 catalog 목록. 알파벳 순서 유지.
// 새 screen 추가 시 아래 import + catalog 변수 참조 추가.

import 'bank_account_page/bank_account_page_test.dart' as bank_account_page;
import 'checkin_placeholder_page/checkin_placeholder_page_test.dart'
    as checkin_placeholder_page;
import 'create_verification_page/create_verification_page_test.dart'
    as create_verification_page;
import 'event_application_detail_page/event_application_detail_page_test.dart'
    as event_application_detail_page;
import 'event_application_list_page/event_application_list_page_test.dart'
    as event_application_list_page;
import 'event_application_manage_page/event_application_manage_page_test.dart'
    as event_application_manage_page;
import 'event_application_review_carousel_page/event_application_review_carousel_page_test.dart'
    as event_application_review_carousel_page;
import 'event_application_review_confirm_page/event_application_review_confirm_page_test.dart'
    as event_application_review_confirm_page;
import 'event_create_page/event_create_page_test.dart' as event_create_page;
import 'event_detail_page/event_detail_page_test.dart' as event_detail_page;
import 'event_edit_page/event_edit_page_test.dart' as event_edit_page;
import 'location_guide_page/location_guide_page_test.dart'
    as location_guide_page;
import 'more_page/more_page_test.dart' as more_page;
import 'party_list_page/party_list_page_test.dart' as party_list_page;
import 'party_create_wizard_page/party_create_wizard_page_test.dart'
    as party_create_wizard_page;
import 'party_detail_page/party_detail_page_test.dart' as party_detail_page;
import 'partner_apply_page/partner_apply_page_test.dart' as partner_apply_page;
import 'partner_application_detail_page/partner_application_detail_page_test.dart'
    as partner_application_detail_page;
import 'partner_apply_status_page/partner_apply_status_page_test.dart'
    as partner_apply_status_page;
import 'partner_event_detail_page/partner_event_detail_page_test.dart'
    as partner_event_detail_page;
import 'partner_guide/partner_guide_test.dart' as partner_guide;
import 'partner_home_page/partner_home_page_test.dart' as partner_home_page;
import 'partner_login_page/partner_login_page_test.dart' as partner_login_page;
import 'partner_member_list_page/partner_member_list_page_test.dart'
    as partner_member_list_page;
import 'partner_member_permission_page/partner_member_permission_page_test.dart'
    as partner_member_permission_page;
import 'partner_welcome_page/partner_welcome_page_test.dart'
    as partner_welcome_page;
import 'recurrence_management_screen/recurrence_management_screen_test.dart'
    as recurrence_management_screen;
import 'settlement_detail_page/settlement_detail_page_test.dart'
    as settlement_detail_page;
import 'settlement_page/settlement_page_test.dart' as settlement_page;
import 'ticket_create_page/ticket_create_page_test.dart' as ticket_create_page;
import 'ticket_edit_page/ticket_edit_page_test.dart' as ticket_edit_page;
import 'verification_manage_page/verification_manage_page_test.dart'
    as verification_manage_page;

/// 모든 등록된 catalog.
final List<Object> catalogs = [
  bank_account_page.catalog,
  checkin_placeholder_page.catalog,
  create_verification_page.catalog,
  event_application_detail_page.catalog,
  event_application_list_page.catalog,
  event_application_manage_page.catalog,
  event_application_review_carousel_page.catalog,
  event_application_review_confirm_page.catalog,
  event_create_page.catalog,
  event_detail_page.catalog,
  event_edit_page.catalog,
  location_guide_page.catalog,
  more_page.catalog,
  party_create_wizard_page.catalog,
  party_list_page.catalog,
  party_detail_page.catalog,
  partner_apply_page.catalog,
  partner_application_detail_page.catalog,
  partner_apply_status_page.catalog,
  partner_event_detail_page.catalog,
  partner_guide.catalog,
  partner_home_page.catalog,
  partner_login_page.catalog,
  partner_member_list_page.catalog,
  partner_member_permission_page.catalog,
  partner_welcome_page.catalog,
  recurrence_management_screen.catalog,
  settlement_detail_page.catalog,
  settlement_page.catalog,
  ticket_create_page.catalog,
  ticket_edit_page.catalog,
  verification_manage_page.catalog,
];
