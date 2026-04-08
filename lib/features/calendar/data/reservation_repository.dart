import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../domain/reservation.dart';
import '../../admin/domain/property.dart';
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

    // This guarantees the calendar dashboard updates reactively when properties are created/edited/deleted.
    // It also prevents iOS cache staleness from breaking the initial load.
    final allProperties = await ref.watch(propertiesStreamProvider.future);

    await for (final event in ref_calendar.onValue) {
      try {
        final Object? rawData = event.snapshot.value;
        if (rawData == null) {
          yield [];
          continue;
        }
        final targetDateStr = DateFormat('yyyy-MM-dd').format(date);
        final List<Reservation> matchingReservations = [];

        void processItem(String key, dynamic value, String itemCompanyId) {
          if (value is Map) {
            if (!value.containsKey('guest') && !value.containsKey('checkIn') && !value.containsKey('checkOut')) {
              value.forEach((subKey, subValue) {
                if (subValue is Map) {
                  final mutableSubValue = Map<dynamic, dynamic>.from(subValue);
                  mutableSubValue['propertyId'] ??= key;
                  processItem('${key}_$subKey', mutableSubValue, itemCompanyId);
                }
              });
              return;
            }

            final guest = value['guest']?.toString();
            final checkout = value['checkOut']?.toString();
            final checkin = value['checkIn']?.toString();
            
            final propertyIdStr = value['propertyId']?.toString();
            String? resolvedPropertyId;
            String resolvedPropertyName = 'Missing Name';
            String resolvedPropertyAddress = 'Missing Address';
            String resolvedCompanyId = itemCompanyId;
            
            if (propertyIdStr != null && propertyIdStr.isNotEmpty) {
              Property? matchedProp;
              // Priority 1: Match by syncId (Slug) - Global or Company
              final bySyncId = allProperties.where((p) => p.syncId == propertyIdStr).toList();
              if (bySyncId.isNotEmpty) {
                matchedProp = bySyncId.firstWhere((p) => p.companyId == itemCompanyId, orElse: () => bySyncId.first);
              }

              // Priority 2: Try finding within the SAME company by ID or Name
              if (matchedProp == null) {
                final sameCompanyProps = allProperties.where((p) => p.companyId == itemCompanyId).toList();
                matchedProp = sameCompanyProps.where((p) => p.id == propertyIdStr).firstOrNull;
                matchedProp ??= sameCompanyProps.where((p) => p.name == propertyIdStr).firstOrNull;
                
                if (matchedProp == null) {
                  final searchKey = propertyIdStr.toLowerCase().trim();
                  if (searchKey.length > 2) {
                    matchedProp = sameCompanyProps.where((p) {
                      final pName = p.name.toLowerCase().trim();
                      return pName.length > 2 && (pName.contains(searchKey) || searchKey.contains(pName));
                    }).firstOrNull;
                  }
                }
              }

              // Priority 3: Fallback to Global search (ID, Name, or Order)
              if (matchedProp == null) {
                matchedProp = allProperties.where((p) => p.id == propertyIdStr).firstOrNull;
                matchedProp ??= allProperties.where((p) => p.name == propertyIdStr).firstOrNull;
                
                if (matchedProp == null) {
                  final searchKey = propertyIdStr.toLowerCase().trim();
                  if (searchKey.length > 2) {
                    matchedProp = allProperties.where((p) {
                      final pName = p.name.toLowerCase().trim();
                      return pName.length > 2 && (pName.contains(searchKey) || searchKey.contains(pName));
                    }).firstOrNull;
                  }
                }
                
                if (matchedProp == null) {
                  final targetOrder = int.tryParse(propertyIdStr);
                  if (targetOrder != null) {
                    matchedProp = allProperties.where((p) => p.order == targetOrder).firstOrNull;
                  }
                }
              }

              if (matchedProp != null) {
                resolvedPropertyId = matchedProp.id;
                resolvedPropertyName = matchedProp.name;
                resolvedPropertyAddress = matchedProp.address;
                resolvedCompanyId = matchedProp.companyId;
              }
            }

            final displayPropertyString = '$resolvedPropertyName, $resolvedPropertyAddress';

            if (guest != null && guest.isNotEmpty) {
              final guestLower = guest.toLowerCase();
              // Filter out available and blocked dates (e.g., 'Airbnb (Not available)')
              if (!guestLower.contains('available') && !guestLower.contains('not available')) {
                // Check if the checkout date matches the requested date
                if (checkout != null && checkout.startsWith(targetDateStr)) {
                   matchingReservations.add(
                      Reservation(
                        id: '${key}_out',
                        companyId: resolvedCompanyId,
                        guestName: guest,
                        propertyName: displayPropertyString,
                        propertyId: resolvedPropertyId,
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
                        propertyId: resolvedPropertyId,
                        date: date,
                        type: ReservationEventType.checkIn,
                      )
                   );
                }
              }
            }
          }
        }

        void processReservationsData(Object? data, String itemCompanyId) {
          if (data is List) {
            for (int i = 0; i < data.length; i++) {
              if (data[i] != null) processItem(i.toString(), data[i], itemCompanyId);
            }
          } else if (data is Map) {
            data.forEach((key, value) {
              processItem(key.toString(), value, itemCompanyId);
            });
          }
        }

        if (activeCompanyId == null) {
          if (rawData is Map) {
            rawData.forEach((compId, companyData) {
              processReservationsData(companyData, compId.toString());
            });
          } else if (rawData is List) {
             for (int i = 0; i < rawData.length; i++) {
               final companyData = rawData[i];
               if (companyData != null) processReservationsData(companyData, i.toString());
             }
          }
        } else {
          processReservationsData(rawData, activeCompanyId);
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
  Stream<Map<DateTime, List<Reservation>>> build(
      DateTime startDate, DateTime endDate) async* {
    final activeCompanyId = ref.watch(authControllerProvider)?.activeCompanyId;

    final ref_calendar = activeCompanyId == null
        ? FirebaseDatabase.instance.ref('calendar')
        : FirebaseDatabase.instance.ref('calendar/$activeCompanyId');

    final allProperties = await ref.watch(propertiesStreamProvider.future);

    await for (final event in ref_calendar.onValue) {
      try {
        final Object? rawData = event.snapshot.value;
        if (rawData == null) {
          yield {};
          continue;
        }
        final Map<DateTime, List<Reservation>> dateMap = {};

        // Pre-calculate date strings for the requested range
        final Set<String> targetDateStrs = {};
        for (DateTime d = startDate;
            d.isBefore(endDate.add(const Duration(days: 1)));
            d = d.add(const Duration(days: 1))) {
          targetDateStrs.add(DateFormat('yyyy-MM-dd').format(d));
          dateMap[DateTime(d.year, d.month, d.day)] = [];
        }

        void processItem(String key, dynamic value, String itemCompanyId) {
          if (value is Map) {
            if (!value.containsKey('guest') && !value.containsKey('checkIn') && !value.containsKey('checkOut')) {
              value.forEach((subKey, subValue) {
                if (subValue is Map) {
                  final mutableSubValue = Map<dynamic, dynamic>.from(subValue);
                  mutableSubValue['propertyId'] ??= key;
                  processItem('${key}_$subKey', mutableSubValue, itemCompanyId);
                }
              });
              return;
            }

            final guest = value['guest']?.toString();
            final checkout = value['checkOut']?.toString();
            final checkin = value['checkIn']?.toString();
            final propertyIdStr = value['propertyId']?.toString();

            String? resolvedPropertyId;
            String resolvedPropertyName = 'Missing Name';
            String resolvedPropertyAddress = 'Missing Address';
            String resolvedCompanyId = itemCompanyId;

            if (propertyIdStr != null && propertyIdStr.isNotEmpty) {
              Property? matchedProp;
              // Priority 1: Match by syncId (Slug) - Global or Company
              final bySyncId = allProperties.where((p) => p.syncId == propertyIdStr).toList();
              if (bySyncId.isNotEmpty) {
                matchedProp = bySyncId.firstWhere((p) => p.companyId == itemCompanyId, orElse: () => bySyncId.first);
              }

              // Priority 2: Try finding within the SAME company by ID or Name
              if (matchedProp == null) {
                final sameCompanyProps = allProperties.where((p) => p.companyId == itemCompanyId).toList();
                matchedProp = sameCompanyProps.where((p) => p.id == propertyIdStr).firstOrNull;
                matchedProp ??= sameCompanyProps.where((p) => p.name == propertyIdStr).firstOrNull;
                
                if (matchedProp == null) {
                  final searchKey = propertyIdStr.toLowerCase().trim();
                  if (searchKey.length > 2) {
                    matchedProp = sameCompanyProps.where((p) {
                      final pName = p.name.toLowerCase().trim();
                      return pName.length > 2 && (pName.contains(searchKey) || searchKey.contains(pName));
                    }).firstOrNull;
                  }
                }
              }

              // Priority 3: Fallback to Global search (ID, Name, or Order)
              if (matchedProp == null) {
                matchedProp = allProperties.where((p) => p.id == propertyIdStr).firstOrNull;
                matchedProp ??= allProperties.where((p) => p.name == propertyIdStr).firstOrNull;
                if (matchedProp == null) {
                  final searchKey = propertyIdStr.toLowerCase().trim();
                  if (searchKey.length > 2) {
                    matchedProp = allProperties.where((p) {
                      final pName = p.name.toLowerCase().trim();
                      return pName.length > 2 && (pName.contains(searchKey) || searchKey.contains(pName));
                    }).firstOrNull;
                  }
                }
                if (matchedProp == null) {
                  final targetOrder = int.tryParse(propertyIdStr);
                  if (targetOrder != null) {
                    matchedProp = allProperties.where((p) => p.order == targetOrder).firstOrNull;
                  }
                }
              }

              if (matchedProp != null) {
                resolvedPropertyId = matchedProp.id;
                resolvedPropertyName = matchedProp.name;
                resolvedPropertyAddress = matchedProp.address;
                resolvedCompanyId = matchedProp.companyId;
              }
            }

            final displayPropertyString = '$resolvedPropertyName, $resolvedPropertyAddress';

            if (guest != null && guest.isNotEmpty) {
              final guestLower = guest.toLowerCase();
              if (!guestLower.contains('available') && !guestLower.contains('not available')) {
                // Handle Check-out
                if (checkout != null && checkout.length >= 10) {
                  final checkoutPrefix = checkout.substring(0, 10);
                  if (targetDateStrs.contains(checkoutPrefix)) {
                    try {
                      final d = DateTime.parse(checkoutPrefix);
                      final mapKey = DateTime(d.year, d.month, d.day);
                      dateMap[mapKey]?.add(Reservation(
                        id: '${key}_out',
                        companyId: resolvedCompanyId,
                        guestName: guest,
                        propertyName: displayPropertyString,
                        propertyId: resolvedPropertyId,
                        date: mapKey,
                        type: ReservationEventType.checkOut,
                      ));
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
                      dateMap[mapKey]?.add(Reservation(
                        id: '${key}_in',
                        companyId: resolvedCompanyId,
                        guestName: guest,
                        propertyName: displayPropertyString,
                        propertyId: resolvedPropertyId,
                        date: mapKey,
                        type: ReservationEventType.checkIn,
                      ));
                    } catch (_) {}
                  }
                }
              }
            }
          }
        }

        void processReservationsData(Object? data, String itemCompanyId) {
          if (data is List) {
            for (int i = 0; i < data.length; i++) {
              if (data[i] != null) processItem(i.toString(), data[i], itemCompanyId);
            }
          } else if (data is Map) {
            data.forEach((key, value) => processItem(key.toString(), value, itemCompanyId));
          }
        }

        if (activeCompanyId == null) {
          if (rawData is Map) {
            rawData.forEach((compId, companyData) {
              processReservationsData(companyData, compId.toString());
            });
          } else if (rawData is List) {
            for (int i = 0; i < rawData.length; i++) {
              final companyData = rawData[i];
              if (companyData != null) processReservationsData(companyData, i.toString());
            }
          }
        } else {
          processReservationsData(rawData, activeCompanyId);
        }

        yield dateMap;
      } catch (e) {
        throw 'Error parsing date-range reservations: ${e.toString()}';
      }
    }
  }
}

@riverpod
class MonthlyTimeline extends _$MonthlyTimeline {
  @override
  Stream<Map<String, List<TimelineReservation>>> build(
      DateTime startDate, DateTime endDate) async* {
    final activeCompanyId = ref.watch(authControllerProvider)?.activeCompanyId;

    final ref_calendar = activeCompanyId == null
        ? FirebaseDatabase.instance.ref('calendar')
        : FirebaseDatabase.instance.ref('calendar/$activeCompanyId');

    final allProperties = await ref.watch(propertiesStreamProvider.future);

    await for (final event in ref_calendar.onValue) {
      try {
        final Object? rawData = event.snapshot.value;
        if (rawData == null) {
          yield {};
          continue;
        }
        final Map<String, List<TimelineReservation>> propertyMap = {};

        void processItem(String key, dynamic value, String itemCompanyId) {
          if (value is Map) {
            if (!value.containsKey('guest') && !value.containsKey('checkIn') && !value.containsKey('checkOut')) {
              value.forEach((subKey, subValue) {
                if (subValue is Map) {
                  final mutableSubValue = Map<dynamic, dynamic>.from(subValue);
                  mutableSubValue['propertyId'] ??= key;
                  processItem('${key}_$subKey', mutableSubValue, itemCompanyId);
                }
              });
              return;
            }

            final guest = value['guest']?.toString();
            final checkout = value['checkOut']?.toString();
            final checkin = value['checkIn']?.toString();
            final propertyIdStr = value['propertyId']?.toString();

            String resolvedPropertyName = 'Missing Name';
            String resolvedPropertyAddress = 'Missing Address';
            String? resolvedPropertyId;
            String resolvedCompanyId = itemCompanyId;

            if (propertyIdStr != null && propertyIdStr.isNotEmpty) {
              Property? matchedProp;
              // Priority 1: Match by syncId (Slug) - Global or Company
              final bySyncId = allProperties.where((p) => p.syncId == propertyIdStr).toList();
              if (bySyncId.isNotEmpty) {
                matchedProp = bySyncId.firstWhere((p) => p.companyId == itemCompanyId, orElse: () => bySyncId.first);
              }

              // Priority 2: Try finding within the SAME company by ID or Name
              if (matchedProp == null) {
                final sameCompanyProps = allProperties.where((p) => p.companyId == itemCompanyId).toList();
                matchedProp = sameCompanyProps.where((p) => p.id == propertyIdStr).firstOrNull;
                matchedProp ??= sameCompanyProps.where((p) => p.name == propertyIdStr).firstOrNull;
                if (matchedProp == null) {
                  final searchKey = propertyIdStr.toLowerCase().trim();
                  if (searchKey.length > 2) {
                    matchedProp = sameCompanyProps.where((p) {
                      final pName = p.name.toLowerCase().trim();
                      return pName.length > 2 && (pName.contains(searchKey) || searchKey.contains(pName));
                    }).firstOrNull;
                  }
                }
              }

              // Priority 3: Fallback to Global search (ID, Name, or Order)
              if (matchedProp == null) {
                matchedProp = allProperties.where((p) => p.id == propertyIdStr).firstOrNull;
                matchedProp ??= allProperties.where((p) => p.name == propertyIdStr).firstOrNull;
                if (matchedProp == null) {
                  final searchKey = propertyIdStr.toLowerCase().trim();
                  if (searchKey.length > 2) {
                    matchedProp = allProperties.where((p) {
                      final pName = p.name.toLowerCase().trim();
                      return pName.length > 2 && (pName.contains(searchKey) || searchKey.contains(pName));
                    }).firstOrNull;
                  }
                }
                if (matchedProp == null) {
                  final targetOrder = int.tryParse(propertyIdStr);
                  if (targetOrder != null) {
                    matchedProp = allProperties.where((p) => p.order == targetOrder).firstOrNull;
                  }
                }
              }

              if (matchedProp != null) {
                resolvedPropertyName = matchedProp.name;
                resolvedPropertyAddress = matchedProp.address;
                resolvedPropertyId = matchedProp.id;
                resolvedCompanyId = matchedProp.companyId;
              }
            }

            final displayPropertyString = '$resolvedPropertyName, $resolvedPropertyAddress';

            if (guest != null && guest.isNotEmpty) {
              final guestLower = guest.toLowerCase();
              if (!guestLower.contains('available') && !guestLower.contains('not available')) {
                if (checkin != null && checkout != null) {
                  try {
                    final start = DateTime.parse(checkin.substring(0, 10));
                    final end = DateTime.parse(checkout.substring(0, 10));

                    // Only include if it overlaps with our requested range
                    if (start.isBefore(endDate) && end.isAfter(startDate)) {
                      final reservation = TimelineReservation(
                        id: key,
                        guestName: guest,
                        propertyName: displayPropertyString,
                        propertyId: resolvedPropertyId,
                        companyId: resolvedCompanyId,
                        startDate: start,
                        endDate: end,
                      );
                      propertyMap.putIfAbsent(displayPropertyString, () => []).add(reservation);
                    }
                  } catch (_) {}
                }
              }
            }
          }
        }

        void processReservationsData(Object? data, String itemCompanyId) {
          if (data is List) {
            for (int i = 0; i < data.length; i++) {
              if (data[i] != null) processItem(i.toString(), data[i], itemCompanyId);
            }
          } else if (data is Map) {
            data.forEach((key, value) => processItem(key.toString(), value, itemCompanyId));
          }
        }

        if (activeCompanyId == null) {
          if (rawData is Map) {
            rawData.forEach((compId, companyData) {
              processReservationsData(companyData, compId.toString());
            });
          } else if (rawData is List) {
            for (int i = 0; i < rawData.length; i++) {
              final companyData = rawData[i];
              if (companyData != null) processReservationsData(companyData, i.toString());
            }
          }
        } else {
          processReservationsData(rawData, activeCompanyId);
        }

        yield propertyMap;
      } catch (e) {
        throw 'Error parsing timeline: ${e.toString()}';
      }
    }
  }
}
