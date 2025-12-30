// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VerificationFormField {

/// Unique key for the field (e.g., 'company_name').
 String get key;/// Input type: 'text', 'number', 'file', 'date', etc.
 String get type;/// UI Label (e.g., '회사명').
 String get label;/// Whether this field is mandatory.
 bool get required;/// Placeholder text for the input.
 String? get placeholder;/// List of options (for select/radio types).
 List<String>? get options;
/// Create a copy of VerificationFormField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationFormFieldCopyWith<VerificationFormField> get copyWith => _$VerificationFormFieldCopyWithImpl<VerificationFormField>(this as VerificationFormField, _$identity);

  /// Serializes this VerificationFormField to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationFormField&&(identical(other.key, key) || other.key == key)&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.required, required) || other.required == required)&&(identical(other.placeholder, placeholder) || other.placeholder == placeholder)&&const DeepCollectionEquality().equals(other.options, options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,type,label,required,placeholder,const DeepCollectionEquality().hash(options));

@override
String toString() {
  return 'VerificationFormField(key: $key, type: $type, label: $label, required: $required, placeholder: $placeholder, options: $options)';
}


}

/// @nodoc
abstract mixin class $VerificationFormFieldCopyWith<$Res>  {
  factory $VerificationFormFieldCopyWith(VerificationFormField value, $Res Function(VerificationFormField) _then) = _$VerificationFormFieldCopyWithImpl;
@useResult
$Res call({
 String key, String type, String label, bool required, String? placeholder, List<String>? options
});




}
/// @nodoc
class _$VerificationFormFieldCopyWithImpl<$Res>
    implements $VerificationFormFieldCopyWith<$Res> {
  _$VerificationFormFieldCopyWithImpl(this._self, this._then);

  final VerificationFormField _self;
  final $Res Function(VerificationFormField) _then;

/// Create a copy of VerificationFormField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? type = null,Object? label = null,Object? required = null,Object? placeholder = freezed,Object? options = freezed,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,placeholder: freezed == placeholder ? _self.placeholder : placeholder // ignore: cast_nullable_to_non_nullable
as String?,options: freezed == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}

}


/// Adds pattern-matching-related methods to [VerificationFormField].
extension VerificationFormFieldPatterns on VerificationFormField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationFormField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationFormField() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationFormField value)  $default,){
final _that = this;
switch (_that) {
case _VerificationFormField():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationFormField value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationFormField() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String type,  String label,  bool required,  String? placeholder,  List<String>? options)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationFormField() when $default != null:
return $default(_that.key,_that.type,_that.label,_that.required,_that.placeholder,_that.options);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String type,  String label,  bool required,  String? placeholder,  List<String>? options)  $default,) {final _that = this;
switch (_that) {
case _VerificationFormField():
return $default(_that.key,_that.type,_that.label,_that.required,_that.placeholder,_that.options);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String type,  String label,  bool required,  String? placeholder,  List<String>? options)?  $default,) {final _that = this;
switch (_that) {
case _VerificationFormField() when $default != null:
return $default(_that.key,_that.type,_that.label,_that.required,_that.placeholder,_that.options);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationFormField implements VerificationFormField {
  const _VerificationFormField({required this.key, required this.type, required this.label, this.required = true, this.placeholder, final  List<String>? options}): _options = options;
  factory _VerificationFormField.fromJson(Map<String, dynamic> json) => _$VerificationFormFieldFromJson(json);

/// Unique key for the field (e.g., 'company_name').
@override final  String key;
/// Input type: 'text', 'number', 'file', 'date', etc.
@override final  String type;
/// UI Label (e.g., '회사명').
@override final  String label;
/// Whether this field is mandatory.
@override@JsonKey() final  bool required;
/// Placeholder text for the input.
@override final  String? placeholder;
/// List of options (for select/radio types).
 final  List<String>? _options;
/// List of options (for select/radio types).
@override List<String>? get options {
  final value = _options;
  if (value == null) return null;
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of VerificationFormField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationFormFieldCopyWith<_VerificationFormField> get copyWith => __$VerificationFormFieldCopyWithImpl<_VerificationFormField>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationFormFieldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationFormField&&(identical(other.key, key) || other.key == key)&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.required, required) || other.required == required)&&(identical(other.placeholder, placeholder) || other.placeholder == placeholder)&&const DeepCollectionEquality().equals(other._options, _options));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,type,label,required,placeholder,const DeepCollectionEquality().hash(_options));

