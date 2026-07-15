import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Initialize Speech to Text and Text to Speech
  final SpeechToText speech = SpeechToText();
  final FlutterTts tts = FlutterTts();
  bool speechInitialized = false;

  try {
    speechInitialized = await speech.initialize(
      onError: (val) => debugPrint('Background Speech Error: $val'),
      onStatus: (val) => debugPrint('Background Speech Status: $val'),
    );
  } catch (e) {
    debugPrint("Failed to initialize background SpeechToText: $e");
  }

  final List<String> emergencyPhrases = [
    'help',
    'help me',
    'sos',
    'somebody help',
    'call the police',
    'बचाओ',
    'मदद',
    'हेल्प',
    'पुलिस',
    'मुझे बचाओ',
    'bachao',
    'madad',
    'mujhe bachao'
  ];

  final List<String> cancelPhrases = [
    'cancel',
    'safe',
    'cancel sos',
    'stop',
    'मार्क सेफ'
  ];

  String? customVoicePhrase;

  void onVoiceResult(String words) async {
    if (isCountingDown) {
      for (final p in cancelPhrases) {
        if (words.toLowerCase().contains(p)) {
          service.invoke('cancelSOS');
          await tts.speak("SOS cancelled. You are marked as safe.");
          break;
        }
      }
      return;
    }

    final matchPhrases = List<String>.from(emergencyPhrases);
    if (customVoicePhrase != null && customVoicePhrase!.trim().isNotEmpty) {
      matchPhrases.add(customVoicePhrase!.trim().toLowerCase());
    }

    for (final phrase in matchPhrases) {
      if (words.toLowerCase().contains(phrase)) {
        isCountingDown = true;
        countdown = 10;

        await speech.stop();
        await tts.speak("Emergency phrase detected. Sending SOS in 10 seconds.");

        countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
          if (countdown > 0) {
            final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
              'emergency_critical_channel',
              'Emergency Alerts',
              channelDescription: 'Emergency SOS countdown alerts with audio sirens',
              importance: Importance.max,
              priority: Priority.high,
              ticker: 'ticker',
              playSound: true,
              onlyAlertOnce: true,
              sound: const UriAndroidNotificationSound('content://settings/system/alarm_alert'),
              vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
              actions: const [
                AndroidNotificationAction('cancel_sos', 'I AM SAFE - CANCEL'),
              ],
              ongoing: true,
            );
            final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
            
            await flutterLocalNotificationsPlugin.show(
              id: 888,
              title: 'Emergency Phrase Detected!',
              body: 'Are you okay? Automatic SOS in $countdown seconds.',
              notificationDetails: platformChannelSpecifics,
              payload: 'cancel_sos',
            );

            if (!speech.isListening) {
              await speech.listen(
                onResult: (res) => onVoiceResult(res.recognizedWords),
                listenFor: const Duration(seconds: 5),
                pauseFor: const Duration(seconds: 2),
                partialResults: true,
              );
            }

            countdown--;
          } else {
            timer.cancel();
            isCountingDown = false;
            await speech.stop();
            await flutterLocalNotificationsPlugin.cancel(id: 888);
            await triggerSosBackground(
              flutterLocalNotificationsPlugin,
              type: 'voice',
              incidentType: 'Voice Activation',
            );
          }
        });
        break;
      }
    }
  }

  Timer.periodic(const Duration(seconds: 4), (timer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      customVoicePhrase = prefs.getString('custom_voice_sos_phrase');
    } catch (_) {}

    if (speechInitialized && !isCountingDown && !speech.isListening) {
      try {
        await speech.listen(
          onResult: (res) => onVoiceResult(res.recognizedWords),
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 10),
          partialResults: true,
        );
      } catch (e) {
        debugPrint("Error restarting background speech listen: $e");
      }
    }
  });

  service.on('cancelSOS').listen((event) async {
    isCountingDown = false;
    countdownTimer?.cancel();
    try {
      await speech.stop();
    } catch (_) {}
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
            'emergency_critical_channel',
            'Emergency Alerts',
            channelDescription: 'Emergency SOS countdown alerts with audio sirens',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            playSound: true,
            onlyAlertOnce: true,
            sound: UriAndroidNotificationSound('content://settings/system/alarm_alert'),
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

Future<void> triggerSosBackground(FlutterLocalNotificationsPlugin notificationsPlugin, {String type = 'automatic_sensor', String incidentType = 'Vehicle Collision'}) async {
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
      'incident_type': incidentType,
      'severity': 'Critical',
      'detection_type': type,
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
    'emergency_critical_channel',
    'Emergency Alerts',
    description: 'Emergency SOS countdown alerts with audio sirens',
    importance: Importance.max,
    playSound: true,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'emergency_critical_channel',
      initialNotificationTitle: 'ResQLink Active',
      initialNotificationContent: 'Monitoring for sudden impacts',
      foregroundServiceNotificationId: 888,
      foregroundServiceTypes: [AndroidForegroundType.location, AndroidForegroundType.microphone],
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
