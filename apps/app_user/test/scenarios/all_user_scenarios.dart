import 'screenshot_scenario.dart';
import 'account_deletion_scenarios.dart';
import 'blocked_partners_scenarios.dart';
import 'event_application_scenarios.dart';
import 'event_detail_scenarios.dart';
import 'home_scenarios.dart';
import 'login_scenarios.dart';
import 'matching_vote_scenarios.dart';
import 'my_page_scenarios.dart';
import 'party_partner_scenarios.dart';
import 'payment_scenarios.dart';
import 'search_scenarios.dart';
import 'ticket_qr_scenarios.dart';

class UserScenarios {
  static List<ScreenshotScenario> get all => [
    ...HomeScenarios.all,
    ...MyPageScenarios.all,
    ...SearchScenarios.all,
    ...LoginScenarios.all,
    ...EventDetailScenarios.all,
    ...EventApplicationScenarios.all,
    ...MatchingVoteScenarios.all,
    ...PartyPartnerScenarios.all,
    ...PaymentScenarios.all,
    ...TicketQRScenarios.all,
    ...AccountDeletionScenarios.all,
    ...BlockedPartnersScenarios.all,
  ];
}
