import 'booking.dart' show Booking;

class Session {
  final String id;
  final String productId;
  final String userId;
  final String? bookingId;
  final DateTime startTime;
  final DateTime? endTime;
  final int? durationSeconds;
  final String status;

  Session({
    required this.id,
    required this.productId,
    required this.userId,
    this.bookingId,
    required this.startTime,
    this.endTime,
    this.durationSeconds,
    required this.status,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      userId: json['user_id'] as String,
      bookingId: json['booking_id'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      durationSeconds: json['duration_seconds'] as int?,
      status: json['status'] as String,
    );
  }
}

class SessionActivationResult {
  final bool canActivate;
  final String? reason;
  final Booking? booking; // For booked sessions
  final Duration? availableWindow; // For spontaneous sessions

  SessionActivationResult({
    required this.canActivate,
    this.reason,
    this.booking,
    this.availableWindow,
  });
}

