import 'package:supabase_flutter/supabase_flutter.dart' hide Session;
import '../models/session.dart';
import 'bookings_service.dart';

class SessionService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final BookingsService _bookingsService = BookingsService();

  // Check if a spontaneous session can be activated
  Future<SessionActivationResult> checkSpontaneousSession({
    required String productId,
    required DateTime startTime,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return SessionActivationResult(
          canActivate: false,
          reason: 'User not authenticated',
        );
      }

      // Check for overlapping bookings
      final endTime = startTime.add(const Duration(hours: 2));
      final bookings = await _bookingsService.getBookings(
        startDate: startTime,
        endDate: endTime,
      );

      // Filter bookings for this product
      final productBookings = bookings
          .where((b) => b.productId == productId && b.status != 'cancelled')
          .toList();

      // Check for overlaps
      for (var booking in productBookings) {
        if (booking.overlapsWith(startTime, endTime)) {
          return SessionActivationResult(
            canActivate: false,
            reason: 'There is a booking during this time slot',
          );
        }
      }

      // Check for active sessions
      final activeSessions = await _getActiveSessions(
        productId: productId,
        startTime: startTime,
        endTime: endTime,
      );

      if (activeSessions.isNotEmpty) {
        return SessionActivationResult(
          canActivate: false,
          reason: 'There is an active session during this time',
        );
      }

      // Find the next booking to determine availability window
      final futureBookings = bookings
          .where((b) =>
              b.productId == productId &&
              b.status != 'cancelled' &&
              b.startTime.isAfter(startTime))
          .toList();

      if (futureBookings.isNotEmpty) {
        futureBookings.sort((a, b) => a.startTime.compareTo(b.startTime));
        final nextBooking = futureBookings.first;
        final availableWindow = nextBooking.startTime.difference(startTime);

        if (availableWindow.inHours < 2) {
          return SessionActivationResult(
            canActivate: false,
            reason:
                'Available window is less than 2 hours (${availableWindow.inHours}h ${availableWindow.inMinutes % 60}m remaining)',
            availableWindow: availableWindow,
          );
        }
      }

      return SessionActivationResult(
        canActivate: true,
        availableWindow: const Duration(hours: 2), // Default 2 hours
      );
    } catch (e) {
      return SessionActivationResult(
        canActivate: false,
        reason: 'Error checking availability: $e',
      );
    }
  }

  // Check if a booked session can be activated
  Future<SessionActivationResult> checkBookedSession({
    required String bookingId,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return SessionActivationResult(
          canActivate: false,
          reason: 'User not authenticated',
        );
      }

      // Get the booking by ID directly (works for any date)
      final booking = await _bookingsService.getBookingById(bookingId);
      
      if (booking == null) {
        return SessionActivationResult(
          canActivate: false,
          reason: 'Booking not found',
        );
      }

      final now = DateTime.now();

      // Check if booking belongs to user
      if (booking.userId != user.id) {
        return SessionActivationResult(
          canActivate: false,
          reason: 'This booking does not belong to you',
        );
      }

      // Check if booking is cancelled
      if (booking.status == 'cancelled') {
        return SessionActivationResult(
          canActivate: false,
          reason: 'This booking has been cancelled',
        );
      }

      // Check if booking is completed
      if (booking.status == 'completed') {
        return SessionActivationResult(
          canActivate: false,
          reason: 'This booking has already been completed',
        );
      }

      // Check if we're within 30 minutes before booking start
      final timeUntilStart = booking.startTime.difference(now);
      if (timeUntilStart.isNegative) {
        // Booking has already started
        if (now.isAfter(booking.endTime)) {
          return SessionActivationResult(
            canActivate: false,
            reason: 'This booking has already ended',
          );
        }
        // Can activate if booking is in progress
      } else if (timeUntilStart.inMinutes > 30) {
        // Only show minutes remaining if less than 2 hours away
        final minutesRemaining = timeUntilStart.inMinutes;
        final hoursRemaining = timeUntilStart.inHours;
        final showMinutesRemaining = hoursRemaining < 2;
        
        final reason = showMinutesRemaining
            ? 'You can only activate this session up to 30 minutes before the booking starts ($minutesRemaining minutes remaining)'
            : 'You can only activate this session up to 30 minutes before the booking starts';
        
        return SessionActivationResult(
          canActivate: false,
          reason: reason,
          booking: booking,
        );
      }

      // Check for overlapping active sessions
      final activeSessions = await _getActiveSessions(
        productId: booking.productId,
        startTime: now,
        endTime: booking.endTime,
      );

      if (activeSessions.isNotEmpty) {
        return SessionActivationResult(
          canActivate: false,
          reason: 'There is an overlapping active session',
          booking: booking,
        );
      }

      return SessionActivationResult(
        canActivate: true,
        booking: booking,
      );
    } catch (e) {
      return SessionActivationResult(
        canActivate: false,
        reason: 'Error checking booking: $e',
      );
    }
  }

  // Activate a spontaneous session
  Future<Session> activateSpontaneousSession({
    required String productId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final now = DateTime.now();
    final result = await checkSpontaneousSession(
      productId: productId,
      startTime: now,
    );

    if (!result.canActivate) {
      throw Exception(result.reason ?? 'Cannot activate session');
    }

    try {
      final response = await _supabase.from('product_consumption').insert({
        'product_id': productId,
        'user_id': user.id,
        'start_time': now.toIso8601String(),
        'status': 'active',
      }).select().single();

      return Session.fromJson(response);
    } catch (e) {
      throw Exception('Failed to activate session: $e');
    }
  }

  // Activate a booked session
  Future<Session> activateBookedSession({
    required String bookingId,
  }) async {
    final result = await checkBookedSession(bookingId: bookingId);

    if (!result.canActivate || result.booking == null) {
      throw Exception(result.reason ?? 'Cannot activate session');
    }

    final booking = result.booking!;
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final now = DateTime.now();
      final response = await _supabase.from('product_consumption').insert({
        'product_id': booking.productId,
        'user_id': user.id,
        'booking_id': bookingId,
        'start_time': now.toIso8601String(),
        'status': 'active',
      }).select().single();

      return Session.fromJson(response);
    } catch (e) {
      throw Exception('Failed to activate session: $e');
    }
  }

  // Get active sessions for a product in a time range
  Future<List<Session>> _getActiveSessions({
    required String productId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      final response = await _supabase
          .from('product_consumption')
          .select()
          .eq('product_id', productId)
          .eq('status', 'active')
          .gte('start_time', startTime.toIso8601String())
          .lte('start_time', endTime.toIso8601String());

      return (response as List)
          .map((item) => Session.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get active session for current user
  Future<Session?> getActiveSession({String? productId}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return null;
      }

      var query = _supabase
          .from('product_consumption')
          .select()
          .eq('user_id', user.id)
          .eq('status', 'active');

      if (productId != null) {
        query = query.eq('product_id', productId);
      }

      final response = await query.maybeSingle();

      if (response == null) {
        return null;
      }

      return Session.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // End a session
  Future<void> endSession(String sessionId) async {
    try {
      final now = DateTime.now();
      final session = await _supabase
          .from('product_consumption')
          .select()
          .eq('id', sessionId)
          .single();

      final startTime = DateTime.parse(session['start_time'] as String);
      final durationSeconds = now.difference(startTime).inSeconds;

      await _supabase.from('product_consumption').update({
        'end_time': now.toIso8601String(),
        'duration_seconds': durationSeconds,
        'status': 'completed',
      }).eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to end session: $e');
    }
  }
}