@override
String toString() {
  return 'VerificationFormField(key: $key, type: $type, label: $label, required: $required, placeholder: $placeholder, options: $options)';
}


}

/// @nodoc
abstract mixin class _$VerificationFormFieldCopyWith<$Res> implements $VerificationFormFieldCopyWith<$Res> {
  factory _$VerificationFormFieldCopyWith(_VerificationFormField value, $Res Function(_VerificationFormField) _then) = __$VerificationFormFieldCopyWithImpl;
@override @useResult
$Res call({
 String key, String type, String label, bool required, String? placeholder, List<String>? options
});




}
/// @nodoc
class __$VerificationFormFieldCopyWithImpl<$Res>
    implements _$VerificationFormFieldCopyWith<$Res> {
  __$VerificationFormFieldCopyWithImpl(this._self, this._then);

  final _VerificationFormField _self;
  final $Res Function(_VerificationFormField) _then;

/// Create a copy of VerificationFormField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? type = null,Object? label = null,Object? required = null,Object? placeholder = freezed,Object? options = freezed,}) {
  return _then(_VerificationFormField(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,required: null == required ? _self.required : required // ignore: cast_nullable_to_non_nullable
as bool,placeholder: freezed == placeholder ? _self.placeholder : placeholder // ignore: cast_nullable_to_non_nullable
as String?,options: freezed == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<String>?,
  ));
}


}


