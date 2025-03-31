// import 'package:geofence_service/geofence_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class GeofenceHandler {
//   static final _geofenceService = GeofenceService.instance;
//   static final _notificationsPlugin = FlutterLocalNotificationsPlugin();

//   /// Initialize notifications
//   static Future<void> initNotifications() async {
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     final InitializationSettings settings =
//         InitializationSettings(android: androidSettings);
//     await _notificationsPlugin.initialize(settings);
//   }

//   /// Handle geofence status changes
//   static Future<void> _onGeofenceStatusChanged(
//     Geofence geofence,
//     GeofenceRadius geofenceRadius,
//     GeofenceStatus geofenceStatus,
//     Location location,
//   ) async {
//     print('geofence: ${geofence.toJson()}');
//     print('geofenceRadius: ${geofenceRadius.toJson()}');
//     print('geofenceStatus: ${geofenceStatus.toString()}');

//     if (geofenceStatus == GeofenceStatus.EXIT) {
//       print("objectfefwfwefEXITT");
//       await _showExitNotification(geofence.id);
//     }
//   }

//   /// Start geofencing for saved locations
//   static void startGeofencing(List<Map<String, dynamic>> locations) {
//     print("fwefwefwefewfewfewf $locations");
//     locations.forEach((doc) => print("${doc["name"]} fewfwefwefwefefdfgrwwdqwwq ${doc["latitude"]} ${doc["longitude"]}"));

//     List<Geofence> geofences = locations
//         .map((loc) => Geofence(
//               id: loc['name'],
//               latitude: loc['latitude'],
//               longitude: loc['longitude'],
//               radius: [GeofenceRadius(id: 'default', length: 100)], // 10 meters
//             ))
//         .toList();

//     /// Define geofence callbacks
//     _geofenceService.setup(
//       interval: 1000, // Check every 5 seconds
//       accuracy: 100, // Location accuracy in meters
//       loiteringDelayMs: 3000, // Delay before triggering exit event
//     );

//     _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);

//     /// Start geofence monitoring
//     _geofenceService.addGeofenceList(geofences);
//     _geofenceService.start(geofences);

//     print("Geofences registered: ${geofences.length}");
//   }

//   /// Show exit notification when user leaves the location
//   static Future<void> _showExitNotification(String locationName) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'geofence_channel',
//       'Location Reminder',
//       importance: Importance.high,
//       priority: Priority.high,
//     );

//     const NotificationDetails notificationDetails =
//         NotificationDetails(android: androidDetails);
//     await _notificationsPlugin.show(
//       0,
//       'Reminder!',
//       'You are leaving $locationName. Have you taken everything?',
//       notificationDetails,
//     );
//   }
// }

// import 'package:geofence_service/geofence_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';

// class GeofenceHandler {
//   static final _geofenceService = GeofenceService.instance;
//   static final _notificationsPlugin = FlutterLocalNotificationsPlugin();

//   static String? _homeLocation; // Store home location name

//   /// Initialize foreground task
//   static Future<void> initForegroundTask() async {
//     FlutterForegroundTask.init(
//       androidNotificationOptions: AndroidNotificationOptions(
//         channelId: 'geofence_service_channel',
//         channelName: 'Geofence Service',
//         channelDescription:
//             'This notification keeps the geofence service running in the background',
//         channelImportance: NotificationChannelImportance.LOW,
//         priority: NotificationPriority.LOW,
//       ),
//       foregroundTaskOptions: ForegroundTaskOptions(
//         autoRunOnBoot: true, // Restart on device reboot
//         allowWifiLock: true,
//         allowWakeLock: true,
//         eventAction: ForegroundTaskEventAction.repeat(5000),
//       ),
//       iosNotificationOptions: const IOSNotificationOptions(
//         showNotification: false,
//         playSound: false,
//       ),
//     );
//   }

//   /// Start the foreground service
//   static Future<void> startForegroundService() async {
//     await FlutterForegroundTask.startService(
//       notificationTitle: 'Geofence Service Running',
//       notificationText: 'Monitoring your locations in the background',
//       callback: startCallback,
//     );
//   }

//   /// Callback for the foreground service
//   static void startCallback() {
//     FlutterForegroundTask.setTaskHandler(GeofenceTaskHandler());
//   }

//   /// Initialize notifications
//   static Future<void> initNotifications() async {
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     final InitializationSettings settings =
//         InitializationSettings(android: androidSettings);
//     await _notificationsPlugin.initialize(settings);
//   }

