import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_verification_controller.freezed.dart';
part 'create_verification_controller.g.dart';

@freezed
abstract class CreateVerificationState with _$CreateVerificationState {
  const factory CreateVerificationState({
    @Default('') String displayName,
    @Default('') String internalName,
    @Default('') String description,
    @Default([]) List<VerificationFormField> fields,
    @Default(false) bool isSubmitting,
    String? error,
  }) = _CreateVerificationState;
}

@riverpod
class CreateVerificationController extends _$CreateVerificationController {
  @override
  CreateVerificationState build() {
    return const CreateVerificationState();
  }

  void updateDisplayName(String value) {
    state = state.copyWith(displayName: value);
  }

  void updateInternalName(String value) {
    state = state.copyWith(internalName: value);
  }

  void updateDescription(String value) {
    state = state.copyWith(description: value);
  }

  void addField(String type) {
    final newField = VerificationFormField(
      key: 'field_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      label: '', // User will edit this
    );
    state = state.copyWith(fields: [...state.fields, newField]);
  }

  void removeField(int index) {
    final newFields = List<VerificationFormField>.from(state.fields)
      ..removeAt(index);
    state = state.copyWith(fields: newFields);
  }

  void updateField(int index, VerificationFormField field) {
    final newFields = List<VerificationFormField>.from(state.fields);
    newFields[index] = field;
    state = state.copyWith(fields: newFields);
  }

  Future<bool> submit(String? partnerId) async {
    if (state.fields.isEmpty) {
      state = state.copyWith(error: '적어도 하나의 입력 필드가 필요합니다.');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      final partnerRepo = ref.read(partnerRepositoryProvider);
      var effectivePartnerId = partnerId;

      if (effectivePartnerId == null) {
        final myPartners = await partnerRepo.getMyManagedPartners();
        effectivePartnerId = myPartners.firstOrNull?.id;
      }

      if (effectivePartnerId == null) {
        throw Exception('사용 가능한 파트너 정보를 찾을 수 없습니다.');
      }

      final newVerification = Verification(
        id: '', // Repo will handle
        partnerId: effectivePartnerId,
        category: VerificationCategory.etc,
        internalName: state.internalName.trim(),
        displayName: state.displayName.trim(),
        description: state.description.trim(),
        iconKey: 'star',
        formSchema: state.fields,
      );

      await ref
          .read(verificationRepositoryProvider)
          .createVerification(newVerification);

      return true;
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
