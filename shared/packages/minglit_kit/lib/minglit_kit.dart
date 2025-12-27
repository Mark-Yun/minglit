library;

// UI Widgets
export 'src/widgets/auth/login_screen.dart';
export 'src/widgets/partner_detail_view.dart'; 
export 'src/utils/splash_screen.dart'; 
export 'src/utils/dev_screen_list.dart'; 

// Data Models
export 'src/data/models/partner.dart';
export 'src/data/models/partner_application.dart';
export 'src/data/models/verification.dart';

// Repositories
export 'src/data/repositories/auth_repository.dart';
export 'src/data/repositories/partner_repository.dart';
export 'src/data/repositories/verification_repository.dart';

// Logic (BLoCs)
export 'src/logic/blocs/auth/auth_bloc.dart';
export 'src/logic/blocs/auth/auth_event.dart';
export 'src/logic/blocs/auth/auth_state.dart';
export 'src/logic/blocs/partner/partner_bloc.dart';
export 'src/logic/blocs/partner/partner_event.dart';
export 'src/logic/blocs/partner/partner_state.dart';
export 'src/logic/blocs/verification/verification_bloc.dart';
export 'src/logic/blocs/verification/verification_event.dart';
export 'src/logic/blocs/verification/verification_state.dart';

// Utilities & Infrastructure
export 'src/locator.dart'; 
export 'src/utils/log.dart'; 

// External packages (Convenience)
export 'package:get_it/get_it.dart'; 
export 'package:supabase_flutter/supabase_flutter.dart' show AuthException, User; 
export 'package:flutter_bloc/flutter_bloc.dart';