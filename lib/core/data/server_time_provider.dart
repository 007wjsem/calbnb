import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that listens to the clock offset between the client and the Firebase server.
/// Realtime Database exposes this via the '.info/serverTimeOffset' path.
final serverTimeOffsetProvider = StreamProvider<int>((ref) {
  return FirebaseDatabase.instance.ref('.info/serverTimeOffset').onValue.map((event) {
    return (event.snapshot.value as num?)?.toInt() ?? 0;
  });
});

/// Provides an accurately estimated server time by adding the offset to the local device time.
final currentServerTimeProvider = Provider<DateTime>((ref) {
  final offset = ref.watch(serverTimeOffsetProvider).value ?? 0;
  return DateTime.now().add(Duration(milliseconds: offset));
});

/// Helper extension for easy access in any Provider or Widget with Ref
extension ServerTimeExtension on Ref {
  DateTime get currentServerTime {
    final offset = watch(serverTimeOffsetProvider).value ?? 0;
    return DateTime.now().add(Duration(milliseconds: offset));
  }
}
