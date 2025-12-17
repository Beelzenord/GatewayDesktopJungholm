import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/products_service.dart';
import '../services/bookings_service.dart';
import '../services/session_service.dart';
import '../models/booking.dart';
import '../models/session.dart';
import 'calendar_screen.dart';
import 'session_activation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BookingsService _bookingsService = BookingsService();
  final SessionService _sessionService = SessionService();
  List<Booking> _upcomingBookings = [];
  Map<String, SessionActivationResult> _activationChecks = {};
  Session? _activeSession;
  bool _isLoadingBookings = false;

  @override
  void initState() {
    super.initState();
    _loadUpcomingBookings();
    _checkActiveSession();
  }

  Future<void> _loadUpcomingBookings() async {
    setState(() {
      _isLoadingBookings = true;
    });

    try {
      final now = DateTime.now();
      final bookings = await _bookingsService.getUserBookings(
        startDate: now,
        endDate: now.add(const Duration(days: 7)),
      );

      // Filter confirmed bookings and sort by start time
      final upcoming = bookings
          .where((b) => b.status == 'confirmed')
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

      // Check activation status for each booking
      final checks = <String, SessionActivationResult>{};
      for (var booking in upcoming) {
        final result = await _sessionService.checkBookedSession(
          bookingId: booking.id,
        );
        checks[booking.id] = result;
      }

      setState(() {
        _upcomingBookings = upcoming.take(5).toList(); // Show next 5
        _activationChecks = checks;
        _isLoadingBookings = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBookings = false;
      });
    }
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

  Future<void> _activateBooking(String bookingId) async {
    setState(() {
      _isLoadingBookings = true;
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
        await _loadUpcomingBookings();
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
          _isLoadingBookings = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
            tooltip: 'Sign Out',
          ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue[100],
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? 'User',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User info section
              Text(
                'Account Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        context,
                        'Email',
                        user?.email ?? 'N/A',
                        Icons.email,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        context,
                        'Email Verified',
                        user?.emailConfirmedAt != null ? 'Yes' : 'No',
                        Icons.check_circle,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Active Session Card
              if (_activeSession != null)
                Card(
                  color: Colors.green[50],
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_filled, color: Colors.green[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Active Session',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700],
                                    ),
                              ),
                              Text(
                                'Started: ${DateFormat('HH:mm').format(_activeSession!.startTime)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Upcoming Bookings Section
              Text(
                'Upcoming Bookings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (_isLoadingBookings)
                const Center(child: CircularProgressIndicator())
              else if (_upcomingBookings.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No upcoming bookings',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ..._upcomingBookings.map((booking) {
                  final activationResult = _activationChecks[booking.id];
                  final canActivate = activationResult?.canActivate == true &&
                      _activeSession == null;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Icon(Icons.event, color: Colors.blue[700]),
                      ),
                      title: Text(
                        booking.productName ?? 'Lab Instrument',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            '${DateFormat('EEEE, MMMM d').format(booking.startTime)}',
                          ),
                          Text(
                            '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          if (activationResult != null && !activationResult.canActivate)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                activationResult.reason ?? '',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      trailing: canActivate
                          ? ElevatedButton.icon(
                              onPressed: () => _activateBooking(booking.id),
                              icon: const Icon(Icons.play_arrow, size: 18),
                              label: const Text('Activate'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Actions section
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.calendar_today),
                label: const Text('View Calendar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await _showProductSelector(context);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Activate Session'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await authService.signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProductSelector(BuildContext context) async {
    final productsService = ProductsService();
    
    try {
      final products = await productsService.getActiveProducts();
      
      if (products.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No active lab instruments available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (context.mounted) {
        final selectedProduct = await showDialog<Product>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Select Lab Instrument'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return ListTile(
                    leading: const Icon(Icons.science),
                    title: Text(product.name),
                    subtitle: product.description != null
                        ? Text(product.description!)
                        : null,
                    onTap: () => Navigator.pop(context, product),
                  );
                },
              ),
            ),
          ),
        );

        if (selectedProduct != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SessionActivationScreen(
                productId: selectedProduct.id,
                productName: selectedProduct.name,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

