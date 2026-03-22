// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'partner_apply_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PartnerApplyState {
  int get currentStep;
  String? get applicationId;
  bool get isSaving;
  bool get isSubmitting; // Step 1: Basic Info
  String get brandName;
  String get introduction;
  String? get profileImagePath;
  XFile? get profileImageFile; // Step 2: Business Info
  String get bizType;
  String get bizName;
  String get bizNumber;
  String get representativeName; // Step 3: Contact & Settlement
  String get contactPhone;
  String get contactEmail;
  String get address;
  String get bankName;
  String get accountNumber;
  String get accountHolder;
  String get taxEmail; // Step 4: Documents
  String? get bizRegistrationPath;
  XFile? get bizRegistrationFile;
  String? get bankbookPath;
  XFile? get bankbookFile; // Global status
  AsyncValue<void> get status;

  /// Create a copy of PartnerApplyState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PartnerApplyStateCopyWith<PartnerApplyState> get copyWith =>
      _$PartnerApplyStateCopyWithImpl<PartnerApplyState>(
          this as PartnerApplyState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PartnerApplyState &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.applicationId, applicationId) ||
                other.applicationId == applicationId) &&
            (identical(other.isSaving, isSaving) ||
                other.isSaving == isSaving) &&
            (identical(other.isSubmitting, isSubmitting) ||
                other.isSubmitting == isSubmitting) &&
            (identical(other.brandName, brandName) ||
                other.brandName == brandName) &&
            (identical(other.introduction, introduction) ||
                other.introduction == introduction) &&
            (identical(other.profileImagePath, profileImagePath) ||
                other.profileImagePath == profileImagePath) &&
            (identical(other.profileImageFile, profileImageFile) ||
                other.profileImageFile == profileImageFile) &&
            (identical(other.bizType, bizType) || other.bizType == bizType) &&
            (identical(other.bizName, bizName) || other.bizName == bizName) &&
            (identical(other.bizNumber, bizNumber) ||
                other.bizNumber == bizNumber) &&
            (identical(other.representativeName, representativeName) ||
                other.representativeName == representativeName) &&
            (identical(other.contactPhone, contactPhone) ||
                other.contactPhone == contactPhone) &&
            (identical(other.contactEmail, contactEmail) ||
                other.contactEmail == contactEmail) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.bankName, bankName) ||
                other.bankName == bankName) &&
            (identical(other.accountNumber, accountNumber) ||
                other.accountNumber == accountNumber) &&
            (identical(other.accountHolder, accountHolder) ||
                other.accountHolder == accountHolder) &&
            (identical(other.taxEmail, taxEmail) ||
                other.taxEmail == taxEmail) &&
            (identical(other.bizRegistrationPath, bizRegistrationPath) ||
                other.bizRegistrationPath == bizRegistrationPath) &&
            (identical(other.bizRegistrationFile, bizRegistrationFile) ||
                other.bizRegistrationFile == bizRegistrationFile) &&
            (identical(other.bankbookPath, bankbookPath) ||
                other.bankbookPath == bankbookPath) &&
            (identical(other.bankbookFile, bankbookFile) ||
                other.bankbookFile == bankbookFile) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        currentStep,
        applicationId,
        isSaving,
        isSubmitting,
        brandName,
        introduction,
        profileImagePath,
        profileImageFile,
        bizType,
        bizName,
        bizNumber,
        representativeName,
        contactPhone,
        contactEmail,
        address,
        bankName,
        accountNumber,
        accountHolder,
        taxEmail,
        bizRegistrationPath,
        bizRegistrationFile,
        bankbookPath,
        bankbookFile,
        status
      ]);

  @override
  String toString() {
    return 'PartnerApplyState(currentStep: $currentStep, applicationId: $applicationId, isSaving: $isSaving, isSubmitting: $isSubmitting, brandName: $brandName, introduction: $introduction, profileImagePath: $profileImagePath, profileImageFile: $profileImageFile, bizType: $bizType, bizName: $bizName, bizNumber: $bizNumber, representativeName: $representativeName, contactPhone: $contactPhone, contactEmail: $contactEmail, address: $address, bankName: $bankName, accountNumber: $accountNumber, accountHolder: $accountHolder, taxEmail: $taxEmail, bizRegistrationPath: $bizRegistrationPath, bizRegistrationFile: $bizRegistrationFile, bankbookPath: $bankbookPath, bankbookFile: $bankbookFile, status: $status)';
  }
}

