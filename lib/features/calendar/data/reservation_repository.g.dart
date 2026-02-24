// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dailyReservationsHash() => r'3fa8d6aedbf1d56102b6a0f0e85535b52ebdf9d4';

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

abstract class _$DailyReservations
    extends BuildlessAutoDisposeStreamNotifier<List<Reservation>> {
  late final DateTime date;

  Stream<List<Reservation>> build(
    DateTime date,
  );
}

/// See also [DailyReservations].
@ProviderFor(DailyReservations)
const dailyReservationsProvider = DailyReservationsFamily();

/// See also [DailyReservations].
class DailyReservationsFamily extends Family<AsyncValue<List<Reservation>>> {
  /// See also [DailyReservations].
  const DailyReservationsFamily();

  /// See also [DailyReservations].
  DailyReservationsProvider call(
    DateTime date,
  ) {
    return DailyReservationsProvider(
      date,
    );
  }

  @override
  DailyReservationsProvider getProviderOverride(
    covariant DailyReservationsProvider provider,
  ) {
    return call(
      provider.date,
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
  String? get name => r'dailyReservationsProvider';
}

/// See also [DailyReservations].
class DailyReservationsProvider extends AutoDisposeStreamNotifierProviderImpl<
    DailyReservations, List<Reservation>> {
  /// See also [DailyReservations].
  DailyReservationsProvider(
    DateTime date,
  ) : this._internal(
          () => DailyReservations()..date = date,
          from: dailyReservationsProvider,
          name: r'dailyReservationsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dailyReservationsHash,
          dependencies: DailyReservationsFamily._dependencies,
          allTransitiveDependencies:
              DailyReservationsFamily._allTransitiveDependencies,
          date: date,
        );

  DailyReservationsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Stream<List<Reservation>> runNotifierBuild(
    covariant DailyReservations notifier,
  ) {
    return notifier.build(
      date,
    );
  }

  @override
  Override overrideWith(DailyReservations Function() create) {
    return ProviderOverride(
      origin: this,
      override: DailyReservationsProvider._internal(
        () => create()..date = date,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeStreamNotifierProviderElement<DailyReservations, List<Reservation>>
      createElement() {
    return _DailyReservationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DailyReservationsProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DailyReservationsRef
    on AutoDisposeStreamNotifierProviderRef<List<Reservation>> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _DailyReservationsProviderElement
    extends AutoDisposeStreamNotifierProviderElement<DailyReservations,
        List<Reservation>> with DailyReservationsRef {
  _DailyReservationsProviderElement(super.provider);

  @override
  DateTime get date => (origin as DailyReservationsProvider).date;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
