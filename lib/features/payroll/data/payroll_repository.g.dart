// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$payrollRepositoryHash() => r'6a5e234710de20c05bf20e5df8097f5ac3c7876c';

/// See also [payrollRepository].
@ProviderFor(payrollRepository)
final payrollRepositoryProvider =
    AutoDisposeProvider<PayrollRepository>.internal(
  payrollRepository,
  name: r'payrollRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$payrollRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PayrollRepositoryRef = AutoDisposeProviderRef<PayrollRepository>;
String _$cleanerPaymentsStreamHash() =>
    r'3ab7cd56c046d77d18776f4ada7d4c9ccc56c0a6';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [cleanerPaymentsStream].
@ProviderFor(cleanerPaymentsStream)
const cleanerPaymentsStreamProvider = CleanerPaymentsStreamFamily();

/// See also [cleanerPaymentsStream].
class CleanerPaymentsStreamFamily
    extends Family<AsyncValue<List<PayrollPayment>>> {
  /// See also [cleanerPaymentsStream].
  const CleanerPaymentsStreamFamily();

  /// See also [cleanerPaymentsStream].
  CleanerPaymentsStreamProvider call(
    String companyId,
    String cleanerId,
  ) {
    return CleanerPaymentsStreamProvider(
      companyId,
      cleanerId,
    );
  }

  @override
  CleanerPaymentsStreamProvider getProviderOverride(
    covariant CleanerPaymentsStreamProvider provider,
  ) {
    return call(
      provider.companyId,
      provider.cleanerId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'cleanerPaymentsStreamProvider';
}

/// See also [cleanerPaymentsStream].
class CleanerPaymentsStreamProvider
    extends AutoDisposeStreamProvider<List<PayrollPayment>> {
  /// See also [cleanerPaymentsStream].
  CleanerPaymentsStreamProvider(
    String companyId,
    String cleanerId,
  ) : this._internal(
          (ref) => cleanerPaymentsStream(
            ref as CleanerPaymentsStreamRef,
            companyId,
            cleanerId,
          ),
          from: cleanerPaymentsStreamProvider,
          name: r'cleanerPaymentsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$cleanerPaymentsStreamHash,
          dependencies: CleanerPaymentsStreamFamily._dependencies,
          allTransitiveDependencies:
              CleanerPaymentsStreamFamily._allTransitiveDependencies,
          companyId: companyId,
          cleanerId: cleanerId,
        );

  CleanerPaymentsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.companyId,
    required this.cleanerId,
  }) : super.internal();

  final String companyId;
  final String cleanerId;

  @override
  Override overrideWith(
    Stream<List<PayrollPayment>> Function(CleanerPaymentsStreamRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CleanerPaymentsStreamProvider._internal(
        (ref) => create(ref as CleanerPaymentsStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        companyId: companyId,
        cleanerId: cleanerId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<PayrollPayment>> createElement() {
    return _CleanerPaymentsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CleanerPaymentsStreamProvider &&
        other.companyId == companyId &&
        other.cleanerId == cleanerId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, companyId.hashCode);
    hash = _SystemHash.combine(hash, cleanerId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CleanerPaymentsStreamRef
    on AutoDisposeStreamProviderRef<List<PayrollPayment>> {
  /// The parameter `companyId` of this provider.
  String get companyId;

  /// The parameter `cleanerId` of this provider.
  String get cleanerId;
}

class _CleanerPaymentsStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<PayrollPayment>>
    with CleanerPaymentsStreamRef {
  _CleanerPaymentsStreamProviderElement(super.provider);

  @override
  String get companyId => (origin as CleanerPaymentsStreamProvider).companyId;
  @override
  String get cleanerId => (origin as CleanerPaymentsStreamProvider).cleanerId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
