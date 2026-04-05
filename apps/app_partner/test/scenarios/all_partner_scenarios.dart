import 'closing_soon_scenarios.dart';
import 'create_verification_scenarios.dart';
import 'event_card_scenarios.dart';
import 'more_page_scenarios.dart';
import 'partner_apply_scenarios.dart';
import 'partner_apply_status_scenarios.dart';
import 'partner_event_detail_scenarios.dart';
import 'partner_home_scenarios.dart';
import 'partner_login_scenarios.dart';
import 'partner_screenshot_scenario.dart';
import 'party_create_wizard_scenarios.dart';
import 'party_list_scenarios.dart';
import 'settlement_empty_state_scenarios.dart';
import 'settlement_scenarios.dart';
import 'upcoming_events_scenarios.dart';
import 'verification_manage_scenarios.dart';

class PartnerScenarios {
  static List<PartnerScreenshotScenario> get all => [
    ...PartnerHomeScenarios.all,
    ...EventCardScenarios.all,
    ...ClosingSoonScenarios.all,
    ...UpcomingEventsScenarios.all,
    ...SettlementEmptyStateScenarios.all,
    ...PartnerLoginScenarios.all,
    ...PartnerApplyScenarios.all,
    ...PartnerApplyStatusScenarios.all,
    ...PartyCreateWizardScenarios.all,
    ...PartnerEventDetailScenarios.all,
    ...SettlementScenarios.all,
    ...VerificationManageScenarios.all,
    ...MorePageScenarios.all,
    ...CreateVerificationScenarios.all,
    ...PartyListScenarios.all,
  ];
}
