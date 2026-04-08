// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dailyReservationsHash() => r'8951d3dcbf717494aef8eb26b6e13f814beac48f';

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

String _$dateRangeReservationsHash() =>
    r'bea7f2ea98d6605c9b12165f881985e7fcee2661';

abstract class _$DateRangeReservations
    extends BuildlessAutoDisposeStreamNotifier<
        Map<DateTime, List<Reservation>>> {
  late final DateTime startDate;
  late final DateTime endDate;

  Stream<Map<DateTime, List<Reservation>>> build(
    DateTime startDate,
    DateTime endDate,
  );
}

/// See also [DateRangeReservations].
@ProviderFor(DateRangeReservations)
const dateRangeReservationsProvider = DateRangeReservationsFamily();

/// See also [DateRangeReservations].
class DateRangeReservationsFamily
    extends Family<AsyncValue<Map<DateTime, List<Reservation>>>> {
  /// See also [DateRangeReservations].
  const DateRangeReservationsFamily();

  /// See also [DateRangeReservations].
  DateRangeReservationsProvider call(
    DateTime startDate,
    DateTime endDate,
  ) {
    return DateRangeReservationsProvider(
      startDate,
      endDate,
    );
  }

  @override
  DateRangeReservationsProvider getProviderOverride(
    covariant DateRangeReservationsProvider provider,
  ) {
    return call(
      provider.startDate,
      provider.endDate,
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
  String? get name => r'dateRangeReservationsProvider';
}

/// See also [DateRangeReservations].
class DateRangeReservationsProvider
    extends AutoDisposeStreamNotifierProviderImpl<DateRangeReservations,
        Map<DateTime, List<Reservation>>> {
  /// See also [DateRangeReservations].
  DateRangeReservationsProvider(
    DateTime startDate,
    DateTime endDate,
  ) : this._internal(
          () => DateRangeReservations()
            ..startDate = startDate
            ..endDate = endDate,
          from: dateRangeReservationsProvider,
          name: r'dateRangeReservationsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$dateRangeReservationsHash,
          dependencies: DateRangeReservationsFamily._dependencies,
          allTransitiveDependencies:
              DateRangeReservationsFamily._allTransitiveDependencies,
          startDate: startDate,
          endDate: endDate,
        );

  DateRangeReservationsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final DateTime startDate;
  final DateTime endDate;

  @override
  Stream<Map<DateTime, List<Reservation>>> runNotifierBuild(
    covariant DateRangeReservations notifier,
  ) {
    return notifier.build(
      startDate,
      endDate,
    );
  }

  @override
  Override overrideWith(DateRangeReservations Function() create) {
    return ProviderOverride(
      origin: this,
      override: DateRangeReservationsProvider._internal(
        () => create()
          ..startDate = startDate
          ..endDate = endDate,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeStreamNotifierProviderElement<DateRangeReservations,
      Map<DateTime, List<Reservation>>> createElement() {
    return _DateRangeReservationsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is DateRangeReservationsProvider &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin DateRangeReservationsRef
    on AutoDisposeStreamNotifierProviderRef<Map<DateTime, List<Reservation>>> {
  /// The parameter `startDate` of this provider.
  DateTime get startDate;

  /// The parameter `endDate` of this provider.
  DateTime get endDate;
}

class _DateRangeReservationsProviderElement
    extends AutoDisposeStreamNotifierProviderElement<DateRangeReservations,
        Map<DateTime, List<Reservation>>> with DateRangeReservationsRef {
  _DateRangeReservationsProviderElement(super.provider);

  @override
  DateTime get startDate => (origin as DateRangeReservationsProvider).startDate;
  @override
  DateTime get endDate => (origin as DateRangeReservationsProvider).endDate;
}

String _$monthlyTimelineHash() => r'9e7ae2c7bb6c7186bc8bcd14cc15fe716ba9737a';

abstract class _$MonthlyTimeline extends BuildlessAutoDisposeStreamNotifier<
    Map<String, List<TimelineReservation>>> {
  late final DateTime startDate;
  late final DateTime endDate;

  Stream<Map<String, List<TimelineReservation>>> build(
    DateTime startDate,
    DateTime endDate,
  );
}

/// See also [MonthlyTimeline].
@ProviderFor(MonthlyTimeline)
const monthlyTimelineProvider = MonthlyTimelineFamily();

/// See also [MonthlyTimeline].
class MonthlyTimelineFamily
    extends Family<AsyncValue<Map<String, List<TimelineReservation>>>> {
  /// See also [MonthlyTimeline].
  const MonthlyTimelineFamily();

  /// See also [MonthlyTimeline].
  MonthlyTimelineProvider call(
    DateTime startDate,
    DateTime endDate,
  ) {
    return MonthlyTimelineProvider(
      startDate,
      endDate,
    );
  }

  @override
  MonthlyTimelineProvider getProviderOverride(
    covariant MonthlyTimelineProvider provider,
  ) {
    return call(
      provider.startDate,
      provider.endDate,
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
  String? get name => r'monthlyTimelineProvider';
}

/// See also [MonthlyTimeline].
class MonthlyTimelineProvider extends AutoDisposeStreamNotifierProviderImpl<
    MonthlyTimeline, Map<String, List<TimelineReservation>>> {
  /// See also [MonthlyTimeline].
  MonthlyTimelineProvider(
    DateTime startDate,
    DateTime endDate,
  ) : this._internal(
          () => MonthlyTimeline()
            ..startDate = startDate
            ..endDate = endDate,
          from: monthlyTimelineProvider,
          name: r'monthlyTimelineProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$monthlyTimelineHash,
          dependencies: MonthlyTimelineFamily._dependencies,
          allTransitiveDependencies:
              MonthlyTimelineFamily._allTransitiveDependencies,
          startDate: startDate,
          endDate: endDate,
        );

  MonthlyTimelineProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.startDate,
    required this.endDate,
  }) : super.internal();

  final DateTime startDate;
  final DateTime endDate;

  @override
  Stream<Map<String, List<TimelineReservation>>> runNotifierBuild(
    covariant MonthlyTimeline notifier,
  ) {
    return notifier.build(
      startDate,
      endDate,
    );
  }

  @override
  Override overrideWith(MonthlyTimeline Function() create) {
    return ProviderOverride(
      origin: this,
      override: MonthlyTimelineProvider._internal(
        () => create()
          ..startDate = startDate
          ..endDate = endDate,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  @override
  AutoDisposeStreamNotifierProviderElement<MonthlyTimeline,
      Map<String, List<TimelineReservation>>> createElement() {
    return _MonthlyTimelineProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyTimelineProvider &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, startDate.hashCode);
    hash = _SystemHash.combine(hash, endDate.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MonthlyTimelineRef on AutoDisposeStreamNotifierProviderRef<
    Map<String, List<TimelineReservation>>> {
  /// The parameter `startDate` of this provider.
  DateTime get startDate;

  /// The parameter `endDate` of this provider.
  DateTime get endDate;
}

class _MonthlyTimelineProviderElement
    extends AutoDisposeStreamNotifierProviderElement<MonthlyTimeline,
        Map<String, List<TimelineReservation>>> with MonthlyTimelineRef {
  _MonthlyTimelineProviderElement(super.provider);

  @override
  DateTime get startDate => (origin as MonthlyTimelineProvider).startDate;
  @override
  DateTime get endDate => (origin as MonthlyTimelineProvider).endDate;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
