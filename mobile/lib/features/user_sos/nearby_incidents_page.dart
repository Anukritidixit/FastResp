import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class NearbyIncidentsPage extends StatefulWidget {
  const NearbyIncidentsPage({super.key});

  @override
  State<NearbyIncidentsPage> createState() => _NearbyIncidentsPageState();
}

class _NearbyIncidentsPageState extends State<NearbyIncidentsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _nearbyIncidents = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchNearbyIncidents();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295; // PI / 180
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a)) * 1000; // Distance in meters (R = 6371km)
  }

  Future<void> _fetchNearbyIncidents() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 1. Get current location
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permission denied.");
        }
      }

      final pos = await Geolocator.getCurrentPosition();

      // 2. Fetch all active incidents
      final response = await _supabase
          .from('sos_incidents')
          .select('*')
          .inFilter('status', ['Pending', 'In Progress', 'Accepted']);

      // 3. Filter by distance (2km radius) and sort
      final List<Map<String, dynamic>> filteredList = [];
      for (var item in response) {
        final double incidentLat = double.parse(item['latitude'].toString());
        final double incidentLon = double.parse(item['longitude'].toString());

        final distance = _calculateDistance(
          pos.latitude,
          pos.longitude,
          incidentLat,
          incidentLon,
        );

        if (distance <= 2000) {
          // Add calculated distance to the incident payload
          item['distance_meters'] = distance;
          filteredList.add(item);
        }
      }

      // Sort by distance (closest first)
      filteredList.sort((a, b) => (a['distance_meters'] as double).compareTo(b['distance_meters'] as double));

      setState(() {
        _nearbyIncidents = filteredList;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0E),
      appBar: AppBar(
        title: const Text("Community Aid Center", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Safety Warning Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.15)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFFEF4444), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "DISCLAIMER & SAFETY NOTICE",
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "You are not a verified emergency responder. Please prioritize your own safety and do not obstruct professional emergency services at the scene.",
                        style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11, height: 1.4), // zinc400
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Incident List view
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                        ),
                      )
                    : _nearbyIncidents.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, color: Color(0xFF3F3F46), size: 48), // zinc700
                                SizedBox(height: 12),
                                Text(
                                  "No active emergencies nearby.",
                                  style: TextStyle(color: Color(0xFF71717A), fontSize: 14), // zinc500
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchNearbyIncidents,
                            color: const Color(0xFF6366F1),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(24),
                              itemCount: _nearbyIncidents.length,
                              itemBuilder: (context, index) {
                                final item = _nearbyIncidents[index];
                                final distance = item['distance_meters'] as double;
                                final type = item['incident_type'] as String? ?? 'General Emergency';
                                final severity = item['severity'] as String? ?? 'Critical';
                                final timeStr = item['created_at'] != null 
                                    ? DateTime.parse(item['created_at'].toString()).toLocal().toString().substring(11, 16)
                                    : '--:--';

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
                                          Text(
                                            type,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: severity == 'Critical' 
                                                  ? Colors.redAccent.withValues(alpha: 0.15)
                                                  : Colors.amberAccent.withValues(alpha: 0.15),
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
                                          )
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on_outlined, color: Color(0xFF6366F1), size: 16),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${distance.toStringAsFixed(0)} meters away",
                                            style: const TextStyle(color: Color(0xFFD4D4D8), fontSize: 13, fontWeight: FontWeight.bold), // zinc300
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.access_time, color: Color(0xFF52525B), size: 14), // zinc600
                                          const SizedBox(width: 4),
                                          Text(
                                            "Reported $timeStr",
                                            style: const TextStyle(color: Color(0xFF71717A), fontSize: 12), // zinc500
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Help Action Button (Mock Community Responder signup)
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text("Alert broadcasted. Stay safe at the scene."),
                                                backgroundColor: Color(0xFF6366F1),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                            foregroundColor: const Color(0xFF6366F1),
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                          ),
                                          child: const Text("OFFER ASSISTANCE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