//   /// Start geofencing for saved locations
//   static Future<void> startGeofencing(
//       List<Map<String, dynamic>> locations) async {
//     print("Starting geofencing for locations: $locations");

//     List<Geofence> geofences = locations.map((loc) {
//       if (loc['name'].toString().toLowerCase() == "home") {
//         _homeLocation = loc['name']; // Store home location
//       }

//       return Geofence(
//         id: loc['name'],
//         latitude: loc['latitude'],
//         longitude: loc['longitude'],
//         radius: [GeofenceRadius(id: 'default', length: 40)], // 100 meters
//       );
//     }).toList();

//     _geofenceService.setup(
//       interval: 1000,
//       accuracy: 100,
//       loiteringDelayMs: 3000,
//     );

//     _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);

//     _geofenceService.addGeofenceList(geofences);
//     _geofenceService.start(geofences);

//     print("✅ Geofences registered: ${geofences.length}");

//     // Start foreground service after geofencing is set up
//     await startForegroundService();
//   }

//   /// Handle geofence status changes
//   static Future<void> _onGeofenceStatusChanged(
//     Geofence geofence,
//     GeofenceRadius geofenceRadius,
//     GeofenceStatus geofenceStatus,
//     Location location,
//   ) async {
//     print('Geofence triggered: ${geofence.id} - Status: $geofenceStatus');

//     List<Map<String, dynamic>> reminders = await _fetchReminders(geofence.id);

//     if (geofenceStatus == GeofenceStatus.ENTER) {
//       print(geofence.id);
//       if (geofence.id == _homeLocation) {
//         // 4. Reminder when entering home (things to take from home)
//         _showNotification("Arrived Home", _getReminderText(reminders, "Take"));
//       } else {
//         // 1. Reminder when user reaches area (take/give items)
//         _showNotification("Arrived at ${geofence.id}",
//             _getReminderText(reminders, "Take", "Give"));
//       }
//     } else if (geofenceStatus == GeofenceStatus.EXIT) {
//       if (geofence.id == _homeLocation) {
//         // 3. Reminder when exiting home (things to take from home)
//         _showNotification("Leaving Home", _getReminderText(reminders, "Take"));

//         // 5. Reminder when exiting home (not forgetting anything)
//         _showNotification("Reminder", "Did you forget anything?");
//       } else {
//         // 2. Reminder when exiting area
//         _showNotification(
//             "Leaving ${geofence.id}", "Have you completed your task?");
//       }
//     }
//   }

//   /// Fetch reminders from Firestore for a specific location
//   static Future<List<Map<String, dynamic>>> _fetchReminders(
//       String location) async {
//     QuerySnapshot snapshot = await FirebaseFirestore.instance
//         .collection('reminders')
//         .where('location', isEqualTo: location)
//         .get();

//     return snapshot.docs
//         .map((doc) => doc.data() as Map<String, dynamic>)
//         .toList();
//   }

//   /// Generate reminder text based on type
//   static String _getReminderText(
//       List<Map<String, dynamic>> reminders, String type1,
//       [String? type2]) {
//     List<String> items = reminders
//         .where((reminder) =>
//             reminder['type'] == type1 ||
//             (type2 != null && reminder['type'] == type2))
//         .map((reminder) => reminder['itemName'] as String) // Explicit cast
//         .toList();

//     return items.isEmpty
//         ? "No reminders for now."
//         : "Don't forget: ${items.join(", ")}";
//   }

//   /// Show notification
//   static Future<void> _showNotification(String title, String body) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'geofence_channel',
//       'Location Reminder',
//       importance: Importance.high,
//       priority: Priority.high,
//     );

//     const NotificationDetails notificationDetails =
//         NotificationDetails(android: androidDetails);

//     await _notificationsPlugin.show(0, title, body, notificationDetails);
//   }
// }

// class GeofenceTaskHandler extends TaskHandler {
//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter? starter) async {
//     print("Foreground task started");
//   }

//   @override
//   Future<void> onEvent(DateTime timestamp) async {
//     print("Foreground task event");
//     // You can add periodic logic here if needed
//   }

//   @override
//   Future<void> onDestroy(DateTime timestamp) async {
//     print("Foreground task destroyed");
//     await FlutterForegroundTask.restartService();
//   }

