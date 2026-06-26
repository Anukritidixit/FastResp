import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../auth/user_session.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final _supabase = Supabase.instance.client;
  
  // Active User session data
  Map<String, dynamic>? _userSession;

  // Active SOS Incident state
  Map<String, dynamic>? _activeIncident;
  RealtimeChannel? _realtimeChannel;

  bool _triggering = false;
  bool _simulatingAccident = false;
  int _countdownSeconds = 15;
  Timer? _accidentTimer;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserSession();

    // Pulse animation for SOS button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _accidentTimer?.cancel();
    _unsubscribeFromIncident();
    super.dispose();
  }

  void _loadUserSession() {
    if (UserSession.current != null && UserSession.current!['role'] == 'User') {
      setState(() {
        _userSession = UserSession.current;
      });
      _checkActiveIncident();
    } else {
      final sessionStr = localStorageGetSession();
      if (sessionStr != null) {
        UserSession.current = sessionStr;
        setState(() {
          _userSession = sessionStr;
        });
        _checkActiveIncident();
      }
    }
  }

  // Helper simulating localStorage locally in flutter since we bypass Supabase Auth
  Map<String, dynamic>? localStorageGetSession() {
    return {
      "id": "643287b9-d3cf-41cf-8f10-2c6ce554e3b9", // Arjun Mehta's real database ID
      "name": "Arjun Mehta",
      "phone": "+91 98765 43210",
      "blood_group": "O+",
      "role": "User"
    };
  }

  Future<void> _checkActiveIncident() async {
    if (_userSession == null) return;
    try {
      final data = await _supabase
          .from('sos_incidents')
          .select('*, assigned_volunteer:volunteers(users(name))')
          .eq('victim_id', _userSession!['id'])
          .inFilter('status', ['Pending', 'In Progress', 'Accepted'])
          .maybeSingle();

      if (data != null) {
        setState(() {
          _activeIncident = data;
        });
        _subscribeToIncident(data['id']);
      }
    } catch (e) {
      debugPrint("Error checking active incident: $e");
    }
  }

  void _subscribeToIncident(String incidentId) {
    _unsubscribeFromIncident();

    _realtimeChannel = _supabase
        .channel('active_sos_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sos_incidents',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: incidentId,
          ),
          callback: (payload) {
            _checkActiveIncident();
          },
        );
    _realtimeChannel!.subscribe();

    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      if (_activeIncident != null && _activeIncident!['id'] != null) {
        _supabase.from('sos_incidents').update({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        }).eq('id', _activeIncident!['id']).catchError((e) {
          debugPrint("Error updating continuous location: $e");
        });
      }
    });
  }

  void _unsubscribeFromIncident() {
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _triggerSos({String type = 'manual'}) async {
    if (_userSession == null || _triggering) return;

    setState(() {
      _triggering = true;
    });

    try {
      final pos = await _getCurrentLocation();
      final lat = pos?.latitude ?? 22.5720;
      final lon = pos?.longitude ?? 88.3620;
      final accuracy = pos?.accuracy ?? 0.0;

      // 1. Fetch user's emergency contacts
      List<Map<String, dynamic>> contactsList = [];
      try {
        final contactsData = await _supabase
            .from('emergency_contacts')
            .select('*')
            .eq('user_id', _userSession!['id']);
        contactsList = List<Map<String, dynamic>>.from(contactsData);
      } catch (ce) {
        debugPrint("Error fetching emergency contacts: $ce");
      }

      String? primaryContactStr;
      if (contactsList.isNotEmpty) {
        final first = contactsList.first;
        primaryContactStr = "${first['name']} (${first['relation']}) - ${first['phone']}";
      }

      // 2. Create new incident (including primary contact info)
      final response = await _supabase
          .from('sos_incidents')
          .insert({
            'victim_id': _userSession!['id'],
            'victim_name': _userSession!['name'],
            'phone': _userSession!['phone'],
            'blood_group': _userSession!['blood_group'],
            'latitude': lat,
            'longitude': lon,
            'accuracy': accuracy,
            'incident_type': 'Medical Emergency',
            'severity': 'Critical',
            'detection_type': type,
            'status': 'Pending',
            'emergency_contact': primaryContactStr
          })
          .select()
          .single();

      setState(() {
        _activeIncident = response;
      });

      _subscribeToIncident(response['id']);

      // 3. Automatically send simulated SMS to all emergency contacts
      for (final contact in contactsList) {
        final cName = contact['name'];
        final cPhone = contact['phone'];
        final cRelation = contact['relation'];
        debugPrint("📱 SMS sent automatically to Emergency Contact [$cName ($cRelation) - $cPhone]: '🚨 EMERGENCY ALERT: SOS triggered by ${_userSession!['name']}. Location: ($lat, $lon). Help is being dispatched!'");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("🚨 SMS sent to contact $cName ($cRelation): $cPhone"),
              backgroundColor: const Color(0xFF6366F1),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }

      // Invoke Deno edge function to notify volunteers in 5km radius
      try {
        await _supabase.functions.invoke('notify-volunteers', body: {
          'incident_id': response['id'],
          'latitude': lat,
          'longitude': lon,
          'radius_meters': 5000
        });
      } catch (e) {
        debugPrint("Failed to invoke notify-volunteers: $e");
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to trigger SOS: $e")),
        );
      }
    } finally {
      setState(() {
        _triggering = false;
        _simulatingAccident = false;
      });
    }
  }

  void _startAccidentSimulation() {
    setState(() {
      _simulatingAccident = true;
      _countdownSeconds = 15;
    });

    _accidentTimer?.cancel();
    _accidentTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 1) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        timer.cancel();
        _triggerSos(type: 'impact');
      }
    });
  }

  void _cancelAccidentSimulation() {
    _accidentTimer?.cancel();
    setState(() {
      _simulatingAccident = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Alert cancelled. You marked yourself as safe."),
        backgroundColor: Color(0xFF10B981), // emerald
      ),
    );
  }

  Future<void> _cancelActiveSos() async {
    if (_activeIncident == null) return;
    try {
      await _supabase
          .from('sos_incidents')
          .update({'status': 'Cancelled'})
          .eq('id', _activeIncident!['id']);

      _unsubscribeFromIncident();
      setState(() {
        _activeIncident = null;
      });
    } catch (e) {
      debugPrint("Error cancelling SOS: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final volunteerData = _activeIncident?['assigned_volunteer'];
    final volunteerUser = volunteerData != null ? volunteerData['users'] : null;
    final volunteerName = volunteerUser != null ? volunteerUser['name'] as String? : null;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      appBar: AppBar(
        title: const Text("ResQLink SOS Panel", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Color(0xFFA1A1AA)),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFA1A1AA)), // zinc400
            onPressed: () => context.go('/login'),
          )
        ],
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: 100,
            left: 50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withValues(alpha: 0.05),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Community Option Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/dashboard/user/nearby'),
                        icon: const Icon(Icons.explore_outlined, size: 18),
                        label: const Text("View Nearby Incidents"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Accident Detection Simulator Controls
                if (!_simulatingAccident && _activeIncident == null)
                  TextButton.icon(
                    onPressed: _startAccidentSimulation,
                    icon: const Icon(Icons.sensors, color: Colors.amberAccent, size: 16),
                    label: const Text(
                      "Simulate Sudden Vehicle Impact",
                      style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),

                const Spacer(),

                // Central Interactive Box
                if (_simulatingAccident) ...[
                  // 15 Second Countdown Confirmation Screen
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          "Possible Accident Detected!",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Automatic SOS trigger will launch in:",
                          style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)), // zinc400
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "$_countdownSeconds s",
                          style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.amberAccent),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _cancelAccidentSimulation,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF10B981)), // emerald
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text("I'M SAFE", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _accidentTimer?.cancel();
                                  _triggerSos(type: 'impact');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text("SEND HELP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ] else if (_activeIncident == null) ...[
                  // Large Glowing Breathing SOS Button
                  GestureDetector(
                    onTap: _triggerSos,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.25 * _pulseController.value),
                                blurRadius: 30 + (20 * _pulseController.value),
                                spreadRadius: 10 + (12 * _pulseController.value),
                              ),
                              BoxShadow(
                                color: const Color(0xFFB91C1C).withValues(alpha: 0.15 * (1.0 - _pulseController.value)),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                            border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
                          ),
                          alignment: Alignment.center,
                          child: Container(
                            margin: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.15),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            alignment: Alignment.center,
                            child: _triggering
                                ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.gpp_maybe, size: 44, color: Colors.white),
                                      SizedBox(height: 8),
                                      Text(
                                        "SEND SOS",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        "TAP TO TRIGGER",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Press once to summon emergency responders",
                    style: TextStyle(color: Color(0xFF52525B), fontSize: 13), // zinc600
                  ),
                ] else ...[
                  // Live Active SOS Tracking Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.01),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.02),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "INCIDENT REF: ${_activeIncident!['id']}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF71717A), fontSize: 10, fontFamily: 'monospace', letterSpacing: 0.5),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Emergency Broadcast Active",
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2), width: 1),
                              ),
                              child: Text(
                                _activeIncident!['status'].toUpperCase(),
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32, color: Colors.white10),
                        
                        // Status Timeline
                        _buildStatusRow("Alert Dispatched to Dispatcher", true),
                        _buildStatusRow("Locating Nearby Responders", _activeIncident!['status'] == 'Pending' || _activeIncident!['status'] == 'In Progress' || _activeIncident!['status'] == 'Accepted'),
                        _buildStatusRow(
                          volunteerName != null ? "Assigned Responder: $volunteerName" : "Waiting for Volunteer Assignment",
                          volunteerName != null,
                        ),
                        _buildStatusRow("Rescue Operations En Route", _activeIncident!['status'] == 'In Progress'),

                        const SizedBox(height: 24),

                        // Cancel Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _cancelActiveSos,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.04),
                            ),
                            child: const Text(
                              "Cancel Alert Request",
                              style: TextStyle(color: Color(0xFFFCA5A5), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],

                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: active ? const Color(0xFF10B981) : const Color(0xFF3F3F46),
            size: 16,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: active ? Colors.white : const Color(0xFF71717A),
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
