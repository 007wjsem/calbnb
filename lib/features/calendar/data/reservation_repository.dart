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

