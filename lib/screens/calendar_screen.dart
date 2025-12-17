import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';
import '../services/bookings_service.dart';
import '../services/session_service.dart';
import '../services/auth_service.dart';
import '../models/booking.dart';
import '../models/session.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final BookingsService _bookingsService = BookingsService();
  final SessionService _sessionService = SessionService();
  
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Booking>> _bookings = {};
  List<Booking> _selectedBookings = [];
  bool _isLoading = false;
  Map<String, SessionActivationResult> _activationChecks = {};
  Session? _activeSession;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    try {
      final session = await _sessionService.getActiveSession();
      setState(() {
        _activeSession = session;
      });
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DateTime startDate;
      DateTime endDate;

      if (_calendarFormat == CalendarFormat.month) {
        // Load bookings for the entire month
        startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
        final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
        endDate = nextMonth.subtract(const Duration(days: 1));
      } else {
        // Load bookings for the week
        final weekStart = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
        startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        endDate = startDate.add(const Duration(days: 6));
      }

      final bookings = await _bookingsService.getBookings(
        startDate: startDate,
        endDate: endDate,
      );

      // Group bookings by date (using Swedish local time)
      final Map<DateTime, List<Booking>> groupedBookings = {};
      for (var booking in bookings) {
        // Use local time components (already converted from UTC in Booking model)
        final date = DateTime(
          booking.startTime.year,
          booking.startTime.month,
          booking.startTime.day,
        );
        groupedBookings.putIfAbsent(date, () => []).add(booking);
      }

      // Check activation status for user's bookings only
      final authService = AuthService();
      final user = authService.currentUser;
      if (user != null) {
        final userBookings = bookings.where((b) => b.userId == user.id).toList();
        for (var booking in userBookings) {
          final result = await _sessionService.checkBookedSession(
            bookingId: booking.id,
          );
          _activationChecks[booking.id] = result;
        }
      }

      setState(() {
        _bookings = groupedBookings;
        _selectedBookings = _getBookingsForDay(_selectedDay);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading bookings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Booking> _getBookingsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _bookings[date] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedBookings = _getBookingsForDay(selectedDay);
      });
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
    _loadBookings();
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Instrument Bookings'),
        actions: [
          // View toggle buttons
          ToggleButtons(
            isSelected: [
              _calendarFormat == CalendarFormat.month,
              _calendarFormat == CalendarFormat.week,
            ],
            onPressed: (index) {
              setState(() {
                _calendarFormat = index == 0
                    ? CalendarFormat.month
                    : CalendarFormat.week;
              });
              _loadBookings();
            },
            borderRadius: BorderRadius.circular(8),
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Month'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('Week'),
              ),
            ],
          ),
          const SizedBox(width: 8),
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                await windowManager.close();
              },
              tooltip: 'Close App',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Calendar widget
                TableCalendar<Booking>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  calendarFormat: _calendarFormat,
                  eventLoader: _getBookingsForDay,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(color: Colors.red[400]),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                  ),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: _onFormatChanged,
                  onPageChanged: _onPageChanged,
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return const SizedBox.shrink();
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                // Bookings list for selected day
                Expanded(
                  child: _selectedBookings.isEmpty
                      ? Center(
                          child: Text(
                            'No bookings for ${DateFormat('EEEE, MMMM d, y').format(_selectedDay)}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _selectedBookings.length,
                          itemBuilder: (context, index) {
                            final booking = _selectedBookings[index];
                            final activationResult = _activationChecks[booking.id];
                            final isUserBooking = _isUserBooking(booking);
                            final canActivate = isUserBooking &&
                                activationResult?.canActivate == true &&
                                _activeSession == null;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header row with icon, title, and status
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: _getStatusColor(booking.status),
                                          radius: 24,
                                          child: Icon(
                                            Icons.science,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                booking.productName ?? 'Lab Instrument',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                                                style: TextStyle(
                                                  color: Colors.grey[700],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Chip(
                                          label: Text(
                                            booking.status.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          backgroundColor: _getStatusColor(booking.status),
                                          labelStyle: const TextStyle(color: Colors.white),
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                        ),
                                      ],
                                    ),
                                    // Notes
                                    if (booking.notes != null &&
                                        booking.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        booking.notes!,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    // Activation status
                                    if (isUserBooking && activationResult != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            activationResult.canActivate
                                                ? Icons.check_circle
                                                : Icons.info_outline,
                                            size: 16,
                                            color: activationResult.canActivate
                                                ? Colors.green[700]
                                                : Colors.orange[700],
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              activationResult.canActivate
                                                  ? 'Ready to activate'
                                                  : (activationResult.reason ?? ''),
                                              style: TextStyle(
                                                color: activationResult.canActivate
                                                    ? Colors.green[700]
                                                    : Colors.orange[700],
                                                fontSize: 12,
                                                fontWeight: activationResult.canActivate
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    // Activate button
                                    if (canActivate) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () => _activateBooking(booking.id),
                                          icon: const Icon(Icons.play_arrow, size: 18),
                                          label: const Text('Activate Session'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  bool _isUserBooking(Booking booking) {
    try {
      final authService = AuthService();
      final user = authService.currentUser;
      return user != null && booking.userId == user.id;
    } catch (e) {
      return false;
    }
  }

  Future<void> _activateBooking(String bookingId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _sessionService.activateBookedSession(bookingId: bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session activated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _checkActiveSession();
        await _loadBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to activate session: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

