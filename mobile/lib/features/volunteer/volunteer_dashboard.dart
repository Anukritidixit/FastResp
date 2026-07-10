import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../auth/user_session.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  final _supabase = Supabase.instance.client;
  
  // Volunteer simulated session
  Map<String, dynamic>? _volunteerSession;

  bool _isAvailable = false;
  List<Map<String, dynamic>> _activeIncidents = [];
  bool _loadingIncidents = false;
  
  // Background location updates
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionSubscription;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _loadVolunteerSession();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _positionSubscription?.cancel();
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
    }
    super.dispose();
  }

  void _loadVolunteerSession() {
    if (UserSession.current != null && UserSession.current!['role'] == 'Volunteer') {
      setState(() {
        _volunteerSession = UserSession.current;
      });
    } else {
      // Simulated session fetch for Rahul Sharma / Amit Kumar (Volunteer)
      final fallbackSession = {
        "id": "dd71b0ce-94cc-4bab-9810-b19e79aa4273", // Amit Kumar's real User/Volunteer ID
        "name": "Amit Kumar",
        "email": "amit.k@example.com",
        "role": "Volunteer"
      };
      UserSession.current = fallbackSession;
      setState(() {
        _volunteerSession = fallbackSession;
      });
    }
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    if (_volunteerSession == null) return;
    try {
      final data = await _supabase
          .from('volunteers')
          .select('is_available')
          .eq('id', _volunteerSession!['id'])
          .single();

      setState(() {
        _isAvailable = data['is_available'] == 'Available' || data['is_available'] == 'Busy';
      });

      if (_isAvailable) {
        _startLocationTracking();
        _fetchActiveIncidents();
        _subscribeToIncidents();
      }
    } catch (e) {
      debugPrint("Error fetching availability: $e");
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    if (_volunteerSession == null) return;

    setState(() {
      _isAvailable = value;
    });

    try {
      final status = value ? 'Available' : 'Offline';
      await _supabase
          .from('volunteers')
          .update({'is_available': status})
          .eq('id', _volunteerSession!['id']);

      if (value) {
        _startLocationTracking();
        _fetchActiveIncidents();
        _subscribeToIncidents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You are now ONLINE and ready to receive alerts.")),
          );
        }
      } else {
        _stopLocationTracking();
        _unsubscribeFromIncidents();
        setState(() {
          _activeIncidents.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You are now OFFLINE.")),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isAvailable = !value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update status: $e")),
        );
      }
    }
  }

  Future<void> _startLocationTracking() async {
    _stopLocationTracking();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // Get initial position
    final pos = await Geolocator.getCurrentPosition();
    _updateDatabaseLocation(pos);

    // Periodically update database with current position
    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      final currentPos = await Geolocator.getCurrentPosition();
      _updateDatabaseLocation(currentPos);
    });
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _positionSubscription?.cancel();
  }

  Future<void> _updateDatabaseLocation(Position pos) async {
    if (_volunteerSession == null) return;
    try {
      await _supabase
          .from('volunteers')
          .update({
            'latitude': pos.latitude,
            'longitude': pos.longitude,
          })
          .eq('id', _volunteerSession!['id']);
      debugPrint("Updated volunteer location in DB: (${pos.latitude}, ${pos.longitude})");
    } catch (e) {
      debugPrint("Failed to update location: $e");
    }
  }

  Future<void> _fetchActiveIncidents() async {
    if (!_isAvailable) return;
    setState(() {
      _loadingIncidents = true;
    });

    try {
      // Fetch incidents that are Pending (need responder)
      final response = await _supabase
          .from('sos_incidents')
          .select('*')
          .eq('status', 'Pending')
          .order('created_at', ascending: false);

      setState(() {
        _activeIncidents = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetching active incidents: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loadingIncidents = false;
        });
      }
    }
  }

  void _subscribeToIncidents() {
    _unsubscribeFromIncidents();
    _realtimeChannel = _supabase
        .channel('volunteer_dashboard_incidents')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sos_incidents',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'status',
            value: 'Pending',
          ),
          callback: (payload) {
            _fetchActiveIncidents();
          },
        );
    _realtimeChannel!.subscribe();
  }

  void _unsubscribeFromIncidents() {
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  Future<void> _acceptIncident(String incidentId) async {
    if (_volunteerSession == null) return;

    try {
      // Call Deno Edge Function to assign volunteer and update statuses safely
      await _supabase.functions.invoke('assign-volunteer', body: {
        'incident_id': incidentId,
        'volunteer_id': _volunteerSession!['id'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Emergency Accepted! Opening routing navigation..."),
            backgroundColor: Color(0xFF10B981), // emerald
          ),
        );
        // Route to maps viewport
        context.push('/dashboard/volunteer/map', extra: {'incidentId': incidentId});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to accept incident: $e")),
        );
      }
    }
  }

  // Volunteer Self-SOS Trigger (In Case Responder Needs Help)
  Future<void> _triggerSelfSos() async {
    if (_volunteerSession == null) return;

    final shouldTrigger = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Request Emergency Backup?"),
        content: const Text("This will trigger a live SOS alert requesting backup to your current location."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("SEND SOS"),
          ),
        ],
      ),
    );

    if (shouldTrigger ?? false) {
      try {
        final pos = await Geolocator.getCurrentPosition();
        
        final response = await _supabase
            .from('sos_incidents')
            .insert({
              'victim_id': _volunteerSession!['id'],
              'victim_name': "${_volunteerSession!['name']} (Volunteer)",
              'phone': "N/A", // Privacy Guard: masked / not shared
              'blood_group': "O+",
              'latitude': pos.latitude,
              'longitude': pos.longitude,
              'incident_type': 'Backup Request',
              'severity': 'Critical',
              'detection_type': 'manual',
              'status': 'Pending'
            })
            .select()
            .single();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Backup Alert triggered: ${response['id']}"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to trigger SOS: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text("ResQLink Responder Console", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFFA1A1AA)),
            onPressed: () => context.push('/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFA1A1AA)),
            onPressed: () => context.go('/login'),
          )
        ],
      ),
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEF4444).withValues(alpha: 0.02),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Availability Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.02),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Pulsing Online/Offline Dot
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isAvailable ? const Color(0xFF10B981) : const Color(0xFF71717A),
                          boxShadow: _isAvailable
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAvailable ? "Duty Status: ONLINE" : "Duty Status: OFFLINE",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isAvailable ? "Broadcasting live GPS to dispatcher" : "Offline • Incidents hidden",
                            style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Switch(
                        value: _isAvailable,
                        onChanged: _toggleAvailability,
                        activeThumbColor: const Color(0xFF10B981),
                        activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                        inactiveThumbColor: const Color(0xFF71717A),
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // Volunteer Self-SOS Backup Request Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _triggerSelfSos,
                    icon: const Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 18),
                    label: const Text(
                      "REQUEST TACTICAL BACKUP (SOS)",
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5, fontSize: 13, color: Color(0xFFEF4444)),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.06),
                      side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.35), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Incoming Alerts Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Active Dispatch Feed",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isAvailable ? "Realtime updates" : "Alerts will appear here",
                          style: const TextStyle(color: Color(0xFF71717A), fontSize: 11),
                        ),
                      ],
                    ),
                    if (_isAvailable)
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, color: Color(0xFF6366F1), size: 22),
                        onPressed: _fetchActiveIncidents,
                      )
                  ],
                ),
                const SizedBox(height: 16),

                // Alerts list
                Expanded(
                  child: !_isAvailable
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.01),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.radar, color: Colors.white.withValues(alpha: 0.12), size: 48),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Standing By Offline",
                                style: TextStyle(color: Color(0xFF71717A), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Toggle duty status online to scan for emergencies.",
                                style: TextStyle(color: Color(0xFF52525B), fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      : _loadingIncidents
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                          : _activeIncidents.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withValues(alpha: 0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 36),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        "No Active Emergencies Nearby",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        "Everything is clear in your sector.",
                                        style: TextStyle(color: Color(0xFF71717A), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _activeIncidents.length,
                                  itemBuilder: (context, index) {
                                    final alert = _activeIncidents[index];
                                    final id = alert['id'] as String? ?? 'SOS';
                                    final type = alert['incident_type'] as String? ?? 'General Emergency';
                                    final severity = alert['severity'] as String? ?? 'Critical';
                                    final victim = alert['victim_name'] as String? ?? 'Unknown Victim';
                                    final blood = alert['blood_group'] as String? ?? 'N/A';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.02),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(Icons.local_hospital_outlined, color: Color(0xFFEF4444), size: 16),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Text(
                                                    type,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                                  ),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: severity == 'Critical'
                                                      ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                                                      : Colors.amber.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  severity,
                                                  style: TextStyle(
                                                    color: severity == 'Critical' ? const Color(0xFFEF4444) : Colors.amber,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          
                                          // Victim details
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Icon(Icons.person_outline_rounded, color: Color(0xFF71717A), size: 14),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Victim: $victim",
                                                      style: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 12, fontWeight: FontWeight.bold),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.bloodtype_outlined, color: Color(0xFF71717A), size: 14),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Blood Group Needed: $blood",
                                                      style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 16),

                                          // Actions Panel
                                          SizedBox(
                                            width: double.infinity,
                                            height: 46,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _acceptIncident(id),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF6366F1),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                elevation: 0,
                                              ),
                                              icon: const Icon(Icons.navigation_outlined, size: 14, color: Colors.white),
                                              label: const Text(
                                                "ACCEPT DISPATCH",
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
