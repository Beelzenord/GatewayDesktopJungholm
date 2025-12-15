import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:window_manager/window_manager.dart';
import '../services/session_service.dart';
import '../services/bookings_service.dart';
import '../models/booking.dart';
import '../models/session.dart';

class SessionActivationScreen extends StatefulWidget {
  final String productId;
  final String? productName;

  const SessionActivationScreen({
    super.key,
    required this.productId,
    this.productName,
  });

  @override
  State<SessionActivationScreen> createState() =>
      _SessionActivationScreenState();
}

class _SessionActivationScreenState extends State<SessionActivationScreen> {
  final SessionService _sessionService = SessionService();
  final BookingsService _bookingsService = BookingsService();

  bool _isLoading = false;
  Session? _activeSession;
  List<Booking> _userBookings = [];
  SessionActivationResult? _spontaneousCheck;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check for active session
      final activeSession =
          await _sessionService.getActiveSession(productId: widget.productId);
      
      // Load user bookings for today and tomorrow
      final now = DateTime.now();
      final bookings = await _bookingsService.getUserBookings(
        startDate: now.subtract(const Duration(hours: 1)),
        endDate: now.add(const Duration(days: 1)),
      );

      // Filter bookings for this product
      final productBookings = bookings
          .where((b) =>
              b.productId == widget.productId &&
              b.status != 'cancelled' &&
              b.status != 'completed')
          .toList();

      // Check spontaneous session availability
      final spontaneousCheck = await _sessionService.checkSpontaneousSession(
        productId: widget.productId,
        startTime: now,
      );

      setState(() {
        _activeSession = activeSession;
        _userBookings = productBookings;
        _spontaneousCheck = spontaneousCheck;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _activateSpontaneousSession() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _sessionService.activateSpontaneousSession(
        productId: widget.productId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spontaneous session activated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
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

  Future<void> _activateBookedSession(String bookingId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _sessionService.activateBookedSession(bookingId: bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booked session activated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
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

  Future<void> _endSession() async {
    if (_activeSession == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: const Text('Are you sure you want to end this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _sessionService.endSession(_activeSession!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session ended successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end session: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productName ?? 'Lab Instrument'),
        actions: [
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Active Session Card
                  if (_activeSession != null)
                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.play_circle_filled,
                                    color: Colors.green[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Active Session',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Started: ${DateFormat('yyyy-MM-dd HH:mm').format(_activeSession!.startTime)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _endSession,
                              icon: const Icon(Icons.stop),
                              label: const Text('End Session'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (_activeSession == null) ...[
                    const SizedBox(height: 24),
                    // Spontaneous Session Section
                    Text(
                      'Spontaneous Session',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_spontaneousCheck?.canActivate == true) ...[
                              Row(
                                children: [
                                  Icon(Icons.check_circle,
                                    color: Colors.green[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Available for spontaneous session',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_spontaneousCheck?.availableWindow != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Available window: ${_spontaneousCheck!.availableWindow!.inHours}h ${_spontaneousCheck!.availableWindow!.inMinutes % 60}m',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _activateSpontaneousSession,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Activate Spontaneous Session'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Icon(Icons.cancel, color: Colors.red[700]),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _spontaneousCheck?.reason ??
                                          'Not available',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.red[700],
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Booked Sessions Section
                    Text(
                      'Your Bookings',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    if (_userBookings.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No bookings available for activation',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ..._userBookings.map((booking) {
                        return FutureBuilder<SessionActivationResult>(
                          future: _sessionService.checkBookedSession(
                            bookingId: booking.id,
                          ),
                          builder: (context, snapshot) {
                            final canActivate =
                                snapshot.data?.canActivate ?? false;
                            final reason = snapshot.data?.reason;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: canActivate
                                      ? Colors.green
                                      : Colors.grey,
                                  child: const Icon(Icons.event, color: Colors.white),
                                ),
                                title: Text(
                                  '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('EEEE, MMMM d').format(booking.startTime),
                                    ),
                                    if (reason != null && !canActivate) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        reason,
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: ElevatedButton.icon(
                                  onPressed: canActivate
                                      ? () => _activateBookedSession(booking.id)
                                      : null,
                                  icon: const Icon(Icons.play_arrow, size: 18),
                                  label: const Text('Activate'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                  ],
                ],
              ),
            ),
    );
  }
}

