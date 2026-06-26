import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class IncidentMapRoute extends StatefulWidget {
  final String incidentId;
  const IncidentMapRoute({super.key, required this.incidentId});

  @override
  State<IncidentMapRoute> createState() => _IncidentMapRouteState();
}

class _IncidentMapRouteState extends State<IncidentMapRoute> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _incident;
  bool _loading = true;
  String? _errorMessage;

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchIncidentDetails();
  }

  @override
  void dispose() {
    _unsubscribeFromIncident();
    super.dispose();
  }

  void _subscribeToIncident() {
    _unsubscribeFromIncident();
    _realtimeChannel = _supabase
        .channel('volunteer_incident_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sos_incidents',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.incidentId,
          ),
          callback: (payload) {
            _fetchIncidentDetails(silent: true);
          },
        );
    _realtimeChannel!.subscribe();
  }

  void _unsubscribeFromIncident() {
    if (_realtimeChannel != null) {
      _supabase.removeChannel(_realtimeChannel!);
      _realtimeChannel = null;
    }
  }

  Future<void> _fetchIncidentDetails({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _supabase
          .from('sos_incidents')
          .select('*')
          .eq('id', widget.incidentId)
          .single();

      setState(() {
        _incident = response;
      });

      if (!silent) {
        _subscribeToIncident();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      if (!silent) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _launchGoogleNavigation() async {
    if (_incident == null) return;
    final lat = _incident!['latitude'];
    final lng = _incident!['longitude'];
    
    // Attempt to launch native Google Maps with Navigation
    final Uri url = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    try {
      bool launched = await launchUrl(url);
      if (!launched) {
        // Fallback to Web Google Maps
        final Uri webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      final Uri webUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _resolveIncident() async {
    if (_incident == null) return;
    try {
      await _supabase
          .from('sos_incidents')
          .update({
            'status': 'Resolved',
            'resolved_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', widget.incidentId);

      await _supabase
          .from('volunteers')
          .update({'is_available': 'Available'})
          .eq('id', _incident!['assigned_volunteer_id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Emergency successfully resolved. Good work!"),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.go('/dashboard/volunteer');
      }
    } catch (e) {
      debugPrint("Failed to resolve incident: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = _incident?['incident_type'] as String? ?? 'Emergency Incident';
    final severity = _incident?['severity'] as String? ?? 'Critical';
    final victim = _incident?['victim_name'] as String? ?? 'Victim';

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      appBar: AppBar(
        title: const Text("Live Tracking Map", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
              : Column(
                  children: [
                    // Visual placeholder for Map
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF18181B),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.map_rounded, size: 64, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "Google Maps Integration Ready",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                "Launch external navigation to follow real-time directions to the victim.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Navigation Panel
                    Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                                    type,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  Text(
                                    "Victim Name: $victim (Blood: ${_incident?['blood_group'] ?? 'N/A'})",
                                    style: const TextStyle(color: Color(0xFF71717A), fontSize: 12),
                                  ),
                                  if (_incident?['latitude'] != null && _incident?['longitude'] != null) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.gps_fixed, size: 12, color: Color(0xFF10B981)),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Exact Location: Lat ${_incident!['latitude'].toStringAsFixed(6)}, Lng ${_incident!['longitude'].toStringAsFixed(6)}",
                                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_incident?['accuracy'] != null && double.tryParse(_incident!['accuracy'].toString()) != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.radar, size: 12, color: Colors.amberAccent),
                                            const SizedBox(width: 4),
                                            Text(
                                              "GPS Accuracy: ±${double.parse(_incident!['accuracy'].toString()).toStringAsFixed(1)}m",
                                              style: const TextStyle(color: Colors.amberAccent, fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: severity == 'Critical' ? Colors.redAccent.withValues(alpha: 0.15) : Colors.amberAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  severity,
                                  style: TextStyle(
                                    color: severity == 'Critical' ? Colors.redAccent : Colors.amberAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 32, color: Colors.white10),
                          
                          // Launch Native Google Maps button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _launchGoogleNavigation,
                              icon: const Icon(Icons.navigation, color: Colors.white),
                              label: const Text("Launch Turn-by-Turn Navigation", style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB), // Blue for Google Maps
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Resolve Emergency
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _resolveIncident,
                              icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                              label: const Text("Mark as Resolved", style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981), // Emerald
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
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