//   @override
//   void onRepeatEvent(DateTime timestamp) {
//     // TODO: implement onRepeatEvent
//   }
// }



// SECONDDDDDDDDDDDDDDdd

// import 'package:geofence_service/geofence_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:firebase_core/firebase_core.dart';

// /// Callback for the foreground service
// void startCallback() {
//   print("rhuyhewiudnch ");
//   FlutterForegroundTask.setTaskHandler(GeofenceTaskHandler());
// }

// class GeofenceHandler {
//   static final _geofenceService = GeofenceService.instance;
//   static final _notificationsPlugin = FlutterLocalNotificationsPlugin();

//   static String? _homeLocation; // Store home location name

//   //   /// Initialize foreground task
//   static Future<void> initForegroundTask() async {
//     FlutterForegroundTask.init(
//       androidNotificationOptions: AndroidNotificationOptions(
//         channelId: 'geofence_service_channel',
//         channelName: 'Geofence Service',
//         channelDescription:
//             'This notification keeps the geofence service running in the background',
//         channelImportance: NotificationChannelImportance.LOW,
//         priority: NotificationPriority.LOW,
//       ),
//       foregroundTaskOptions: ForegroundTaskOptions(
//         autoRunOnBoot: true, // Restart on device reboot
//         allowWifiLock: true,
//         allowWakeLock: true,
//         eventAction: ForegroundTaskEventAction.repeat(5000),
//       ),
//       iosNotificationOptions: const IOSNotificationOptions(
//         showNotification: false,
//         playSound: false,
//       ),
//     );
//   }

//   /// Start the foreground service
//   static Future<void> startForegroundService() async {
//     if (await FlutterForegroundTask.isRunningService) {
//       print("Foreground service is already running");
//       return;
//     } else {
//       print("fwefewfwewefewfgthyh");
//     }

//     try {
//       await FlutterForegroundTask.startService(
//         notificationTitle: 'Geofence Service Running',
//         notificationText: 'Monitoring your locations in the background',
//         callback: startCallback, // Reference the top-level function
//       );
//       print("Foreground service started successfully");
//     } catch (e) {
//       print("Error starting foreground service: $e");
//     }
//   }

//   /// Initialize notifications
//   static Future<void> initNotifications() async {
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     final InitializationSettings settings =
//         InitializationSettings(android: androidSettings);
//     await _notificationsPlugin.initialize(settings);
//   }

//   /// Start geofencing for saved locations
//   static Future<void> startGeofencing(
//       List<Map<String, dynamic>> locations) async {
//     print("Starting geofencing for locations: $locations");

//     List<Geofence> geofences = locations.map((loc) {
//       if (loc['name'].toString().toLowerCase() == "home") {
//         _homeLocation = loc['name']; // Store home location
//       }

//       return Geofence(
//         id: loc['name'],
//         latitude: loc['latitude'],
//         longitude: loc['longitude'],
//         radius: [GeofenceRadius(id: 'default', length: 40)], // 100 meters
//       );
//     }).toList();

//     _geofenceService.setup(
//       interval: 1000,
//       accuracy: 100,
//       loiteringDelayMs: 3000,
//     );

//     _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);

//     _geofenceService.addGeofenceList(geofences);
//     _geofenceService.start(geofences);

//     print("✅ Geofences registered: ${geofences.length}");

//     // Start foreground service after geofencing is set up
//     await startForegroundService();
//   }

//   /// Handle geofence status changes
//   static Future<void> _onGeofenceStatusChanged(
//     Geofence geofence,
//     GeofenceRadius geofenceRadius,
//     GeofenceStatus geofenceStatus,
//     Location location,
//   ) async {
//     print('Geofence triggered: ${geofence.id} - Status: $geofenceStatus');

//     List<Map<String, dynamic>> reminders = await _fetchReminders(geofence.id);

//     if (geofenceStatus == GeofenceStatus.ENTER) {
//       print(geofence.id);
//       if (geofence.id == _homeLocation) {
//         // 4. Reminder when entering home (things to take from home)
//         _showNotification("Arrived Home", _getReminderText(reminders, "Take"));
//       } else {
//         // 1. Reminder when user reaches area (take/give items)
//         _showNotification("Arrived at ${geofence.id}",
//             _getReminderText(reminders, "Take", "Give"));
//       }
//     } else if (geofenceStatus == GeofenceStatus.EXIT) {
//       if (geofence.id == _homeLocation) {
//         // 3. Reminder when exiting home (things to take from home)
//         _showNotification("Leaving Home", _getReminderText(reminders, "Take"));

