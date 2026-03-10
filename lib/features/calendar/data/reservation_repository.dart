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
    
    final ref_calendar = activeCompanyId == null 
        ? FirebaseDatabase.instance.ref('calendar')
        : FirebaseDatabase.instance.ref('calendar/$activeCompanyId');

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
            final guest = value['guest']?.toString();
            final checkout = value['checkOut']?.toString();
            final checkin = value['checkIn']?.toString();
            
            // Extract safely without rigid type casting in case Make.com sends integers
            final propertyIdStr = value['propertyId']?.toString();
            
            String resolvedPropertyName = 'Missing Name';
            String resolvedPropertyAddress = 'Missing Address';
            String resolvedCompanyId = activeCompanyId ?? '';
            
            if (propertyIdStr != null && propertyIdStr.isNotEmpty) {
              try {
                // 1. Try finding by rigid Document ID
                final matchedProp = allProperties.firstWhere((p) => p.id == propertyIdStr);
                resolvedPropertyName = matchedProp.name;
                resolvedPropertyAddress = matchedProp.address;
                resolvedCompanyId = matchedProp.companyId;
              } catch (_) {
                try {
                  // 2. Fallback: Try finding by Property Name
                  final matchedPropByName = allProperties.firstWhere((p) => p.name == propertyIdStr);
                  resolvedPropertyName = matchedPropByName.name;
                  resolvedPropertyAddress = matchedPropByName.address;
                  resolvedCompanyId = matchedPropByName.companyId;
                } catch (_) { 
                  // 3. Fallback: Try finding by Legacy Order index
                  final int? targetOrder = int.tryParse(propertyIdStr);
                  if (targetOrder != null) {
                    try {
                      final matchedPropByOrder = allProperties.firstWhere((p) => p.order == targetOrder);
                      resolvedPropertyName = matchedPropByOrder.name;
                      resolvedPropertyAddress = matchedPropByOrder.address;
                      resolvedCompanyId = matchedPropByOrder.companyId;
                    } catch (_) {}
                  }
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
                      companyId: resolvedCompanyId,
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
                      companyId: resolvedCompanyId,
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

        void processReservationsData(Object? data) {
          if (data is List) {
            for (int i = 0; i < data.length; i++) {
              if (data[i] != null) processItem(i.toString(), data[i]);
            }
          } else if (data is Map) {
            data.forEach((key, value) {
              processItem(key.toString(), value);
            });
          }
        }

        if (activeCompanyId == null) {
          // If Super Admin, rawData is a map of ALL companies under `calendar`.
          if (rawData is Map) {
            for (final companyData in rawData.values) {
              processReservationsData(companyData);
            }
          } else if (rawData is List) {
             for (final companyData in rawData) {
               if (companyData != null) processReservationsData(companyData);
             }
          }
        } else {
          // If Admin, rawData is just the reservations array/map for their specific company.
          processReservationsData(rawData);
        }

        yield matchingReservations;
      } catch (e) {
        throw 'Error parsing real-time updates: ${e.toString()}';
      }
    }
  }
}

