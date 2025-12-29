import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'party_create_controller.g.dart';

@riverpod
Future<List<Map<String, dynamic>>> partyVerificationTypes(Ref ref) async {
  final repo = ref.watch(verificationRepositoryProvider);
  return repo.getVerifications();
}

@riverpod
Future<List<Location>> partnerLocations(Ref ref, String partnerId) async {
  if (partnerId.isEmpty) return [];
  final repo = ref.watch(partnerRepositoryProvider);
  return repo.getLocations(partnerId);
}

@riverpod
Future<Partner?> currentPartnerInfo(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  // Assume user.id is the partner.id for simplicity in this partner app context
  // or fetch via relation if different.
  final repo = ref.watch(partnerRepositoryProvider);
  return repo.getPartnerById(user.id);
}

@riverpod
class PartyCreateController extends _$PartyCreateController {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> createParty({
    required String title,
    required Map<String, dynamic> description,
    required int minConfirmedCount,
    required int maxParticipants,
    required String contactPhone,
    required String contactEmail,
    required List<String> requiredVerificationIds,
    String? contactKakao,
    XFile? imageFile,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      // 1. Auto-detect Partner ID
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw const AuthException('User not authenticated');
      }
      final partnerId = user.id; // Assumes User ID = Partner ID for now

      final repository = ref.read(partyRepositoryProvider);
      String? imageUrl;

      // 2. Upload Image
      if (imageFile != null) {
        imageUrl = await repository.uploadPartyImage(imageFile, partnerId);
      }

      // 3. Prepare Contact Options (Organic JSON)
      final contactOptions = <String, dynamic>{};
      if (contactPhone.isNotEmpty) contactOptions['phone'] = contactPhone;
      if (contactEmail.isNotEmpty) contactOptions['email'] = contactEmail;
      if (contactKakao != null && contactKakao.isNotEmpty) {
        contactOptions['kakao_open_chat'] = contactKakao;
      }
      // Add more dynamic contacts here in the future (e.g., instagram)

      // 4. Create Party
      final newParty = Party(
        id: '', // Server generated
        partnerId: partnerId,
        title: title,
        description: description, // Store rich text JSON directly
        minConfirmedCount: minConfirmedCount,
        maxParticipants: maxParticipants,
        contactOptions: contactOptions,
        imageUrl: imageUrl,
        requiredVerificationIds: requiredVerificationIds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createParty(newParty);
    });
  }
}