/// @nodoc
abstract mixin class $PartnerApplyStateCopyWith<$Res> {
  factory $PartnerApplyStateCopyWith(
          PartnerApplyState value, $Res Function(PartnerApplyState) _then) =
      _$PartnerApplyStateCopyWithImpl;
  @useResult
  $Res call(
      {int currentStep,
      String? applicationId,
      bool isSaving,
      bool isSubmitting,
      String brandName,
      String introduction,
      String? profileImagePath,
      XFile? profileImageFile,
      String bizType,
      String bizName,
      String bizNumber,
      String representativeName,
      String contactPhone,
      String contactEmail,
      String address,
      String bankName,
      String accountNumber,
      String accountHolder,
      String taxEmail,
      String? bizRegistrationPath,
      XFile? bizRegistrationFile,
      String? bankbookPath,
      XFile? bankbookFile,
      AsyncValue<void> status});
}

/// @nodoc
class _$PartnerApplyStateCopyWithImpl<$Res>
    implements $PartnerApplyStateCopyWith<$Res> {
  _$PartnerApplyStateCopyWithImpl(this._self, this._then);

  final PartnerApplyState _self;
  final $Res Function(PartnerApplyState) _then;

  /// Create a copy of PartnerApplyState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentStep = null,
    Object? applicationId = freezed,
    Object? isSaving = null,
    Object? isSubmitting = null,
    Object? brandName = null,
    Object? introduction = null,
    Object? profileImagePath = freezed,
    Object? profileImageFile = freezed,
    Object? bizType = null,
    Object? bizName = null,
    Object? bizNumber = null,
    Object? representativeName = null,
    Object? contactPhone = null,
    Object? contactEmail = null,
    Object? address = null,
    Object? bankName = null,
    Object? accountNumber = null,
    Object? accountHolder = null,
    Object? taxEmail = null,
    Object? bizRegistrationPath = freezed,
    Object? bizRegistrationFile = freezed,
    Object? bankbookPath = freezed,
    Object? bankbookFile = freezed,
    Object? status = null,
  }) {
    return _then(_self.copyWith(
      currentStep: null == currentStep
          ? _self.currentStep
          : currentStep // ignore: cast_nullable_to_non_nullable
              as int,
      applicationId: freezed == applicationId
          ? _self.applicationId
          : applicationId // ignore: cast_nullable_to_non_nullable
              as String?,
      isSaving: null == isSaving
          ? _self.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      isSubmitting: null == isSubmitting
          ? _self.isSubmitting
          : isSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      brandName: null == brandName
          ? _self.brandName
          : brandName // ignore: cast_nullable_to_non_nullable
              as String,
      introduction: null == introduction
          ? _self.introduction
          : introduction // ignore: cast_nullable_to_non_nullable
              as String,
      profileImagePath: freezed == profileImagePath
          ? _self.profileImagePath
          : profileImagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      profileImageFile: freezed == profileImageFile
          ? _self.profileImageFile
          : profileImageFile // ignore: cast_nullable_to_non_nullable
              as XFile?,
      bizType: null == bizType
          ? _self.bizType
          : bizType // ignore: cast_nullable_to_non_nullable
              as String,
      bizName: null == bizName
          ? _self.bizName
          : bizName // ignore: cast_nullable_to_non_nullable
              as String,
      bizNumber: null == bizNumber
          ? _self.bizNumber
          : bizNumber // ignore: cast_nullable_to_non_nullable
              as String,
      representativeName: null == representativeName
          ? _self.representativeName
          : representativeName // ignore: cast_nullable_to_non_nullable
              as String,
      contactPhone: null == contactPhone
          ? _self.contactPhone
          : contactPhone // ignore: cast_nullable_to_non_nullable
              as String,
      contactEmail: null == contactEmail
          ? _self.contactEmail
          : contactEmail // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _self.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      bankName: null == bankName
          ? _self.bankName
          : bankName // ignore: cast_nullable_to_non_nullable
              as String,
      accountNumber: null == accountNumber
          ? _self.accountNumber
          : accountNumber // ignore: cast_nullable_to_non_nullable
              as String,
      accountHolder: null == accountHolder
          ? _self.accountHolder
          : accountHolder // ignore: cast_nullable_to_non_nullable
              as String,
      taxEmail: null == taxEmail
          ? _self.taxEmail
          : taxEmail // ignore: cast_nullable_to_non_nullable
              as String,
      bizRegistrationPath: freezed == bizRegistrationPath
          ? _self.bizRegistrationPath
          : bizRegistrationPath // ignore: cast_nullable_to_non_nullable
              as String?,
      bizRegistrationFile: freezed == bizRegistrationFile
          ? _self.bizRegistrationFile
          : bizRegistrationFile // ignore: cast_nullable_to_non_nullable
              as XFile?,
      bankbookPath: freezed == bankbookPath
          ? _self.bankbookPath
          : bankbookPath // ignore: cast_nullable_to_non_nullable
              as String?,
      bankbookFile: freezed == bankbookFile
          ? _self.bankbookFile
          : bankbookFile // ignore: cast_nullable_to_non_nullable
              as XFile?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as AsyncValue<void>,
    ));
  }
}