//         // 5. Reminder when exiting home (not forgetting anything)
//         _showNotification("Reminder", "Did you forget anything?");
//       } else {
//         // 2. Reminder when exiting area
//         _showNotification(
//             "Leaving ${geofence.id}", "Have you completed your task?");
//       }
//     }
//   }

//   /// Fetch reminders from Firestore for a specific location
//   static Future<List<Map<String, dynamic>>> _fetchReminders(
//       String location) async {
//     QuerySnapshot snapshot = await FirebaseFirestore.instance
//         .collection('reminders')
//         .where('location', isEqualTo: location)
//         .get();

//     return snapshot.docs
//         .map((doc) => doc.data() as Map<String, dynamic>)
//         .toList();
//   }

//   /// Generate reminder text based on type
//   static String _getReminderText(
//       List<Map<String, dynamic>> reminders, String type1,
//       [String? type2]) {
//     List<String> items = reminders
//         .where((reminder) =>
//             reminder['type'] == type1 ||
//             (type2 != null && reminder['type'] == type2))
//         .map((reminder) => reminder['itemName'] as String) // Explicit cast
//         .toList();

//     return items.isEmpty
//         ? "No reminders for now."
//         : "Don't forget: ${items.join(", ")}";
//   }

//   /// Show notification
//   static Future<void> _showNotification(String title, String body) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'geofence_channel',
//       'Location Reminder',
//       importance: Importance.high,
//       priority: Priority.high,
//     );

//     const NotificationDetails notificationDetails =
//         NotificationDetails(android: androidDetails);

//     await _notificationsPlugin.show(0, title, body, notificationDetails);
//   }
// }

// class GeofenceTaskHandler extends TaskHandler {
//   final _geofenceService = GeofenceService.instance;
//   List<Map<String, dynamic>> _locations = [];
//   String? _homeLocation;

//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter? starter) async {
//     print("Foreground task started at $timestamp");

//     try {
//       await Firebase.initializeApp();
//       QuerySnapshot snapshot =
//           await FirebaseFirestore.instance.collection('locations').get();
//       _locations = snapshot.docs
//           .map((doc) => doc.data() as Map<String, dynamic>)
//           .toList();

//       print("✅ Locations fetched: $_locations");
//     } catch (e, stackTrace) {
//       print("❌ Firestore fetch error: $e");
//       print(stackTrace);
//     }

//     await _startGeofencing();
//   }

//   @override
//   Future<void> onEvent(DateTime timestamp) async {
//     print("Foreground task event at $timestamp");

//     // Check if geofencing is running; if not, restart it
//     if (!_geofenceService.isRunningService) {
//       print("Geofence service is not running, restarting...");
//       await _startGeofencing();
//     }
//   }

//   @override
//   Future<void> onDestroy(DateTime timestamp) async {
//     print("Foreground task destroyed at $timestamp");
//     await _geofenceService.stop();
//     await FlutterForegroundTask.restartService();
//   }

//   @override
//   Future<void> onRepeatEvent(DateTime timestamp) async {
//     print("Foreground task repeat event at $timestamp");

//     // Periodically check if geofencing is running
//     if (!_geofenceService.isRunningService) {
//       print("Geofence service stopped, restarting...");
//       await _startGeofencing();
//     }
//   }

//   Future<void> _startGeofencing() async {
//     if (_locations.isEmpty) {
//       print("No locations to monitor.");
//       return;
//     }
//     print("back geofecnce sgtaredbjhfne");

//     List<Geofence> geofences = _locations.map((loc) {
//       if (loc['name'].toString().toLowerCase() == "home") {
//         _homeLocation = loc['name'];
//       }
//       return Geofence(
//         id: loc['name'],
//         latitude: loc['latitude'],
//         longitude: loc['longitude'],
//         radius: [GeofenceRadius(id: 'default', length: 40)],
//       );
//     }).toList();

//     _geofenceService.setup(
//       interval: 1000,
//       accuracy: 100,
//       loiteringDelayMs: 3000,
//     );

//     _geofenceService.addGeofenceStatusChangeListener(
//         GeofenceHandler._onGeofenceStatusChanged);

//     _geofenceService.addGeofenceList(geofences);
//     if (geofences.isEmpty) {
//       print("⚠️ No geofences available to start.");
//       return;
//     }
//     await _geofenceService.start(geofences);

