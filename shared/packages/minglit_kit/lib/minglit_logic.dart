// External Dependencies for Logic
export 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers

export 'src/features/auth/logic/auth_controller.dart';
export 'src/features/consent/logic/consent_controller.dart';
export 'src/features/notification/logic/notification_settings_controller.dart';
export 'src/features/notification/notification_initializer.dart';
export 'src/features/notification/notification_list_controller.dart';
export 'src/features/notification/notification_service.dart';
export 'src/features/search/logic/location_search_controller.dart';
export 'src/features/theme/theme_controller.dart';
export 'src/features/theme/theme_settings_tile.dart';
export 'src/logic/providers/event_feed_provider.dart';
export 'src/logic/providers/statsig_provider.dart';
export 'src/logic/providers/supabase_provider.dart';
export 'src/logic/providers/user_profile_provider.dart';

// Note: Other repositories are exported via minglit_data.dart,

// or should be added here if they are logic-heavy.
