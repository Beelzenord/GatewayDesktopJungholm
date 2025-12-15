class Booking {
  final String id;
  final String userId;
  final String productId;
  final String? productName;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;
  final String status;
  final String? bookingReference;

  Booking({
    required this.id,
    required this.userId,
    required this.productId,
    this.productName,
    required this.startTime,
    required this.endTime,
    this.notes,
    required this.status,
    this.bookingReference,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Handle nested products object from Supabase join
    String? productName;
    if (json['products'] != null) {
      if (json['products'] is Map) {
        productName = json['products']['name'] as String?;
      } else if (json['products'] is List && json['products'].isNotEmpty) {
        productName = json['products'][0]['name'] as String?;
      }
    }

    return Booking(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      productName: productName,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      notes: json['notes'] as String?,
      status: json['status'] as String,
      bookingReference: json['booking_reference'] as String?,
    );
  }

  bool isOnDate(DateTime date) {
    final startDate = DateTime(startTime.year, startTime.month, startTime.day);
    final endDate = DateTime(endTime.year, endTime.month, endTime.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    
    return checkDate.isAtSameMomentAs(startDate) ||
        checkDate.isAtSameMomentAs(endDate) ||
        (checkDate.isAfter(startDate) && checkDate.isBefore(endDate));
  }

  bool overlapsWith(DateTime start, DateTime end) {
    return startTime.isBefore(end) && endTime.isAfter(start);
  }
}