/// @nodoc
mixin _$Verification {

 String get id; VerificationCategory get category;/// Internal identifier (e.g., 'global_career').
@JsonKey(name: 'internal_name') String get internalName;/// Display name shown to users (e.g., '직장 인증').
@JsonKey(name: 'display_name') String get displayName;/// Partner ID who owns this verification. Null means Global/System verification.
@JsonKey(name: 'partner_id') String? get partnerId; String? get description;/// Icon identifier (e.g., 'briefcase').
@JsonKey(name: 'icon_key') String? get iconKey;/// Dynamic form definition.
@JsonKey(name: 'form_schema') List<VerificationFormField> get formSchema;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of Verification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationCopyWith<Verification> get copyWith => _$VerificationCopyWithImpl<Verification>(this as Verification, _$identity);

  /// Serializes this Verification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Verification&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.internalName, internalName) || other.internalName == internalName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.description, description) || other.description == description)&&(identical(other.iconKey, iconKey) || other.iconKey == iconKey)&&const DeepCollectionEquality().equals(other.formSchema, formSchema)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,internalName,displayName,partnerId,description,iconKey,const DeepCollectionEquality().hash(formSchema),isActive,createdAt);

@override
String toString() {
  return 'Verification(id: $id, category: $category, internalName: $internalName, displayName: $displayName, partnerId: $partnerId, description: $description, iconKey: $iconKey, formSchema: $formSchema, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $VerificationCopyWith<$Res>  {
  factory $VerificationCopyWith(Verification value, $Res Function(Verification) _then) = _$VerificationCopyWithImpl;
@useResult
$Res call({
 String id, VerificationCategory category,@JsonKey(name: 'internal_name') String internalName,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'partner_id') String? partnerId, String? description,@JsonKey(name: 'icon_key') String? iconKey,@JsonKey(name: 'form_schema') List<VerificationFormField> formSchema,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$VerificationCopyWithImpl<$Res>
    implements $VerificationCopyWith<$Res> {
  _$VerificationCopyWithImpl(this._self, this._then);

  final Verification _self;
  final $Res Function(Verification) _then;

/// Create a copy of Verification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? category = null,Object? internalName = null,Object? displayName = null,Object? partnerId = freezed,Object? description = freezed,Object? iconKey = freezed,Object? formSchema = null,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as VerificationCategory,internalName: null == internalName ? _self.internalName : internalName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,partnerId: freezed == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,iconKey: freezed == iconKey ? _self.iconKey : iconKey // ignore: cast_nullable_to_non_nullable
as String?,formSchema: null == formSchema ? _self.formSchema : formSchema // ignore: cast_nullable_to_non_nullable
as List<VerificationFormField>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Verification].
extension VerificationPatterns on Verification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Verification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Verification() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Verification value)  $default,){
final _that = this;
switch (_that) {
case _Verification():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Verification value)?  $default,){
final _that = this;
switch (_that) {
case _Verification() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  VerificationCategory category, @JsonKey(name: 'internal_name')  String internalName, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'partner_id')  String? partnerId,  String? description, @JsonKey(name: 'icon_key')  String? iconKey, @JsonKey(name: 'form_schema')  List<VerificationFormField> formSchema, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Verification() when $default != null:
return $default(_that.id,_that.category,_that.internalName,_that.displayName,_that.partnerId,_that.description,_that.iconKey,_that.formSchema,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  VerificationCategory category, @JsonKey(name: 'internal_name')  String internalName, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'partner_id')  String? partnerId,  String? description, @JsonKey(name: 'icon_key')  String? iconKey, @JsonKey(name: 'form_schema')  List<VerificationFormField> formSchema, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Verification():
return $default(_that.id,_that.category,_that.internalName,_that.displayName,_that.partnerId,_that.description,_that.iconKey,_that.formSchema,_that.isActive,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  VerificationCategory category, @JsonKey(name: 'internal_name')  String internalName, @JsonKey(name: 'display_name')  String displayName, @JsonKey(name: 'partner_id')  String? partnerId,  String? description, @JsonKey(name: 'icon_key')  String? iconKey, @JsonKey(name: 'form_schema')  List<VerificationFormField> formSchema, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Verification() when $default != null:
return $default(_that.id,_that.category,_that.internalName,_that.displayName,_that.partnerId,_that.description,_that.iconKey,_that.formSchema,_that.isActive,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Verification implements Verification {
  const _Verification({required this.id, required this.category, @JsonKey(name: 'internal_name') required this.internalName, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(name: 'partner_id') this.partnerId, this.description, @JsonKey(name: 'icon_key') this.iconKey, @JsonKey(name: 'form_schema') final  List<VerificationFormField> formSchema = const [], @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'created_at') this.createdAt}): _formSchema = formSchema;
  factory _Verification.fromJson(Map<String, dynamic> json) => _$VerificationFromJson(json);

@override final  String id;
@override final  VerificationCategory category;
/// Internal identifier (e.g., 'global_career').
@override@JsonKey(name: 'internal_name') final  String internalName;
/// Display name shown to users (e.g., '직장 인증').
@override@JsonKey(name: 'display_name') final  String displayName;
/// Partner ID who owns this verification. Null means Global/System verification.
@override@JsonKey(name: 'partner_id') final  String? partnerId;
@override final  String? description;
/// Icon identifier (e.g., 'briefcase').
@override@JsonKey(name: 'icon_key') final  String? iconKey;
/// Dynamic form definition.
 final  List<VerificationFormField> _formSchema;
/// Dynamic form definition.
@override@JsonKey(name: 'form_schema') List<VerificationFormField> get formSchema {
  if (_formSchema is EqualUnmodifiableListView) return _formSchema;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_formSchema);
}

@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of Verification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationCopyWith<_Verification> get copyWith => __$VerificationCopyWithImpl<_Verification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Verification&&(identical(other.id, id) || other.id == id)&&(identical(other.category, category) || other.category == category)&&(identical(other.internalName, internalName) || other.internalName == internalName)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.partnerId, partnerId) || other.partnerId == partnerId)&&(identical(other.description, description) || other.description == description)&&(identical(other.iconKey, iconKey) || other.iconKey == iconKey)&&const DeepCollectionEquality().equals(other._formSchema, _formSchema)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,category,internalName,displayName,partnerId,description,iconKey,const DeepCollectionEquality().hash(_formSchema),isActive,createdAt);

