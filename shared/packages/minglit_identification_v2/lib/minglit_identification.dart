/// Minglit Identification Package
///
/// Provides platform-agnostic identity verification via Portone.
library minglit_identification;

export 'src/interface/identification_provider.dart';
export 'src/implementation/identification_stub.dart'
    if (dart.library.io) 'src/implementation/identification_io.dart'
    if (dart.library.js_interop) 'src/implementation/identification_web.dart';
