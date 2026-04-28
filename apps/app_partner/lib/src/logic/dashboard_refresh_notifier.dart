import 'package:app_partner/src/features/home/partner_dashboard_controller.dart'
    show PartnerDashboardController;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_refresh_notifier.g.dart';

/// Shared refresh signal for the partner dashboard.
/// Features that cause dashboard-relevant state changes (e.g. event creation)
/// call [DashboardRefreshNotifier.bump] instead of directly invalidating
/// [PartnerDashboardController], avoiding cross-feature coupling.
@Riverpod(keepAlive: true)
class DashboardRefresh extends _$DashboardRefresh {
  @override
  int build() => 0;

  // Fix #1943: bump triggers any provider watching this to rebuild
  void bump() => state++;
}
