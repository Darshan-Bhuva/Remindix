// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:location/location.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:things_reminder/add_reminder_page.dart';
// import 'package:things_reminder/select_location_page.dart';

// class HomePage extends StatefulWidget {
//   @override
//   _HomePageState createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   List<Map<String, dynamic>> locations = [];

//   @override
//   void initState() {
//     super.initState();
//     fetchLocations();
//   }

//   Future<void> fetchLocations() async {
//     var snapshot =
//         await FirebaseFirestore.instance.collection('locations').get();
//     setState(() {
//       locations = snapshot.docs.map((doc) => doc.data()).toList();
//     });
//   }

//   /// Get current location using `location` package
//   Future<void> addCurrentLocation(String name) async {
//     Location location = Location();

//     // Check if location services are enabled
//     bool serviceEnabled = await location.serviceEnabled();
//     if (!serviceEnabled) {
//       serviceEnabled =
//           await location.requestService(); // Ask user to enable location
//       if (!serviceEnabled) {
//         print("Location services are still disabled.");
//         return;
//       }
//     }

//     // Check and request location permission
//     PermissionStatus permissionGranted = await location.hasPermission();
//     if (permissionGranted == PermissionStatus.denied) {
//       permissionGranted = await location.requestPermission();
//       if (permissionGranted != PermissionStatus.granted) {
//         print("Location permission denied.");
//         return;
//       }
//     }

//     // Get current location
//     LocationData currentLocation = await location.getLocation();

//     // Check if name already exists
//     var existingLocations = await FirebaseFirestore.instance
//         .collection('locations')
//         .where('name', isEqualTo: name)
//         .get();

//     if (existingLocations.docs.isNotEmpty) {
//       // Show error message if name already exists
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content:
//                 Text("Location name already exists! Choose a different name.")),
//       );
//       return;
//     }

//     await FirebaseFirestore.instance.collection('locations').add({
//       'name': name,
//       'latitude': currentLocation.latitude,
//       'longitude': currentLocation.longitude,
//     });

//     fetchLocations(); // Refresh list
//   }

//   /// Open map to select location
//   Future<void> openLocationPicker() async {
//     LatLng? selectedLocation = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => SelectLocationPage()),
//     );

//     if (selectedLocation != null) {
//       String? locationName =
//           await _showInputDialog(context, "Enter Location Name");
//       if (locationName != null) {
//         await FirebaseFirestore.instance.collection('locations').add({
//           'name': locationName,
//           'latitude': selectedLocation.latitude,
//           'longitude': selectedLocation.longitude,
//         });
//         fetchLocations();
//       }
//     }
//   }