/// Adds pattern-matching-related methods to [PartnerApplyState].
extension PartnerApplyStatePatterns on PartnerApplyState {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_PartnerApplyState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PartnerApplyState() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_PartnerApplyState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PartnerApplyState():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_PartnerApplyState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PartnerApplyState() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            int currentStep,
            String? applicationId,
            bool isSaving,
            bool isSubmitting,
            String brandName,
            String introduction,
            String? profileImagePath,
            XFile? profileImageFile,
            String bizType,
            String bizName,
            String bizNumber,
            String representativeName,
            String contactPhone,
            String contactEmail,
            String address,
            String bankName,
            String accountNumber,
            String accountHolder,
            String taxEmail,
            String? bizRegistrationPath,
            XFile? bizRegistrationFile,
            String? bankbookPath,
            XFile? bankbookFile,
            AsyncValue<void> status)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PartnerApplyState() when $default != null:
        return $default(
            _that.currentStep,
            _that.applicationId,
            _that.isSaving,
            _that.isSubmitting,
            _that.brandName,
            _that.introduction,
            _that.profileImagePath,
            _that.profileImageFile,
            _that.bizType,
            _that.bizName,
            _that.bizNumber,
            _that.representativeName,
            _that.contactPhone,
            _that.contactEmail,
            _that.address,
            _that.bankName,
            _that.accountNumber,
            _that.accountHolder,
            _that.taxEmail,
            _that.bizRegistrationPath,
            _that.bizRegistrationFile,
            _that.bankbookPath,
            _that.bankbookFile,
            _that.status);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            int currentStep,
            String? applicationId,
            bool isSaving,
            bool isSubmitting,
            String brandName,
            String introduction,
            String? profileImagePath,
            XFile? profileImageFile,
            String bizType,
            String bizName,
            String bizNumber,
            String representativeName,
            String contactPhone,
            String contactEmail,
            String address,
            String bankName,
            String accountNumber,
            String accountHolder,
            String taxEmail,
            String? bizRegistrationPath,
            XFile? bizRegistrationFile,
            String? bankbookPath,
            XFile? bankbookFile,
            AsyncValue<void> status)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PartnerApplyState():
        return $default(
            _that.currentStep,
            _that.applicationId,
            _that.isSaving,
            _that.isSubmitting,
            _that.brandName,
            _that.introduction,
            _that.profileImagePath,
            _that.profileImageFile,
            _that.bizType,
            _that.bizName,
            _that.bizNumber,
            _that.representativeName,
            _that.contactPhone,
            _that.contactEmail,
            _that.address,
            _that.bankName,
            _that.accountNumber,
            _that.accountHolder,
            _that.taxEmail,
            _that.bizRegistrationPath,
            _that.bizRegistrationFile,
            _that.bankbookPath,
            _that.bankbookFile,
            _that.status);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            int currentStep,
            String? applicationId,
            bool isSaving,
            bool isSubmitting,
            String brandName,
            String introduction,
            String? profileImagePath,
            XFile? profileImageFile,
            String bizType,
            String bizName,
            String bizNumber,
            String representativeName,
            String contactPhone,
            String contactEmail,
            String address,
            String bankName,
            String accountNumber,
            String accountHolder,
            String taxEmail,
            String? bizRegistrationPath,
            XFile? bizRegistrationFile,
            String? bankbookPath,
            XFile? bankbookFile,
            AsyncValue<void> status)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PartnerApplyState() when $default != null:
        return $default(
            _that.currentStep,
            _that.applicationId,
            _that.isSaving,
            _that.isSubmitting,
            _that.brandName,
            _that.introduction,
            _that.profileImagePath,
            _that.profileImageFile,
            _that.bizType,
            _that.bizName,
            _that.bizNumber,
            _that.representativeName,
            _that.contactPhone,
            _that.contactEmail,
            _that.address,
            _that.bankName,
            _that.accountNumber,
            _that.accountHolder,
            _that.taxEmail,
            _that.bizRegistrationPath,
            _that.bizRegistrationFile,
            _that.bankbookPath,
            _that.bankbookFile,
            _that.status);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _PartnerApplyState implements PartnerApplyState {
  const _PartnerApplyState(
      {this.currentStep = 0,
      this.applicationId,
      this.isSaving = false,
      this.isSubmitting = false,
      this.brandName = '',
      this.introduction = '',
      this.profileImagePath,
      this.profileImageFile,
      this.bizType = 'individual',
      this.bizName = '',
      this.bizNumber = '',
      this.representativeName = '',
      this.contactPhone = '',
      this.contactEmail = '',
      this.address = '',
      this.bankName = '',
      this.accountNumber = '',
      this.accountHolder = '',
      this.taxEmail = '',
      this.bizRegistrationPath,
      this.bizRegistrationFile,
      this.bankbookPath,
      this.bankbookFile,
      this.status = const AsyncValue<void>.data(null)});

  @override
  @JsonKey()
  final int currentStep;
  @override
  final String? applicationId;
  @override
  @JsonKey()
  final bool isSaving;
  @override
  @JsonKey()
  final bool isSubmitting;
// Step 1: Basic Info
  @override
  @JsonKey()
  final String brandName;
  @override
  @JsonKey()
  final String introduction;
  @override
  final String? profileImagePath;
  @override
  final XFile? profileImageFile;
// Step 2: Business Info
  @override
  @JsonKey()
  final String bizType;
  @override
  @JsonKey()
  final String bizName;
  @override
  @JsonKey()
  final String bizNumber;
  @override
  @JsonKey()
  final String representativeName;
// Step 3: Contact & Settlement
  @override
  @JsonKey()
  final String contactPhone;
  @override
  @JsonKey()
  final String contactEmail;
  @override
  @JsonKey()
  final String address;
  @override
  @JsonKey()
  final String bankName;
  @override
  @JsonKey()
  final String accountNumber;
  @override
  @JsonKey()
  final String accountHolder;
  @override
  @JsonKey()
  final String taxEmail;
// Step 4: Documents
  @override
  final String? bizRegistrationPath;
  @override
  final XFile? bizRegistrationFile;
  @override
  final String? bankbookPath;
  @override
  final XFile? bankbookFile;
// Global status
  @override
  @JsonKey()
  final AsyncValue<void> status;

  /// Create a copy of PartnerApplyState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PartnerApplyStateCopyWith<_PartnerApplyState> get copyWith =>
      __$PartnerApplyStateCopyWithImpl<_PartnerApplyState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PartnerApplyState &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.applicationId, applicationId) ||
                other.applicationId == applicationId) &&
            (identical(other.isSaving, isSaving) ||
                other.isSaving == isSaving) &&
            (identical(other.isSubmitting, isSubmitting) ||
                other.isSubmitting == isSubmitting) &&
            (identical(other.brandName, brandName) ||
                other.brandName == brandName) &&
            (identical(other.introduction, introduction) ||
                other.introduction == introduction) &&
            (identical(other.profileImagePath, profileImagePath) ||
                other.profileImagePath == profileImagePath) &&
            (identical(other.profileImageFile, profileImageFile) ||
                other.profileImageFile == profileImageFile) &&
            (identical(other.bizType, bizType) || other.bizType == bizType) &&
            (identical(other.bizName, bizName) || other.bizName == bizName) &&
            (identical(other.bizNumber, bizNumber) ||
                other.bizNumber == bizNumber) &&
            (identical(other.representativeName, representativeName) ||
                other.representativeName == representativeName) &&
            (identical(other.contactPhone, contactPhone) ||
                other.contactPhone == contactPhone) &&
            (identical(other.contactEmail, contactEmail) ||
                other.contactEmail == contactEmail) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.bankName, bankName) ||
                other.bankName == bankName) &&
            (identical(other.accountNumber, accountNumber) ||
                other.accountNumber == accountNumber) &&
            (identical(other.accountHolder, accountHolder) ||
                other.accountHolder == accountHolder) &&
            (identical(other.taxEmail, taxEmail) ||
                other.taxEmail == taxEmail) &&
            (identical(other.bizRegistrationPath, bizRegistrationPath) ||
                other.bizRegistrationPath == bizRegistrationPath) &&
            (identical(other.bizRegistrationFile, bizRegistrationFile) ||
                other.bizRegistrationFile == bizRegistrationFile) &&
            (identical(other.bankbookPath, bankbookPath) ||
                other.bankbookPath == bankbookPath) &&
            (identical(other.bankbookFile, bankbookFile) ||
                other.bankbookFile == bankbookFile) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        currentStep,
        applicationId,
        isSaving,
        isSubmitting,
        brandName,
        introduction,
        profileImagePath,
        profileImageFile,
        bizType,
        bizName,
        bizNumber,
        representativeName,
        contactPhone,
        contactEmail,
        address,
        bankName,
        accountNumber,
        accountHolder,
        taxEmail,
        bizRegistrationPath,
        bizRegistrationFile,
        bankbookPath,
        bankbookFile,
        status
      ]);

  @override
  String toString() {
    return 'PartnerApplyState(currentStep: $currentStep, applicationId: $applicationId, isSaving: $isSaving, isSubmitting: $isSubmitting, brandName: $brandName, introduction: $introduction, profileImagePath: $profileImagePath, profileImageFile: $profileImageFile, bizType: $bizType, bizName: $bizName, bizNumber: $bizNumber, representativeName: $representativeName, contactPhone: $contactPhone, contactEmail: $contactEmail, address: $address, bankName: $bankName, accountNumber: $accountNumber, accountHolder: $accountHolder, taxEmail: $taxEmail, bizRegistrationPath: $bizRegistrationPath, bizRegistrationFile: $bizRegistrationFile, bankbookPath: $bankbookPath, bankbookFile: $bankbookFile, status: $status)';
  }
}