//     print("✅ Geofences registered in task handler: ${geofences.length}");
//   }
// }


// import 'package:geofence_service/geofence_service.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:firebase_core/firebase_core.dart';

// /// Callback for the foreground service
// void startCallback() {
//   print("rhuyhewiudnch ");
//   FlutterForegroundTask.setTaskHandler(GeofenceTaskHandler());
// }

// class GeofenceHandler {
//   static final _geofenceService = GeofenceService.instance;
//   static final _notificationsPlugin = FlutterLocalNotificationsPlugin();

//   static String? _homeLocation; // Store home location name

//   //   /// Initialize foreground task
//   static Future<void> initForegroundTask() async {
//     FlutterForegroundTask.init(
//       androidNotificationOptions: AndroidNotificationOptions(
//         channelId: 'geofence_service_channel',
//         channelName: 'Geofence Service',
//         channelDescription:
//             'This notification keeps the geofence service running in the background',
//         channelImportance: NotificationChannelImportance.LOW,
//         priority: NotificationPriority.LOW,
//       ),
//       foregroundTaskOptions: ForegroundTaskOptions(
//         autoRunOnBoot: true, // Restart on device reboot
//         allowWifiLock: true,
//         allowWakeLock: true,
//         eventAction: ForegroundTaskEventAction.repeat(5000),
//       ),
//       iosNotificationOptions: const IOSNotificationOptions(
//         showNotification: false,
//         playSound: false,
//       ),
//     );
//   }

//   /// Start the foreground service
//   static Future<void> startForegroundService() async {
//     if (await FlutterForegroundTask.isRunningService) {
//       print("Foreground service is already running");
//       return;
//     } else {
//       print("fwefewfwewefewfgthyh");
//     }

//     try {
//       await FlutterForegroundTask.startService(
//         notificationTitle: 'Geofence Service Running',
//         notificationText: 'Monitoring your locations in the background',
//         callback: startCallback,
//       );
//       print("Foreground service started successfully");
//     } catch (e) {
//       print("Error starting foreground service: $e");
//     }
//   }

//   /// Initialize notifications
//   static Future<void> initNotifications() async {
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     final InitializationSettings settings =
//         InitializationSettings(android: androidSettings);
//     await _notificationsPlugin.initialize(settings);
//   }

//   /// Start geofencing for saved locations
//   static Future<void> startGeofencing(
//       List<Map<String, dynamic>> locations) async {
//     print("Starting geofencing for locations: $locations");

//     List<Geofence> geofences = locations.map((loc) {
//       if (loc['name'].toString().toLowerCase() == "home") {
//         _homeLocation = loc['name']; // Store home location
//       }

//       return Geofence(
//         id: loc['name'],
//         latitude: loc['latitude'],
//         longitude: loc['longitude'],
//         radius: [GeofenceRadius(id: 'default', length: 10)], // 100 meters
//       );
//     }).toList();

//     _geofenceService.setup(
//       interval: 1000,
//       accuracy: 100,
//       loiteringDelayMs: 3000,
//     );

//     _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);

//     _geofenceService.addGeofenceList(geofences);
//     if (geofences.isEmpty) {
//       print("⚠️ No geofences available to start.");
//       return;
//     }
//     await _geofenceService.start(geofences);

//     print("✅ Geofences registered: ${geofences.length}");

//     // Start foreground service after geofencing is set up
//     await startForegroundService();
//   }

//   /// Handle geofence status changes
//   static Future<void> _onGeofenceStatusChanged(
//     Geofence geofence,
//     GeofenceRadius geofenceRadius,
//     GeofenceStatus geofenceStatus,
//     Location location,
//   ) async {
//     print('Geofence triggered: ${geofence.id} - Status: $geofenceStatus');

//     List<Map<String, dynamic>> reminders = await _fetchReminders(geofence.id);

//     if (geofenceStatus == GeofenceStatus.ENTER) {
//       print(geofence.id);
//       if (geofence.id == _homeLocation) {
//         // 4. Reminder when entering home (things to take from home)
//         _showNotification("Arrived Home", _getReminderText(reminders, "Take"));
//       } else {
//         // 1. Reminder when user reaches area (take/give items)
//         _showNotification("Arrived at ${geofence.id}",
//             _getReminderText(reminders, "Take", "Give"));
//       }
//     } else if (geofenceStatus == GeofenceStatus.EXIT) {
//       if (geofence.id == _homeLocation) {
//         // 3. Reminder when exiting home (things to take from home)
//         _showNotification("Leaving Home", _getReminderText(reminders, "Take"));

