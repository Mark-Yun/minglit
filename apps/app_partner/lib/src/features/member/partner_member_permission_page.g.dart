// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_member_permission_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// **Local Provider: Single Partner Member**
///
/// Fetches details for a specific member.
/// Currently filters from the full list, but can be updated to fetch from DB directly.

@ProviderFor(partnerMember)
const partnerMemberProvider = PartnerMemberFamily._();

/// **Local Provider: Single Partner Member**
///
/// Fetches details for a specific member.
/// Currently filters from the full list, but can be updated to fetch from DB directly.

final class PartnerMemberProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, dynamic>?>,
          Map<String, dynamic>?,
          FutureOr<Map<String, dynamic>?>
        >
    with
        $FutureModifier<Map<String, dynamic>?>,
        $FutureProvider<Map<String, dynamic>?> {
  /// **Local Provider: Single Partner Member**
  ///
  /// Fetches details for a specific member.
  /// Currently filters from the full list, but can be updated to fetch from DB directly.
  const PartnerMemberProvider._({
    required PartnerMemberFamily super.from,
    required ({String partnerId, String targetUserId}) super.argument,
  }) : super(
         retry: null,
         name: r'partnerMemberProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$partnerMemberHash();

  @override
  String toString() {
    return r'partnerMemberProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, dynamic>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, dynamic>?> create(Ref ref) {
    final argument = this.argument as ({String partnerId, String targetUserId});
    return partnerMember(
      ref,
      partnerId: argument.partnerId,
      targetUserId: argument.targetUserId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PartnerMemberProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partnerMemberHash() => r'441e81eb6f5388fa16ed763fcd1edb45dd07785e';

/// **Local Provider: Single Partner Member**
///
/// Fetches details for a specific member.
/// Currently filters from the full list, but can be updated to fetch from DB directly.

final class PartnerMemberFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<String, dynamic>?>,
          ({String partnerId, String targetUserId})
        > {
  const PartnerMemberFamily._()
    : super(
        retry: null,
        name: r'partnerMemberProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// **Local Provider: Single Partner Member**
  ///
  /// Fetches details for a specific member.
  /// Currently filters from the full list, but can be updated to fetch from DB directly.

  PartnerMemberProvider call({
    required String partnerId,
    required String targetUserId,
  }) => PartnerMemberProvider._(
    argument: (partnerId: partnerId, targetUserId: targetUserId),
    from: this,
  );

  @override
  String toString() => r'partnerMemberProvider';
}
