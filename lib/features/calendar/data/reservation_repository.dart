import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../domain/reservation.dart';
import '../../admin/data/property_repository.dart';

part 'reservation_repository.g.dart';

@riverpod
class DailyReservations extends _$DailyReservations {
  @override
  Stream<List<Reservation>> build(DateTime date) async* {
    final ref = FirebaseDatabase.instance.ref('master_calendar');
    final propRepo = PropertyRepository();

    await for (final event in ref.onValue) {
      try {
        final Object? rawData = event.snapshot.value;
        if (rawData == null) {
          yield [];
          continue;
        }

        // Fetch properties on every broadcast update to ensure we have the most 
        // up-to-date name/address mappings.
        final allProperties = await propRepo.fetchAll();
        final targetDateStr = DateFormat('yyyy-MM-dd').format(date);
        final List<Reservation> matchingReservations = [];

        void processItem(String key, dynamic value) {
          if (value is Map) {
            final guest = value['guest'] as String?;
            final checkout = value['checkOut'] as String?;
            final checkin = value['checkIn'] as String?;
            
            // The 'propertyId' historically stored in master_calendar actually maps to the display order.
            final propertyOrderIdStr = value['propertyId'] as String?;
            
            String resolvedPropertyName = 'Missing Name';
            String resolvedPropertyAddress = 'Missing Address';
            
            if (propertyOrderIdStr != null) {
              final int? targetOrder = int.tryParse(propertyOrderIdStr);
              if (targetOrder != null) {
                // Try to find a property that perfectly matches this order index
                try {
                  final matchedProp = allProperties.firstWhere((p) => p.order == targetOrder);
                  resolvedPropertyName = matchedProp.name;
                  resolvedPropertyAddress = matchedProp.address;
                } catch (_) {
                  // firstWhere throws StateError if no matching element is found
                }
              }
            }

            final displayPropertyString = '$resolvedPropertyName, $resolvedPropertyAddress';

            if (guest != null && guest.isNotEmpty && guest.toLowerCase() != 'available') {
              // Check if the checkout date matches the requested date
              if (checkout != null && checkout.startsWith(targetDateStr)) {
                 matchingReservations.add(
                    Reservation(
                      id: '${key}_out',
                      guestName: guest,
                      propertyName: displayPropertyString,
                      date: date,
                      type: ReservationEventType.checkOut,
                    )
                 );
              }
              
              // Check if the checkin date matches the requested date
              if (checkin != null && checkin.startsWith(targetDateStr)) {
                 matchingReservations.add(
                    Reservation(
                      id: '${key}_in',
                      guestName: guest,
                      propertyName: displayPropertyString,
                      date: date,
                      type: ReservationEventType.checkIn,
                    )
                 );
              }
            }
          }
        }

        // Firebase sometimes returns a List if keys are consecutive integers (like an array)
        if (rawData is List) {
          for (int i = 0; i < rawData.length; i++) {
            if (rawData[i] != null) {
              processItem(i.toString(), rawData[i]);
            }
          }
        } else if (rawData is Map) {
          // Otherwise it returns a standard Map
          rawData.forEach((key, value) {
            processItem(key.toString(), value);
          });
        }

        yield matchingReservations;
      } catch (e) {
        throw 'Error parsing real-time updates: ${e.toString()}';
      }
    }
  }
}


@riverpod
class DateRangeReservations extends _$DateRangeReservations {
  @override
  Stream<Map<DateTime, List<Reservation>>> build(DateTime startDate, DateTime endDate) async* {
    final ref = FirebaseDatabase.instance.ref('master_calendar');
    final propRepo = PropertyRepository();

    await for (final event in ref.onValue) {
      try {
        final Object? rawData = event.snapshot.value;
        if (rawData == null) {
          yield {};
          continue;
        }

        final allProperties = await propRepo.fetchAll();
        final Map<DateTime, List<Reservation>> dateMap = {};
        
        // Pre-calculate date strings for the requested range to avoid formatting inside the loop repeatedly
        final Set<String> targetDateStrs = {};
        for (DateTime d = startDate; d.isBefore(endDate.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
          targetDateStrs.add(DateFormat('yyyy-MM-dd').format(d));
          dateMap[DateTime(d.year, d.month, d.day)] = []; // Initialize empty lists for all dates in range
        }

        void processItem(String key, dynamic value) {
          if (value is Map) {
            final guest = value['guest'] as String?;
            final checkout = value['checkOut'] as String?;
            final checkin = value['checkIn'] as String?;
            final propertyOrderIdStr = value['propertyId'] as String?;
            
            String resolvedPropertyName = 'Missing Name';
            String resolvedPropertyAddress = 'Missing Address';
            
            if (propertyOrderIdStr != null) {
              final int? targetOrder = int.tryParse(propertyOrderIdStr);
              if (targetOrder != null) {
                try {
                  final matchedProp = allProperties.firstWhere((p) => p.order == targetOrder);
                  resolvedPropertyName = matchedProp.name;
                  resolvedPropertyAddress = matchedProp.address;
                } catch (_) {}
              }
            }

            final displayPropertyString = '$resolvedPropertyName, $resolvedPropertyAddress';

            if (guest != null && guest.isNotEmpty && guest.toLowerCase() != 'available') {
              
              // Handle Check-out
              if (checkout != null && checkout.length >= 10) {
                final checkoutPrefix = checkout.substring(0, 10);
                if (targetDateStrs.contains(checkoutPrefix)) {
                  try {
                    final d = DateTime.parse(checkoutPrefix);
                    final mapKey = DateTime(d.year, d.month, d.day);
                    if (dateMap.containsKey(mapKey)) {
                      dateMap[mapKey]!.add(
                        Reservation(
                          id: '${key}_out',
                          guestName: guest,
                          propertyName: displayPropertyString,
                          date: mapKey,
                          type: ReservationEventType.checkOut,
                        )
                      );
                    }
                  } catch (_) {}
                }
              }

              // Handle Check-in
              if (checkin != null && checkin.length >= 10) {
                final checkinPrefix = checkin.substring(0, 10);
                if (targetDateStrs.contains(checkinPrefix)) {
                  try {
                    final d = DateTime.parse(checkinPrefix);
                    final mapKey = DateTime(d.year, d.month, d.day);
                    if (dateMap.containsKey(mapKey)) {
                      dateMap[mapKey]!.add(
                        Reservation(
                          id: '${key}_in',
                          guestName: guest,
                          propertyName: displayPropertyString,
                          date: mapKey,
                          type: ReservationEventType.checkIn,
                        )
                      );
                    }
                  } catch (_) {}
                }
              }
            }
          }
        }

        if (rawData is List) {
          for (int i = 0; i < rawData.length; i++) {
            if (rawData[i] != null) {
              processItem(i.toString(), rawData[i]);
            }
          }
        } else if (rawData is Map) {
          rawData.forEach((key, value) {
            processItem(key.toString(), value);
          });
        }

        yield dateMap;
      } catch (e) {
        throw 'Error parsing real-time updates: ${e.toString()}';
      }
    }
  }
}
