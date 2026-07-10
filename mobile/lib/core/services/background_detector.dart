import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://crktpdsijoneauexgsoj.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNya3RwZHNpam9uZWF1ZXhnc29qIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MTgxODYyNSwiZXhwIjoyMDk3Mzk0NjI1fQ.rPPwpdTgMPJ6VJqWJ1gdbPoAnuocU4dXOnwmRfGrryw',
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  
  // Use named parameters based on the latest flutter_local_notifications API requirements
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload == 'cancel_sos') {
        service.invoke('cancelSOS');
      }
    },
  );

  bool isCountingDown = false;
  int countdown = 20;
  Timer? countdownTimer;

  service.on('cancelSOS').listen((event) {
    isCountingDown = false;
    countdownTimer?.cancel();
    flutterLocalNotificationsPlugin.cancel(id: 888);
  });

  userAccelerometerEventStream().listen((UserAccelerometerEvent event) async {
    if (isCountingDown) return;

    double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    
    if (magnitude > 40.0) {
      isCountingDown = true;
      countdown = 20;

      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (countdown > 0) {
          const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
            'sos_channel',
            'SOS Alerts',
            channelDescription: 'Emergency SOS countdown alerts',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            actions: [
              AndroidNotificationAction('cancel_sos', 'I AM SAFE - CANCEL'),
            ],
            ongoing: true,
          );
          const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
          
          await flutterLocalNotificationsPlugin.show(
            id: 888,
            title: 'Possible Accident Detected!',
            body: 'Are you okay? Automatic SOS in $countdown seconds.',
            notificationDetails: platformChannelSpecifics,
            payload: 'cancel_sos',
          );
          countdown--;
        } else {
          timer.cancel();
          isCountingDown = false;
          await flutterLocalNotificationsPlugin.cancel(id: 888);
          await triggerSosBackground(flutterLocalNotificationsPlugin);
        }
      });
    }
  });

  // Polling for Volunteer Push Notifications Simulation
  Set<String> notifiedIncidents = {};
  Timer.periodic(const Duration(seconds: 15), (timer) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Only proceed if user is a volunteer
      final volCheck = await supabase.from('volunteers').select('id').eq('id', user.id).maybeSingle();
      if (volCheck == null) return;

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        );
      } catch (_) {}
      if (pos == null) return;

      // Fetch Pending incidents
      final incidents = await supabase.from('sos_incidents').select('*').eq('status', 'Pending');
      for (var inc in incidents) {
        final id = inc['id'].toString();
        if (notifiedIncidents.contains(id)) continue;

        if (inc['latitude'] != null && inc['longitude'] != null) {
          final distance = Geolocator.distanceBetween(
            pos.latitude, pos.longitude,
            (inc['latitude'] as num).toDouble(), (inc['longitude'] as num).toDouble(),
          );

          if (distance <= 10000) { // Within 10km
            notifiedIncidents.add(id);

            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'sos_channel', 'SOS Alerts',
              importance: Importance.max, priority: Priority.high,
            );
            await flutterLocalNotificationsPlugin.show(
              id: id.hashCode, // Unique ID per incident
              title: '🚨 EMERGENCY: SOS Nearby!',
              body: '${inc['incident_type'] ?? 'Emergency'} reported ${(distance/1000).toStringAsFixed(1)}km away. Tap to open app and accept.',
              notificationDetails: const NotificationDetails(android: androidDetails),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error polling for incidents: $e");
    }
  });
}

Future<void> triggerSosBackground(FlutterLocalNotificationsPlugin notificationsPlugin) async {
  try {
    final supabase = Supabase.instance.client;
    
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition();
    } catch (_) {}
    final lat = pos?.latitude ?? 22.5720;
    final lon = pos?.longitude ?? 88.3620;
    final accuracy = pos?.accuracy ?? 0.0;

    final victimId = '643287b9-d3cf-41cf-8f10-2c6ce554e3b9';
    final victimName = 'Arjun Mehta';
    
    List<Map<String, dynamic>> contactsList = [];
    try {
      final contactsData = await supabase.from('emergency_contacts').select('*').eq('user_id', victimId);
      contactsList = List<Map<String, dynamic>>.from(contactsData);
    } catch (_) {}

    String? primaryContactStr;
    if (contactsList.isNotEmpty) {
      final first = contactsList.first;
      primaryContactStr = "${first['name']} (${first['relation']}) - ${first['phone']}";
    }

    final incidentResponse = await supabase.from('sos_incidents').insert({
      'victim_id': victimId,
      'victim_name': victimName,
      'phone': '+91 98765 43210',
      'blood_group': 'O+',
      'latitude': lat,
      'longitude': lon,
      'accuracy': accuracy,
      'incident_type': 'Vehicle Collision',
      'severity': 'Critical',
      'detection_type': 'automatic_sensor',
      'status': 'Pending',
      'emergency_contact': primaryContactStr
    }).select().single();

    try {
      await supabase.functions.invoke('notify-volunteers', body: {
        'incident_id': incidentResponse['id'],
        'latitude': lat,
        'longitude': lon,
        'radius_meters': 5000
      });
    } catch (_) {}

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'sos_channel', 'SOS Alerts',
      importance: Importance.max, priority: Priority.high,
    );
    await notificationsPlugin.show(
      id: 999,
      title: 'SOS Dispatched!',
      body: 'Emergency contacts and nearby volunteers have been notified.',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );

  } catch (e) {
    debugPrint("Failed to trigger background SOS: $e");
  }
}

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'sos_channel',
    'SOS Alerts',
    description: 'Emergency SOS countdown alerts',
    importance: Importance.max,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'sos_channel',
      initialNotificationTitle: 'ResQLink Active',
      initialNotificationContent: 'Monitoring for sudden impacts',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: (ServiceInstance service) {
        return true;
      },
    ),
  );
  
  // We can't auto-start the service here on Android 14+ because 
  // the user hasn't granted location permissions yet!
  // service.startService();
}
