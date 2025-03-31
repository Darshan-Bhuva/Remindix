// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AddReminderPage extends StatefulWidget {
//   final List<Map<String, dynamic>> locations;
//   AddReminderPage(this.locations);

//   @override
//   _AddReminderPageState createState() => _AddReminderPageState();
// }

// class _AddReminderPageState extends State<AddReminderPage> {
//   String? selectedLocation;
//   String itemName = "";
//   String type = "Take"; // Default type

//   /// Save Reminder to Firebase
//   Future<void> saveReminder() async {
//     if (selectedLocation == null || itemName.isEmpty) return;

//     await FirebaseFirestore.instance.collection('reminders').add({
//       'location': selectedLocation,
//       'itemName': itemName,
//       'type': type,
//     });

//     Navigator.pop(context); // Go back to Home Page
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Add Reminder")),
//       body: Column(
//         children: [
//           DropdownButton<String>(
//             hint: Text("Select Location"),
//             value: selectedLocation,
//             items: widget.locations.map<DropdownMenuItem<String>>((loc) {
//               // ✅ Explicit type
//               return DropdownMenuItem<String>(
//                 // ✅ Explicit type
//                 value: loc['name'] as String, // ✅ Ensure it's a String
//                 child: Text(loc['name']),
//               );
//             }).toList(),
//             onChanged: (value) => setState(() => selectedLocation = value),
//           ),
//           TextField(
//             decoration: InputDecoration(labelText: "Item Name"),
//             onChanged: (value) => itemName = value,
//           ),
//           Row(
//             children: [
//               Radio(
//                   value: "Take",
//                   groupValue: type,
//                   onChanged: (val) => setState(() => type = val!)),
//               Text("Take"),
//               Radio(
//                   value: "Give",
//                   groupValue: type,
//                   onChanged: (val) => setState(() => type = val!)),
//               Text("Give"),
//             ],
//           ),
//           ElevatedButton(onPressed: saveReminder, child: Text("Save Reminder")),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddReminderPage extends StatefulWidget {
  final List<Map<String, dynamic>> locations;
  AddReminderPage(this.locations);

  @override
  _AddReminderPageState createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  String? selectedLocation;
  String itemName = "";
  String type = "Take"; // Default type

  /// Save Reminder to Firebase
  Future<void> saveReminder() async {
    if (selectedLocation == null || itemName.isEmpty) return;

    await FirebaseFirestore.instance.collection('reminders').add({
      'location': selectedLocation,
      'itemName': itemName,
      'type': type,
    });

    Navigator.pop(context); // Go back to Home Page
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7F7F7), // Background Color
      appBar: AppBar(
        title: Text("Add Reminder"),
        backgroundColor: Color(0xFF5436C6),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Dropdown
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButton<String>(
                  hint: Text("Select Location"),
                  value: selectedLocation,
                  isExpanded: true,
                  underline: SizedBox(), // Remove default underline
                  items: widget.locations.map<DropdownMenuItem<String>>((loc) {
                    return DropdownMenuItem<String>(
                      value: loc['name'] as String,
                      child: Text(loc['name']),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedLocation = value),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Item Name Input Field
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Item Name",
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => itemName = value,
                ),
              ),
            ),
            SizedBox(height: 16),

            // Radio Buttons
            Text("Reminder Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: Text("Take"),
                    value: "Take",
                    groupValue: type,
                    activeColor: Color(0xFF5436C6),
                    onChanged: (val) => setState(() => type = val!),
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: Text("Give"),
                    value: "Give",
                    groupValue: type,
                    activeColor: Color(0xFF5436C6),
                    onChanged: (val) => setState(() => type = val!),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Save Button
            Center(
              child: ElevatedButton(
                onPressed: saveReminder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5436C6),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Save Reminder",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
