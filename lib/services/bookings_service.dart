import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';

class BookingsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch bookings for a date range
  Future<List<Booking>> getBookings({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            id,
            user_id,
            product_id,
            start_time,
            end_time,
            notes,
            status,
            booking_reference,
            products!bookings_instrument_id_fkey (
              name
            )
          ''')
          .gte('start_time', startDate.toIso8601String())
          .lte('end_time', endDate.toIso8601String())
          .order('start_time');

      final List<Booking> bookings = [];
      for (var item in response) {
        try {
          bookings.add(Booking.fromJson(item));
        } catch (e) {
          // Skip invalid bookings
          continue;
        }
      }
      return bookings;
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }

  // Fetch bookings for a specific date
  Future<List<Booking>> getBookingsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getBookings(startDate: startOfDay, endDate: endOfDay);
  }

  // Fetch bookings for current user
  Future<List<Booking>> getUserBookings({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return [];
      }

      final response = await _supabase
          .from('bookings')
          .select('''
            id,
            user_id,
            product_id,
            start_time,
            end_time,
            notes,
            status,
            booking_reference,
            products!bookings_instrument_id_fkey (
              name
            )
          ''')
          .eq('user_id', user.id)
          .gte('start_time', startDate.toIso8601String())
          .lte('end_time', endDate.toIso8601String())
          .order('start_time');

      final List<Booking> bookings = [];
      for (var item in response) {
        try {
          bookings.add(Booking.fromJson(item));
        } catch (e) {
          continue;
        }
      }
      return bookings;
    } catch (e) {
      throw Exception('Failed to fetch user bookings: $e');
    }
  }

  // Fetch a specific booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            id,
            user_id,
            product_id,
            start_time,
            end_time,
            notes,
            status,
            booking_reference,
            products!bookings_instrument_id_fkey (
              name
            )
          ''')
          .eq('id', bookingId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return Booking.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch booking: $e');
    }
  }
}

