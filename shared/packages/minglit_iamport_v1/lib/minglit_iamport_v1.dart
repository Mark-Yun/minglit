library minglit_iamport_v1;

import 'src/service/payment_service.dart';
import 'src/service/certification_service.dart';

export 'src/service/payment_service.dart';
export 'src/service/certification_service.dart';

import 'src/implementation/certification_stub.dart'
    if (dart.library.io) 'src/implementation/certification_io.dart'
    if (dart.library.js_interop) 'src/implementation/certification_web.dart';

import 'src/implementation/payment_stub.dart'
    if (dart.library.io) 'src/implementation/payment_io.dart'
    if (dart.library.js_interop) 'src/implementation/payment_web.dart';

CertificationService getCertificationService() => CertificationServiceImpl();
PaymentService getPaymentService() => PaymentServiceImpl();
