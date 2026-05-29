// MDS render catalog registry — app_partner.
//
// 등록된 catalog 목록. 알파벳 순서 유지.
// 새 screen 추가 시 아래 import + catalog 변수 참조 추가.

import 'bank_account_page/bank_account_page_test.dart' as bank_account_page;
import 'checkin_placeholder_page/checkin_placeholder_page_test.dart'
    as checkin_placeholder_page;
import 'create_verification_page/create_verification_page_test.dart'
    as create_verification_page;
import 'location_guide_page/location_guide_page_test.dart'
    as location_guide_page;
import 'more_page/more_page_test.dart' as more_page;
import 'party_list_page/party_list_page_test.dart' as party_list_page;
import 'partner_home_page/partner_home_page_test.dart' as partner_home_page;
import 'partner_login_page/partner_login_page_test.dart' as partner_login_page;
import 'partner_member_list_page/partner_member_list_page_test.dart'
    as partner_member_list_page;
import 'partner_welcome_page/partner_welcome_page_test.dart'
    as partner_welcome_page;
import 'recurrence_management_screen/recurrence_management_screen_test.dart'
    as recurrence_management_screen;
import 'settlement_detail_page/settlement_detail_page_test.dart'
    as settlement_detail_page;
import 'settlement_page/settlement_page_test.dart' as settlement_page;
import 'verification_manage_page/verification_manage_page_test.dart'
    as verification_manage_page;

/// 모든 등록된 catalog.
final List<Object> catalogs = [
  bank_account_page.catalog,
  checkin_placeholder_page.catalog,
  create_verification_page.catalog,
  location_guide_page.catalog,
  more_page.catalog,
  party_list_page.catalog,
  partner_home_page.catalog,
  partner_login_page.catalog,
  partner_member_list_page.catalog,
  partner_welcome_page.catalog,
  recurrence_management_screen.catalog,
  settlement_detail_page.catalog,
  settlement_page.catalog,
  verification_manage_page.catalog,
];
