// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:location/location.dart';

// class SelectLocationPage extends StatefulWidget {
//   @override
//   _SelectLocationPageState createState() => _SelectLocationPageState();
// }

// class _SelectLocationPageState extends State<SelectLocationPage> {
//   LatLng? selectedLocation;
//   late GoogleMapController mapController;
//   Location location = Location();

//   void _onMapCreated(GoogleMapController controller) {
//     mapController = controller;
//   }

//   Future<void> _getCurrentLocation() async {
//     var currentLocation = await location.getLocation();
//     setState(() {
//       selectedLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
//     });
//     mapController.animateCamera(CameraUpdate.newLatLngZoom(selectedLocation!, 13));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Pick a Location")),
//       body: Stack(
//         children: [
//           GoogleMap(
//             onMapCreated: _onMapCreated,
//             initialCameraPosition: CameraPosition(
//               target: LatLng(20.5937, 78.9629), // Default: India
//               zoom: 5,
//             ),
//             onTap: (LatLng location) {
//               setState(() {
//                 selectedLocation = location;
//               });
//             },
//             markers: selectedLocation != null
//                 ? {
//                     Marker(
//                       markerId: MarkerId("selected"),
//                       position: selectedLocation!,
//                     )
//                   }
//                 : {},
//           ),
//           Positioned(
//             bottom: 80,
//             right: 16,
//             child: FloatingActionButton(
//               child: Icon(Icons.my_location),
//               onPressed: _getCurrentLocation,
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         child: Icon(Icons.check),
//         onPressed: () {
//           if (selectedLocation != null) {
//             Navigator.pop(context, selectedLocation);
//           }
//         },
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as Geocoding;

class SelectLocationPage extends StatefulWidget {
  @override
  _SelectLocationPageState createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  LatLng? selectedLocation;
  late GoogleMapController mapController;
  Location location = Location();
  TextEditingController searchController = TextEditingController();

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    var currentLocation = await location.getLocation();
    setState(() {
      selectedLocation = LatLng(currentLocation.latitude!, currentLocation.longitude!);
    });
    mapController.animateCamera(CameraUpdate.newLatLngZoom(selectedLocation!, 15));
  }

  Future<void> _searchLocation(String locationName) async {
    try {
      List<Geocoding.Location> locations = await Geocoding.locationFromAddress(locationName);
      if (locations.isNotEmpty) {
        setState(() {
          selectedLocation = LatLng(locations.first.latitude, locations.first.longitude);
        });
        mapController.animateCamera(CameraUpdate.newLatLngZoom(selectedLocation!, 15));
      }
    } catch (e) {
      // Handle error (e.g., show a snackbar)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location not found")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Pick a Location")),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.hybrid,
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(20.5937, 78.9629), // Default: India
              zoom: 10,
            ),
            onTap: (LatLng location) {
              setState(() {
                selectedLocation = location;
              });
            },
            markers: selectedLocation != null
                ? {
                    Marker(
                      markerId: MarkerId("selected"),
                      position: selectedLocation!,
                    )
                  }
                : {},
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search Location",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _searchLocation(searchController.text);
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              child: Icon(Icons.my_location),
              onPressed: _getCurrentLocation,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: () {
          if (selectedLocation != null) {
            Navigator.pop(context, selectedLocation);
          }
        },
      ),
    );
  }
}