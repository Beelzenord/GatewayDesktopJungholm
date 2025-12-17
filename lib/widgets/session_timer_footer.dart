import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/session_service.dart';
import '../models/session.dart';

class SessionTimerFooter extends StatefulWidget {
  final GlobalKey<NavigatorState>? navigatorKey;
  
  const SessionTimerFooter({super.key, this.navigatorKey});

  @override
  State<SessionTimerFooter> createState() => _SessionTimerFooterState();
}

class _SessionTimerFooterState extends State<SessionTimerFooter> {
  final SessionService _sessionService = SessionService();
  Session? _activeSession;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadActiveSession();
    // Refresh every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeSession != null) {
        _updateElapsedTime();
      } else {
        _loadActiveSession();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveSession() async {
    if (!mounted) return;
    
    try {
      final session = await _sessionService.getActiveSession();
      if (mounted) {
        setState(() {
          _activeSession = session;
          if (session != null) {
            _updateElapsedTime();
          } else {
            _elapsedTime = Duration.zero;
          }
        });
      }
    } catch (e) {
      // If error occurs, reset state
      if (mounted) {
        setState(() {
          _activeSession = null;
          _elapsedTime = Duration.zero;
        });
      }
    }
  }

  void _updateElapsedTime() {
    if (_activeSession != null) {
      final now = DateTime.now();
      final elapsed = now.difference(_activeSession!.startTime);
      if (mounted) {
        setState(() {
          _elapsedTime = elapsed;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _endSession() async {
    if (_activeSession == null || !mounted) return;

    // Use NavigatorState directly from the GlobalKey
    final navigator = widget.navigatorKey?.currentState;
    if (navigator == null || !mounted) return;

    // Build a context from the navigator's overlay
    final overlay = navigator.overlay;
    if (overlay == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: overlay.context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: const Text('End Session'),
        content: const Text('Are you sure you want to end this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(true),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final sessionId = _activeSession!.id;
    
    try {
      await _sessionService.endSession(sessionId);
      if (mounted) {
        // Reset state immediately
        setState(() {
          _activeSession = null;
          _elapsedTime = Duration.zero;
        });
        
        // Show success message - use overlay context or find ScaffoldMessenger
        final messengerContext = widget.navigatorKey?.currentState?.overlay?.context ?? context;
        if (mounted) {
          ScaffoldMessenger.of(messengerContext).showSnackBar(
            const SnackBar(
              content: Text('Session ended successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Reload to ensure state is synced
        if (mounted) {
          await _loadActiveSession();
        }
      }
    } catch (e) {
      if (mounted) {
        final messengerContext = widget.navigatorKey?.currentState?.overlay?.context ?? context;
        ScaffoldMessenger.of(messengerContext).showSnackBar(
          SnackBar(
            content: Text('Failed to end session: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Still try to reload in case session was ended elsewhere
        await _loadActiveSession();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_activeSession == null) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.green[700],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const SizedBox(width: 16),
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Timer and info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Session',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Started: ${DateFormat('HH:mm').format(_activeSession!.startTime)} • Duration: ${_formatDuration(_elapsedTime)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // End session button
            TextButton.icon(
              onPressed: _endSession,
              icon: const Icon(Icons.stop, color: Colors.white, size: 18),
              label: const Text(
                'End',
                style: TextStyle(color: Colors.white),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

