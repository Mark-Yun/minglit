import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'iamport_repository.g.dart';

@Riverpod(keepAlive: true)
IamportRepository iamportRepository(Ref ref) {
  return IamportRepository();
}

class IamportRepository {
  Future<void> verifyCertification(String impUid) async {
    // TODO(payment_verification_system_20260117): Implement server-side verification via Edge Function.
    // await supabase.functions.invoke(
    //   'verify-certification',
    //   body: {'imp_uid': impUid},
    // );

    // For now, simulate network delay
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