//         // 5. Reminder when exiting home (not forgetting anything)
//         _showNotification("Reminder", "Did you forget anything?");
//       } else {
//         // 2. Reminder when exiting area
//         _showNotification(
//             "Leaving ${geofence.id}", "Have you completed your task?");
//       }
//     }
//   }

//   /// Fetch reminders from Firestore for a specific location
//   static Future<List<Map<String, dynamic>>> _fetchReminders(
//       String location) async {
//     QuerySnapshot snapshot = await FirebaseFirestore.instance
//         .collection('reminders')
//         .where('location', isEqualTo: location)
//         .get();

//     return snapshot.docs
//         .map((doc) => doc.data() as Map<String, dynamic>)
//         .toList();
//   }

//   /// Generate reminder text based on type
//   static String _getReminderText(
//       List<Map<String, dynamic>> reminders, String type1,
//       [String? type2]) {
//     List<String> items = reminders
//         .where((reminder) =>
//             reminder['type'] == type1 ||
//             (type2 != null && reminder['type'] == type2))
//         .map((reminder) => reminder['itemName'] as String) // Explicit cast
//         .toList();

//     return items.isEmpty
//         ? "No reminders for now."
//         : "Don't forget: ${items.join(", ")}";
//   }

//   /// Show notification
//   static Future<void> _showNotification(String title, String body) async {
//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'geofence_channel',
//       'Location Reminder',
//       importance: Importance.high,
//       priority: Priority.high,
//     );

//     const NotificationDetails notificationDetails =
//         NotificationDetails(android: androidDetails);

//     await _notificationsPlugin.show(0, title, body, notificationDetails);
//   }
// }

// class GeofenceTaskHandler extends TaskHandler {
//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter? starter) async {
//     print("Foreground task started");

//     // Fetch saved geofence locations and restart geofencing
//     List<Map<String, dynamic>> locations = await _fetchSavedLocations();
//     print(locations);
//     await GeofenceHandler.startGeofencing(locations);
//   }

//   @override
//   Future<void> onEvent(DateTime timestamp) async {
//     print("Foreground task event");
//   }

//   @override
// Future<void> onDestroy(DateTime timestamp) async {
//   print("Foreground task destroyed. Restarting...");
//   await FlutterForegroundTask.restartService(); // Ensures it tries to restart
// }

//   @override
//   void onRepeatEvent(DateTime timestamp) {}

//   /// Fetch saved geofence locations from Firestore
  
//   Future<List<Map<String, dynamic>>> _fetchSavedLocations() async {
//     await Firebase.initializeApp();
//     try {
//       QuerySnapshot snapshot =
//         await FirebaseFirestore.instance.collection('locations').get();

//     return snapshot.docs
//         .map((doc) => doc.data() as Map<String, dynamic>)
//         .toList();
//     } catch (e, stackTrace) {
//       print("❌ Firestore fetch error: $e");
//       print(stackTrace);
//       return [];
//     }
    
//   }
// }

import 'package:geofence_service/geofence_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:firebase_core/firebase_core.dart';

/// Callback for the foreground service
void startCallback() {
  print("Foreground Task Started!");
  FlutterForegroundTask.setTaskHandler(GeofenceTaskHandler());
}

class GeofenceHandler {
  static final _geofenceService = GeofenceService.instance;
  static final _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static String? _homeLocation; // Store home location name

  /// 

  static Future<void> stopGeofenceTracking() async {
    _geofenceService.clearGeofenceList(); // Remove all geofences
    await _geofenceService.stop(); // Stop geofence tracking
    print("🛑 Geofence tracking stopped.");
  }
  
