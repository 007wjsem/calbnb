import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../domain/reservation.dart';
import '../../admin/data/property_repository.dart';

import '../../auth/data/auth_repository.dart';

part 'reservation_repository.g.dart';

@riverpod
class DailyReservations extends _$DailyReservations {
  @override
  Stream<List<Reservation>> build(DateTime date) async* {
    final activeCompanyId = ref.watch(authControllerProvider)?.activeCompanyId;
    
    final DatabaseReference dbRef = activeCompanyId == null 
        ? FirebaseDatabase.instance.ref()
        : FirebaseDatabase.instance.ref('companies/$activeCompanyId');

    // The new reservation standard uses the `reservations` node scoped per company.
    final ref_calendar = dbRef.child('reservations');
    final propRepo = PropertyRepository(activeCompanyId: activeCompanyId);

    await for (final event in ref_calendar.onValue) {
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
            
            // Under the new standard, `propertyId` should strictly map to the property document ID
            final propertyIdStr = value['propertyId'] as String?;
            
            String resolvedPropertyName = 'Missing Name';
            String resolvedPropertyAddress = 'Missing Address';
            
            if (propertyIdStr != null && propertyIdStr.isNotEmpty) {
              try {
                // Find the property that matches this Firebase ID
                final matchedProp = allProperties.firstWhere((p) => p.id == propertyIdStr);
                resolvedPropertyName = matchedProp.name;
                resolvedPropertyAddress = matchedProp.address;
              } catch (_) {
                // If it doesn't match an ID, optionally check if the integration passed the raw property name
                try {
                  final matchedPropByName = allProperties.firstWhere((p) => p.name == propertyIdStr);
                  resolvedPropertyName = matchedPropByName.name;
                  resolvedPropertyAddress = matchedPropByName.address;
                } catch (_) { }
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

