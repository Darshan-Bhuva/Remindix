import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:things_reminder/home.dart';
import 'package:things_reminder/services/geofence_service.dart';
import 'package:workmanager/workmanager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await GeofenceHandler.initNotifications();
  await GeofenceHandler.initForegroundTask();

  await requestIgnoreBatteryOptimization();

  registerBackgroundTask(); // ✅ Register WorkManager Task
  await requestNotificationPermission(); // ✅ Request Notification Permission

  // Fetch locations from Firebase
  QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('locations').get();
  List<Map<String, dynamic>> locations = snapshot.docs
      .map((doc) => doc.data() as Map<String, dynamic>)
      .toList();

  GeofenceHandler.startGeofencing(locations); // Start geofencing

  runApp(MyApp());
}

// ✅ Initialize Notifications
Future<void> requestNotificationPermission() async {
  var status = await Permission.notification.status;
  if (!status.isGranted) {
    await Permission.notification.request();
  }
}

// ✅ WorkManager Callback Function (with Firebase & Error Handling)
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      print("⚡ Restarting Foreground Service...");

      // ✅ Ensure Firebase is initialized before calling anything
      await Firebase.initializeApp();

      // ✅ Check if foreground service is already running
      bool isRunning = await FlutterForegroundTask.isRunningService;
      if (!isRunning) {
        print("🚀 Starting Foreground Service...");
        await GeofenceHandler.startForegroundService();
      } else {
        print("✅ Foreground Service is already running.");
      }

      return Future.value(true);
    } catch (e, stackTrace) {
      print("❌ Error in WorkManager Task: $e");
      print(stackTrace);
      return Future.value(false);
    }
  });
}

// ✅ Properly Initialize WorkManager & Set Constraints
void registerBackgroundTask() {
  Workmanager().initialize(callbackDispatcher);

  Workmanager().registerPeriodicTask(
    "geofence_task",
    "Start Geofence Service",
    frequency: Duration(seconds: 2), // ✅ Run every 15 minutes
    constraints: Constraints(
      networkType: NetworkType.not_required, // ✅ No network needed
      requiresBatteryNotLow: false, // ✅ Run even on low battery
      requiresCharging: false, // ✅ Run without charging
    ),
  );
}

// ✅ Request Battery Optimization Exception
Future<void> requestIgnoreBatteryOptimization() async {
  if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}