  /// Initialize foreground task
  static Future<void> initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'geofence_service_channel',
        channelName: 'Geofence Service',
        channelDescription: 'Keeps geofence service running in the background',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        autoRunOnBoot: true, // Restart on device reboot
        allowWifiLock: true,
        allowWakeLock: true,
        eventAction: ForegroundTaskEventAction.repeat(5000),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
    );
  }

  /// Start the foreground service
  static Future<void> startForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      print("✅ Foreground service is already running");
      return;
    }
    try {
      await FlutterForegroundTask.startService(
        notificationTitle: 'Geofence Service Running',
        notificationText: 'Monitoring locations in the background',
        callback: startCallback,
      );
      print("✅ Foreground service started successfully");
    } catch (e) {
      print("❌ Error starting foreground service: $e");
    }
  }

  /// Initialize notifications
  static Future<void> initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(settings);
  }

  /// Start geofencing for saved locations
  static Future<void> startGeofencing(List<Map<String, dynamic>> locations) async {
    print("🚀 Starting geofencing for locations: $locations");

    List<Geofence> geofences = locations.map((loc) {
      if (loc['name'].toString().toLowerCase() == "home") {
        _homeLocation = loc['name']; // Store home location
      }

      return Geofence(
        id: loc['name'],
        latitude: loc['latitude'],
        longitude: loc['longitude'],
        radius: [GeofenceRadius(id: 'default', length: 50)], // 10 meters
      );
    }).toList();

    _geofenceService.setup(
      interval: 1000,
      accuracy: 100,
      loiteringDelayMs: 3000,
    );

    _geofenceService.addGeofenceStatusChangeListener(_onGeofenceStatusChanged);

    _geofenceService.addGeofenceList(geofences);
    if (geofences.isEmpty) {
      print("⚠️ No geofences available to start.");
      return;
    }
    await _geofenceService.start(geofences);

    print("✅ Geofences registered: ${geofences.length}");

    // Start foreground service after geofencing is set up
    await startForegroundService();
  }

  /// Handle geofence status changes
  static Future<void> _onGeofenceStatusChanged(
    Geofence geofence,
    GeofenceRadius geofenceRadius,
    GeofenceStatus geofenceStatus,
    Location location,
  ) async {
    print('📍 Geofence triggered: ${geofence.id} - Status: $geofenceStatus');

    List<Map<String, dynamic>> reminders = await _fetchReminders(geofence.id);
    print(reminders);

    if (geofenceStatus == GeofenceStatus.ENTER) {
      String takeItems = _getReminderText(reminders, "Take");
      print("Take items: $takeItems");
      String giveItems = _getReminderText(reminders, "Give");

      if (takeItems.isNotEmpty) {
        _showNotification("Arrived at ${geofence.id}", "You Have to Take $takeItems");
      }
      if (giveItems.isNotEmpty) {
        _showNotification("Arrived at ${geofence.id}", "You Have to Give $giveItems");
      }
    }
    if (geofenceStatus == GeofenceStatus.EXIT) {
      String takeItems = _getReminderText(reminders, "Take");
      String giveItems = _getReminderText(reminders, "Give");

      if (takeItems.isNotEmpty) {
        _showNotification("Exiting from ${geofence.id}", "Did You Take $takeItems?");
      }
      if (giveItems.isNotEmpty) {
        _showNotification("Exiting from ${geofence.id}", "Did You Give $giveItems?");
      }
    }
  }

  /// Fetch reminders from Firestore for a specific location
  static Future<List<Map<String, dynamic>>> _fetchReminders(String location) async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('reminders')
        .where('location', isEqualTo: location)
        .get();

    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  /// Generate reminder text based on type
  static String _getReminderText(List<Map<String, dynamic>> reminders, String type) {
    List<String> items = reminders
        .where((reminder) => reminder['type'] == type)
        .map((reminder) => reminder['itemName'] as String)
        .toList();

    print("📝 Reminder items for type '$type': $items");

    return items.isNotEmpty ? items.join(", ") : "";
  }

  /// Show notification
  static Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'geofence_channel',
      'Location Reminder',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);
      
    int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000); 

  await _notificationsPlugin.show(notificationId, title, body, notificationDetails);
  }

}

class GeofenceTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter? starter) async {
    print("✅ Foreground task started");

    List<Map<String, dynamic>> locations = await _fetchSavedLocations();
    if (locations.isNotEmpty) {
      await GeofenceHandler.startGeofencing(locations);
    }
  }

  @override
  Future<void> onEvent(DateTime timestamp) async {
    print("📌 Foreground task event triggered");
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print("❌ Foreground task destroyed. WorkManager will restart it.");
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  /// Fetch saved geofence locations from Firestore
  Future<List<Map<String, dynamic>>> _fetchSavedLocations() async {
    await Firebase.initializeApp();
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('locations').get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e, stackTrace) {
      print("❌ Firestore fetch error: $e");
      print(stackTrace);
      return [];
    }
  }
}