//   /// Navigate to Add Reminder Page
//   void goToAddReminder() {
//     Navigator.push(context,
//         MaterialPageRoute(builder: (context) => AddReminderPage(locations)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Reminder App")),
//       body: Column(
//         children: [
//           ElevatedButton(
//             onPressed: () async {
//               String? locationName =
//                   await _showInputDialog(context, "Enter Location Name");
//               if (locationName != null) addCurrentLocation(locationName);
//             },
//             child: Text("Add Current Location"),
//           ),
//           ElevatedButton(
//             onPressed: openLocationPicker,
//             child: Text("Select Location on Map"),
//           ),
//           ElevatedButton(
//             onPressed: goToAddReminder,
//             child: Text("Add Reminder"),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: locations.length,
//               itemBuilder: (context, index) {
//                 return ListTile(
//                   title: Text(locations[index]['name']),
//                   subtitle: Text(
//                       "Lat: ${locations[index]['latitude']}, Lng: ${locations[index]['longitude']}"),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Show Input Dialog
//   Future<String?> _showInputDialog(BuildContext context, String title) async {
//     TextEditingController controller = TextEditingController();
//     return showDialog<String>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: TextField(controller: controller),
//         actions: [
//           TextButton(
//               onPressed: () => Navigator.pop(context), child: Text("Cancel")),
//           TextButton(
//               onPressed: () => Navigator.pop(context, controller.text),
//               child: Text("OK")),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:things_reminder/add_reminder_page.dart';
import 'package:things_reminder/select_location_page.dart';
import 'package:things_reminder/services/geofence_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> locations = [];
  bool _isLoading = false; // Loader state

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    var locationSnapshot = await FirebaseFirestore.instance
        .collection('locations')
        .orderBy('createdAt', descending: true) // Sort by creation time
        .get();
    var reminderSnapshot =
        await FirebaseFirestore.instance.collection('reminders').get();

    // Convert reminders into a map grouped by location name
    Map<String, List<Map<String, dynamic>>> remindersMap = {};

    for (var doc in reminderSnapshot.docs) {
      var data = doc.data();
      String locationName = data['location']; // Use the name from reminders

      if (!remindersMap.containsKey(locationName)) {
        remindersMap[locationName] = [];
      }
      remindersMap[locationName]!.add(data);
    }

    print("Reminders Map: $remindersMap");

    setState(() {
      locations = locationSnapshot.docs.map((doc) {
        var data = doc.data();
        String locationId = doc.id; // Document ID for deletion
        String locationName = data['name']; // Name for matching reminders

        // Attach relevant reminders to the location using name
        List<Map<String, dynamic>> reminders = remindersMap[locationName] ?? [];

        // Separate "Take" and "Give" items
        List<String> takeItems = reminders
            .where((r) => r['type'] == 'Take')
            .map((r) => r['itemName'] as String)
            .toList();
        List<String> giveItems = reminders
            .where((r) => r['type'] == 'Give')
            .map((r) => r['itemName'] as String)
            .toList();

        return {
          'id': locationId, // For deletion
          'name': locationName,
          'take': takeItems,
          'give': giveItems,
        };
      }).toList();
    });
    setState(() => _isLoading = false); // Show loader
  }

  Future<void> deleteLocation(String docId) async {
    await FirebaseFirestore.instance
        .collection('locations')
        .doc(docId)
        .delete();
    fetchLocations();
  }

  Future<void> addCurrentLocation(String name) async {
    setState(() => _isLoading = true); // Show loader
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    LocationData currentLocation = await location.getLocation();

    var existingLocations = await FirebaseFirestore.instance
        .collection('locations')
        .where('name', isEqualTo: name)
        .get();

    if (existingLocations.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Location name already exists!",
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('locations').add({
      'name': name,
      'latitude': currentLocation.latitude,
      'longitude': currentLocation.longitude,
    });
    setState(() => _isLoading = false);
    fetchLocations();
  }

  Future<void> openLocationPicker() async {
    setState(() => _isLoading = true); // Show loader
    Location location = Location();

    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SelectLocationPage()),
    );

    if (selectedLocation != null) {
      String? locationName =
          await _showInputDialog(context, "Enter Location Name");

      var existingLocations = await FirebaseFirestore.instance
          .collection('locations')
          .where('name', isEqualTo: locationName)
          .get();

      if (existingLocations.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Location name already exists!",
                  style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.red),
        );
        return;
      }

      if (locationName != null) {
        await FirebaseFirestore.instance.collection('locations').add({
          'name': locationName,
          'latitude': selectedLocation.latitude,
          'longitude': selectedLocation.longitude,
          'createdAt': FieldValue.serverTimestamp(),
        });

        fetchLocations();
      }
    }
  }

  Future<void> goToAddReminder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddReminderPage(locations)),
    );
    fetchLocations(); // Refresh data after returning
  }

  Future<void> stopGeofenceService() async {
    await FlutterForegroundTask.stopService(); // Stop foreground service
    GeofenceHandler.stopGeofenceTracking(); // Stop geofence tracking

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Geofence tracking stopped."),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: SizedBox(
        width: 160, // Increase width
        height: 50, // Increase height
        child: FloatingActionButton(
          onPressed: stopGeofenceService,
          backgroundColor: Color(0xFF5436C6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10), // More rounded corners
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10), // Add padding
            child: Text(
              "Stop Service",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Ensure text is visible
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text("Remindix", style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF5436C6),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(
                      width: 150,
                      child: _buildButton("Add Location", openLocationPicker)),
                  SizedBox(
                      width: 150,
                      child: _buildButton("Add Reminder", goToAddReminder)),
                ],
              ),
            ),
            SizedBox(height: 10),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF5436C6),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  return Card(
                    shadowColor: Colors.transparent,
                    color: Colors.white,
                    margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(0xFF5436C6),
                                child: Icon(Icons.location_on,
                                    color: Colors.white),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  locations[index]['name'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    deleteLocation(locations[index]['id']),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          if (locations[index]['take'].isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.shopping_cart,
                                    color: Colors.green, size: 18),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Take: ${locations[index]['take'].join(', ')}",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          if (locations[index]['give'].isNotEmpty)
                            Row(
                              children: [
                                Icon(Icons.card_giftcard,
                                    color: Colors.blue, size: 18),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "Give: ${locations[index]['give'].join(', ')}",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          if (locations[index]['take'].isEmpty &&
                              locations[index]['give'].isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  "No reminders",
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF5436C6),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<String?> _showInputDialog(BuildContext context, String title) async {
    TextEditingController controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: TextStyle(color: Colors.black)),
        content: TextField(
            controller: controller, style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.red))),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text("OK", style: TextStyle(color: Colors.green))),
        ],
      ),
    );
  }
}
