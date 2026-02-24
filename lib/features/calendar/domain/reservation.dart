enum ReservationEventType {
  checkIn,
  checkOut,
}

class Reservation {
  final String id;
  final String guestName;
  final String propertyName;
  final DateTime date;
  final ReservationEventType type;

  const Reservation({
    required this.id,
    required this.guestName,
    required this.propertyName,
    required this.date,
    required this.type,
  });
}
