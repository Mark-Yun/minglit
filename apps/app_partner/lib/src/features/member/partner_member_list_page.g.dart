// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_member_list_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// **Local Provider: Partner Members**

@ProviderFor(partnerMembers)
const partnerMembersProvider = PartnerMembersFamily._();

/// **Local Provider: Partner Members**

final class PartnerMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  /// **Local Provider: Partner Members**
  const PartnerMembersProvider._({
    required PartnerMembersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'partnerMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$partnerMembersHash();

  @override
  String toString() {
    return r'partnerMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return partnerMembers(ref, partnerId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PartnerMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partnerMembersHash() => r'61400c3d950954968fc732e9ade14a2c7114faf5';

/// **Local Provider: Partner Members**

final class PartnerMembersFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Map<String, dynamic>>>,
          String
        > {
  const PartnerMembersFamily._()
    : super(
        retry: null,
        name: r'partnerMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// **Local Provider: Partner Members**

  PartnerMembersProvider call({required String partnerId}) =>
      PartnerMembersProvider._(argument: partnerId, from: this);

  @override
  String toString() => r'partnerMembersProvider';
}
