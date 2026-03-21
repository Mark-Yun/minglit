// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_application_list_page.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(partnerApplications)
const partnerApplicationsProvider = PartnerApplicationsFamily._();

final class PartnerApplicationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PartnerApplication>>,
          List<PartnerApplication>,
          FutureOr<List<PartnerApplication>>
        >
    with
        $FutureModifier<List<PartnerApplication>>,
        $FutureProvider<List<PartnerApplication>> {
  const PartnerApplicationsProvider._({
    required PartnerApplicationsFamily super.from,
    required ({String status, String? searchTerm}) super.argument,
  }) : super(
         retry: null,
         name: r'partnerApplicationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$partnerApplicationsHash();

  @override
  String toString() {
    return r'partnerApplicationsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<PartnerApplication>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PartnerApplication>> create(Ref ref) {
    final argument = this.argument as ({String status, String? searchTerm});
    return partnerApplications(
      ref,
      status: argument.status,
      searchTerm: argument.searchTerm,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PartnerApplicationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$partnerApplicationsHash() =>
    r'445ac8964740d66220df90e7dc3fc2ee8bb75a0c';

final class PartnerApplicationsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<PartnerApplication>>,
          ({String status, String? searchTerm})
        > {
  const PartnerApplicationsFamily._()
    : super(
        retry: null,
        name: r'partnerApplicationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PartnerApplicationsProvider call({
    String status = 'all',
    String? searchTerm,
  }) => PartnerApplicationsProvider._(
    argument: (status: status, searchTerm: searchTerm),
    from: this,
  );

  @override
  String toString() => r'partnerApplicationsProvider';
}
