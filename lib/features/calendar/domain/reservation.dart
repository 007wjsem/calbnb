enum ReservationEventType {
  checkIn,
  checkOut,
}

class Reservation {
  final String id;
  final String companyId;
  final String guestName;
  final String propertyName;
  final DateTime date;
  final ReservationEventType type;

  const Reservation({
    required this.id,
    required this.companyId,
    required this.guestName,
    required this.propertyName,
    required this.date,
    required this.type,
  });
}

class TimelineReservation {
  final String id;
  final String guestName;
  final String propertyName;
  final String? propertyId;
  final String companyId;
  final DateTime startDate;
  final DateTime endDate;

  const TimelineReservation({
    required this.id,
    required this.guestName,
    required this.propertyName,
    this.propertyId,
    required this.companyId,
    required this.startDate,
    required this.endDate,
  });
}