/// @nodoc
abstract mixin class _$PartnerApplyStateCopyWith<$Res>
    implements $PartnerApplyStateCopyWith<$Res> {
  factory _$PartnerApplyStateCopyWith(
          _PartnerApplyState value, $Res Function(_PartnerApplyState) _then) =
      __$PartnerApplyStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int currentStep,
      String? applicationId,
      bool isSaving,
      bool isSubmitting,
      String brandName,
      String introduction,
      String? profileImagePath,
      XFile? profileImageFile,
      String bizType,
      String bizName,
      String bizNumber,
      String representativeName,
      String contactPhone,
      String contactEmail,
      String address,
      String bankName,
      String accountNumber,
      String accountHolder,
      String taxEmail,
      String? bizRegistrationPath,
      XFile? bizRegistrationFile,
      String? bankbookPath,
      XFile? bankbookFile,
      AsyncValue<void> status});
}

/// @nodoc
class __$PartnerApplyStateCopyWithImpl<$Res>
    implements _$PartnerApplyStateCopyWith<$Res> {
  __$PartnerApplyStateCopyWithImpl(this._self, this._then);

  final _PartnerApplyState _self;
  final $Res Function(_PartnerApplyState) _then;

  /// Create a copy of PartnerApplyState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? currentStep = null,
    Object? applicationId = freezed,
    Object? isSaving = null,
    Object? isSubmitting = null,
    Object? brandName = null,
    Object? introduction = null,
    Object? profileImagePath = freezed,
    Object? profileImageFile = freezed,
    Object? bizType = null,
    Object? bizName = null,
    Object? bizNumber = null,
    Object? representativeName = null,
    Object? contactPhone = null,
    Object? contactEmail = null,
    Object? address = null,
    Object? bankName = null,
    Object? accountNumber = null,
    Object? accountHolder = null,
    Object? taxEmail = null,
    Object? bizRegistrationPath = freezed,
    Object? bizRegistrationFile = freezed,
    Object? bankbookPath = freezed,
    Object? bankbookFile = freezed,
    Object? status = null,
  }) {
    return _then(_PartnerApplyState(
      currentStep: null == currentStep
          ? _self.currentStep
          : currentStep // ignore: cast_nullable_to_non_nullable
              as int,
      applicationId: freezed == applicationId
          ? _self.applicationId
          : applicationId // ignore: cast_nullable_to_non_nullable
              as String?,
      isSaving: null == isSaving
          ? _self.isSaving
          : isSaving // ignore: cast_nullable_to_non_nullable
              as bool,
      isSubmitting: null == isSubmitting
          ? _self.isSubmitting
          : isSubmitting // ignore: cast_nullable_to_non_nullable
              as bool,
      brandName: null == brandName
          ? _self.brandName
          : brandName // ignore: cast_nullable_to_non_nullable
              as String,
      introduction: null == introduction
          ? _self.introduction
          : introduction // ignore: cast_nullable_to_non_nullable
              as String,
      profileImagePath: freezed == profileImagePath
          ? _self.profileImagePath
          : profileImagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      profileImageFile: freezed == profileImageFile
          ? _self.profileImageFile
          : profileImageFile // ignore: cast_nullable_to_non_nullable
              as XFile?,
      bizType: null == bizType
          ? _self.bizType
          : bizType // ignore: cast_nullable_to_non_nullable
              as String,
      bizName: null == bizName
          ? _self.bizName
          : bizName // ignore: cast_nullable_to_non_nullable
              as String,
      bizNumber: null == bizNumber
          ? _self.bizNumber
          : bizNumber // ignore: cast_nullable_to_non_nullable
              as String,
      representativeName: null == representativeName
          ? _self.representativeName
          : representativeName // ignore: cast_nullable_to_non_nullable
              as String,
      contactPhone: null == contactPhone
          ? _self.contactPhone
          : contactPhone // ignore: cast_nullable_to_non_nullable
              as String,
      contactEmail: null == contactEmail
          ? _self.contactEmail
          : contactEmail // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _self.address
          : address // ignore: cast_nullable_to_non_nullable
              as String,
      bankName: null == bankName
          ? _self.bankName
          : bankName // ignore: cast_nullable_to_non_nullable
              as String,
      accountNumber: null == accountNumber
          ? _self.accountNumber
          : accountNumber // ignore: cast_nullable_to_non_nullable
              as String,
      accountHolder: null == accountHolder
          ? _self.accountHolder
          : accountHolder // ignore: cast_nullable_to_non_nullable
              as String,
      taxEmail: null == taxEmail
          ? _self.taxEmail
          : taxEmail // ignore: cast_nullable_to_non_nullable
              as String,
      bizRegistrationPath: freezed == bizRegistrationPath
          ? _self.bizRegistrationPath
          : bizRegistrationPath // ignore: cast_nullable_to_non_nullable
              as String?,
      bizRegistrationFile: freezed == bizRegistrationFile
          ? _self.bizRegistrationFile
          : bizRegistrationFile // ignore: cast_nullable_to_non_nullable
              as XFile?,
      bankbookPath: freezed == bankbookPath
          ? _self.bankbookPath
          : bankbookPath // ignore: cast_nullable_to_non_nullable
              as String?,
      bankbookFile: freezed == bankbookFile
          ? _self.bankbookFile
          : bankbookFile // ignore: cast_nullable_to_non_nullable
              as XFile?,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as AsyncValue<void>,
    ));
  }
}

// dart format on
