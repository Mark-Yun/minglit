import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'party_create_controller.freezed.dart';
part 'party_create_controller.g.dart';

@freezed
abstract class PartyCreateState with _$PartyCreateState {
  const factory PartyCreateState({
    @Default([]) List<String> selectedVerificationIds,
    @Default({}) Set<String> enabledContactMethods,
    @Default(AsyncValue.data(null)) AsyncValue<void> status,
    Location? selectedLocation,
    String? descriptionError,
  }) = _PartyCreateState;
}

@riverpod
Future<List<Verification>> partyVerificationTypes(Ref ref) async {
  final repo = ref.watch(verificationRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return [];

  // 1. Fetch Global Verifications
  final globalList = await repo.getGlobalVerifications();

  // 2. Fetch Partner Specific Verifications
  final partnerRepo = ref.watch(partnerRepositoryProvider);
  final myPartners = await partnerRepo.getMyManagedPartners();

  final partnerVerifList = <Verification>[];
  for (final partner in myPartners) {
    final list = await repo.getPartnerVerifications(partner.id);
    partnerVerifList.addAll(list);
  }

  // Combine and remove duplicates by ID
  final all = [...globalList, ...partnerVerifList];
  final seen = <String>{};
  return all.where((v) => seen.add(v.id)).toList();
}

@riverpod
Future<List<Location>> partnerLocations(Ref ref, String partnerId) async {
  if (partnerId.isEmpty) return [];
  final repo = ref.watch(locationRepositoryProvider);
  return repo.getLocations(partnerId);
}

@riverpod
Future<Partner?> currentPartnerInfo(Ref ref) async {
  final partnerRepo = ref.watch(partnerRepositoryProvider);
  final myPartners = await partnerRepo.getMyManagedPartners();
  return myPartners.firstOrNull;
}

@riverpod
class PartyCreateController extends _$PartyCreateController {
  @override
  PartyCreateState build() {
    return const PartyCreateState();
  }

  void updateLocation(Location? location) {
    state = state.copyWith(selectedLocation: location);
  }

  void toggleVerification(String id) {
    final current = List<String>.from(state.selectedVerificationIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(selectedVerificationIds: current);
  }

  void toggleContactMethod(String method) {
    final current = Set<String>.from(state.enabledContactMethods);
    if (current.contains(method)) {
      current.remove(method);
    } else {
      current.add(method);
    }
    state = state.copyWith(enabledContactMethods: current);
  }

  // --- Validators ---

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) return '파티 이름을 입력해주세요.';
    return null;
  }

  String? validateCapacity(String? value) {
    if (value == null || value.isEmpty) return '필수';
    if (int.tryParse(value) == null) return '숫자만 입력 가능합니다.';
    return null;
  }

  String? validateMaxCapacity(String? value, String? minStr) {
    final error = validateCapacity(value);
    if (error != null) return error;

    final min = int.tryParse(minStr ?? '') ?? 0;
    final max = int.tryParse(value ?? '') ?? 0;
    if (min > max) return '최소 인원보다 커야 합니다.';
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) return '연락처를 입력해주세요.';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return '이메일을 입력해주세요.';
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) return '유효한 이메일 형식이 아닙니다.';
    return null;
  }

  Future<void> createParty({
    required String title,
    required Map<String, dynamic> description,
    required int minConfirmedCount,
    required int maxParticipants,
    required String contactPhone,
    required String contactEmail,
    String? contactKakao,
    XFile? imageFile,
    String? addressDetail,
    String? directionsGuide,
  }) async {
    state = state.copyWith(status: const AsyncValue.loading());

    final result = await AsyncValue.guard(() async {
      // 1. Business Validation
      if (state.selectedLocation == null) {
        throw Exception('파티 장소를 선택해주세요.');
      }

      if (state.enabledContactMethods.isEmpty) {
        throw Exception('최소 한 개의 문의 연락처를 선택해야 합니다.');
      }

      final ops = description['ops'] as List?;
      if (ops == null ||
          ops.isEmpty ||
          (ops.length == 1 &&
              (ops[0] as Map<String, dynamic>)['insert'] == '\n')) {
        state = state.copyWith(descriptionError: '파티 설명을 입력해주세요.');
        throw Exception('파티 설명을 입력해주세요.');
      }
      state = state.copyWith(descriptionError: null);

      final partnerRepo = ref.read(partnerRepositoryProvider);
      final myPartners = await partnerRepo.getMyManagedPartners();
      if (myPartners.isEmpty) {
        throw Exception('사용 가능한 파트너 정보를 찾을 수 없습니다.');
      }
      final partnerId = myPartners.first.id;

      final repository = ref.read(partyRepositoryProvider);
      String? imageUrl;

      // 2. Upload Image
      if (imageFile != null) {
        imageUrl = await repository.uploadPartyImage(imageFile, partnerId);
      }

      // 3. Prepare Contact Options
      final contactOptions = <String, dynamic>{};
      if (state.enabledContactMethods.contains('phone') &&
          contactPhone.isNotEmpty) {
        contactOptions['phone'] = contactPhone;
      }
      if (state.enabledContactMethods.contains('email') &&
          contactEmail.isNotEmpty) {
        contactOptions['email'] = contactEmail;
      }
      if (state.enabledContactMethods.contains('kakao') &&
          contactKakao != null &&
          contactKakao.isNotEmpty) {
        contactOptions['kakao_open_chat'] = contactKakao;
      }

      // 4. Create Location (if selected)
      String? locationId;
      if (state.selectedLocation != null) {
        final loc = state.selectedLocation!;
        final locationRepo = ref.read(locationRepositoryProvider);
        final newLocation = await locationRepo.createLocation(
          loc.copyWith(
            partnerId: partnerId,
            addressDetail: addressDetail,
            directionsGuide: directionsGuide,
          ),
        );
        locationId = newLocation.id;
      }

      // 5. Create Party
      final newParty = Party(
        id: '', // Server generated
        partnerId: partnerId,
        locationId: locationId,
        title: title,
        description: description,
        minConfirmedCount: minConfirmedCount,
        maxParticipants: maxParticipants,
        contactOptions: contactOptions,
        imageUrl: imageUrl,
        requiredVerificationIds: state.selectedVerificationIds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.createParty(newParty);

      // Refresh party list to show the new item
      ref.invalidate(partyListProvider);
    });

    state = state.copyWith(status: result);
  }
}