@override
String toString() {
  return 'Verification(id: $id, category: $category, internalName: $internalName, displayName: $displayName, partnerId: $partnerId, description: $description, iconKey: $iconKey, formSchema: $formSchema, isActive: $isActive, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$VerificationCopyWith<$Res> implements $VerificationCopyWith<$Res> {
  factory _$VerificationCopyWith(_Verification value, $Res Function(_Verification) _then) = __$VerificationCopyWithImpl;
@override @useResult
$Res call({
 String id, VerificationCategory category,@JsonKey(name: 'internal_name') String internalName,@JsonKey(name: 'display_name') String displayName,@JsonKey(name: 'partner_id') String? partnerId, String? description,@JsonKey(name: 'icon_key') String? iconKey,@JsonKey(name: 'form_schema') List<VerificationFormField> formSchema,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$VerificationCopyWithImpl<$Res>
    implements _$VerificationCopyWith<$Res> {
  __$VerificationCopyWithImpl(this._self, this._then);

  final _Verification _self;
  final $Res Function(_Verification) _then;

/// Create a copy of Verification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? category = null,Object? internalName = null,Object? displayName = null,Object? partnerId = freezed,Object? description = freezed,Object? iconKey = freezed,Object? formSchema = null,Object? isActive = null,Object? createdAt = freezed,}) {
  return _then(_Verification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as VerificationCategory,internalName: null == internalName ? _self.internalName : internalName // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,partnerId: freezed == partnerId ? _self.partnerId : partnerId // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,iconKey: freezed == iconKey ? _self.iconKey : iconKey // ignore: cast_nullable_to_non_nullable
as String?,formSchema: null == formSchema ? _self._formSchema : formSchema // ignore: cast_nullable_to_non_nullable
as List<VerificationFormField>,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$VerificationRequirementStatus {

 Verification get master;/// User's original data (내 서랍 데이터)
@JsonKey(name: 'user_verification') Map<String, dynamic>? get userVerification;/// Active submission to a partner (제출 내역)
@JsonKey(name: 'active_submission') Map<String, dynamic>? get activeSubmission;/// Final verified result (출입증)
@JsonKey(name: 'verified_result') Map<String, dynamic>? get verifiedResult;
/// Create a copy of VerificationRequirementStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationRequirementStatusCopyWith<VerificationRequirementStatus> get copyWith => _$VerificationRequirementStatusCopyWithImpl<VerificationRequirementStatus>(this as VerificationRequirementStatus, _$identity);

  /// Serializes this VerificationRequirementStatus to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationRequirementStatus&&(identical(other.master, master) || other.master == master)&&const DeepCollectionEquality().equals(other.userVerification, userVerification)&&const DeepCollectionEquality().equals(other.activeSubmission, activeSubmission)&&const DeepCollectionEquality().equals(other.verifiedResult, verifiedResult));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,master,const DeepCollectionEquality().hash(userVerification),const DeepCollectionEquality().hash(activeSubmission),const DeepCollectionEquality().hash(verifiedResult));

@override
String toString() {
  return 'VerificationRequirementStatus(master: $master, userVerification: $userVerification, activeSubmission: $activeSubmission, verifiedResult: $verifiedResult)';
}


}

/// @nodoc
abstract mixin class $VerificationRequirementStatusCopyWith<$Res>  {
  factory $VerificationRequirementStatusCopyWith(VerificationRequirementStatus value, $Res Function(VerificationRequirementStatus) _then) = _$VerificationRequirementStatusCopyWithImpl;
@useResult
$Res call({
 Verification master,@JsonKey(name: 'user_verification') Map<String, dynamic>? userVerification,@JsonKey(name: 'active_submission') Map<String, dynamic>? activeSubmission,@JsonKey(name: 'verified_result') Map<String, dynamic>? verifiedResult
});


$VerificationCopyWith<$Res> get master;

}
/// @nodoc
class _$VerificationRequirementStatusCopyWithImpl<$Res>
    implements $VerificationRequirementStatusCopyWith<$Res> {
  _$VerificationRequirementStatusCopyWithImpl(this._self, this._then);

  final VerificationRequirementStatus _self;
  final $Res Function(VerificationRequirementStatus) _then;

/// Create a copy of VerificationRequirementStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? master = null,Object? userVerification = freezed,Object? activeSubmission = freezed,Object? verifiedResult = freezed,}) {
  return _then(_self.copyWith(
master: null == master ? _self.master : master // ignore: cast_nullable_to_non_nullable
as Verification,userVerification: freezed == userVerification ? _self.userVerification : userVerification // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,activeSubmission: freezed == activeSubmission ? _self.activeSubmission : activeSubmission // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,verifiedResult: freezed == verifiedResult ? _self.verifiedResult : verifiedResult // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}
/// Create a copy of VerificationRequirementStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationCopyWith<$Res> get master {
  
  return $VerificationCopyWith<$Res>(_self.master, (value) {
    return _then(_self.copyWith(master: value));
  });
}
}


/// Adds pattern-matching-related methods to [VerificationRequirementStatus].
extension VerificationRequirementStatusPatterns on VerificationRequirementStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationRequirementStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationRequirementStatus() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationRequirementStatus value)  $default,){
final _that = this;
switch (_that) {
case _VerificationRequirementStatus():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationRequirementStatus value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationRequirementStatus() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Verification master, @JsonKey(name: 'user_verification')  Map<String, dynamic>? userVerification, @JsonKey(name: 'active_submission')  Map<String, dynamic>? activeSubmission, @JsonKey(name: 'verified_result')  Map<String, dynamic>? verifiedResult)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationRequirementStatus() when $default != null:
return $default(_that.master,_that.userVerification,_that.activeSubmission,_that.verifiedResult);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Verification master, @JsonKey(name: 'user_verification')  Map<String, dynamic>? userVerification, @JsonKey(name: 'active_submission')  Map<String, dynamic>? activeSubmission, @JsonKey(name: 'verified_result')  Map<String, dynamic>? verifiedResult)  $default,) {final _that = this;
switch (_that) {
case _VerificationRequirementStatus():
return $default(_that.master,_that.userVerification,_that.activeSubmission,_that.verifiedResult);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Verification master, @JsonKey(name: 'user_verification')  Map<String, dynamic>? userVerification, @JsonKey(name: 'active_submission')  Map<String, dynamic>? activeSubmission, @JsonKey(name: 'verified_result')  Map<String, dynamic>? verifiedResult)?  $default,) {final _that = this;
switch (_that) {
case _VerificationRequirementStatus() when $default != null:
return $default(_that.master,_that.userVerification,_that.activeSubmission,_that.verifiedResult);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationRequirementStatus extends VerificationRequirementStatus {
  const _VerificationRequirementStatus({required this.master, @JsonKey(name: 'user_verification') final  Map<String, dynamic>? userVerification, @JsonKey(name: 'active_submission') final  Map<String, dynamic>? activeSubmission, @JsonKey(name: 'verified_result') final  Map<String, dynamic>? verifiedResult}): _userVerification = userVerification,_activeSubmission = activeSubmission,_verifiedResult = verifiedResult,super._();
  factory _VerificationRequirementStatus.fromJson(Map<String, dynamic> json) => _$VerificationRequirementStatusFromJson(json);

@override final  Verification master;
/// User's original data (내 서랍 데이터)
 final  Map<String, dynamic>? _userVerification;
/// User's original data (내 서랍 데이터)
@override@JsonKey(name: 'user_verification') Map<String, dynamic>? get userVerification {
  final value = _userVerification;
  if (value == null) return null;
  if (_userVerification is EqualUnmodifiableMapView) return _userVerification;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Active submission to a partner (제출 내역)
 final  Map<String, dynamic>? _activeSubmission;
/// Active submission to a partner (제출 내역)
@override@JsonKey(name: 'active_submission') Map<String, dynamic>? get activeSubmission {
  final value = _activeSubmission;
  if (value == null) return null;
  if (_activeSubmission is EqualUnmodifiableMapView) return _activeSubmission;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// Final verified result (출입증)
 final  Map<String, dynamic>? _verifiedResult;
/// Final verified result (출입증)
@override@JsonKey(name: 'verified_result') Map<String, dynamic>? get verifiedResult {
  final value = _verifiedResult;
  if (value == null) return null;
  if (_verifiedResult is EqualUnmodifiableMapView) return _verifiedResult;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of VerificationRequirementStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationRequirementStatusCopyWith<_VerificationRequirementStatus> get copyWith => __$VerificationRequirementStatusCopyWithImpl<_VerificationRequirementStatus>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationRequirementStatusToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationRequirementStatus&&(identical(other.master, master) || other.master == master)&&const DeepCollectionEquality().equals(other._userVerification, _userVerification)&&const DeepCollectionEquality().equals(other._activeSubmission, _activeSubmission)&&const DeepCollectionEquality().equals(other._verifiedResult, _verifiedResult));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,master,const DeepCollectionEquality().hash(_userVerification),const DeepCollectionEquality().hash(_activeSubmission),const DeepCollectionEquality().hash(_verifiedResult));

@override
String toString() {
  return 'VerificationRequirementStatus(master: $master, userVerification: $userVerification, activeSubmission: $activeSubmission, verifiedResult: $verifiedResult)';
}


}

/// @nodoc
abstract mixin class _$VerificationRequirementStatusCopyWith<$Res> implements $VerificationRequirementStatusCopyWith<$Res> {
  factory _$VerificationRequirementStatusCopyWith(_VerificationRequirementStatus value, $Res Function(_VerificationRequirementStatus) _then) = __$VerificationRequirementStatusCopyWithImpl;
@override @useResult
$Res call({
 Verification master,@JsonKey(name: 'user_verification') Map<String, dynamic>? userVerification,@JsonKey(name: 'active_submission') Map<String, dynamic>? activeSubmission,@JsonKey(name: 'verified_result') Map<String, dynamic>? verifiedResult
});


@override $VerificationCopyWith<$Res> get master;

}
/// @nodoc
class __$VerificationRequirementStatusCopyWithImpl<$Res>
    implements _$VerificationRequirementStatusCopyWith<$Res> {
  __$VerificationRequirementStatusCopyWithImpl(this._self, this._then);

  final _VerificationRequirementStatus _self;
  final $Res Function(_VerificationRequirementStatus) _then;

/// Create a copy of VerificationRequirementStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? master = null,Object? userVerification = freezed,Object? activeSubmission = freezed,Object? verifiedResult = freezed,}) {
  return _then(_VerificationRequirementStatus(
master: null == master ? _self.master : master // ignore: cast_nullable_to_non_nullable
as Verification,userVerification: freezed == userVerification ? _self._userVerification : userVerification // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,activeSubmission: freezed == activeSubmission ? _self._activeSubmission : activeSubmission // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,verifiedResult: freezed == verifiedResult ? _self._verifiedResult : verifiedResult // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

/// Create a copy of VerificationRequirementStatus
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VerificationCopyWith<$Res> get master {
  
  return $VerificationCopyWith<$Res>(_self.master, (value) {
    return _then(_self.copyWith(master: value));
  });
}
}

// dart format on
