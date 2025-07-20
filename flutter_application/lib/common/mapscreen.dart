import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapScreen extends StatefulWidget {
  final LatLng? currentLocation;

  const MapScreen({super.key, this.currentLocation});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  final TextEditingController addressController = TextEditingController();
  LatLng? currentLocation;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  bool showDirections = false;

  BitmapDescriptor? customIcon;
  final MarkerId adminMarkerId = const MarkerId('admin_location');
  final MarkerId userMarkerId = const MarkerId('user_location');

  @override
  void initState() {
    super.initState();
    _loadCustomMarker().then((_) {
      _fetchAndShowAdminLocation();
    });
    _getCurrentLocation();
  }

  Future<BitmapDescriptor> getResizedMarker(
      String path, int width, int height) async {
    final ByteData data = await rootBundle.load(path);
    final Uint8List bytes = data.buffer.asUint8List();

    final img.Image? original = img.decodeImage(bytes);
    final img.Image resized =
        img.copyResize(original!, width: width, height: height);

    final resizedBytes = Uint8List.fromList(img.encodePng(resized));
    return BitmapDescriptor.fromBytes(resizedBytes);
  }

  Future<void> _loadCustomMarker() async {
    customIcon =
        await getResizedMarker('assets/restaurant_location.png', 70, 70);
  }

  Future<void> _fetchAndShowAdminLocation() async {
    try {
      final data = await Supabase.instance.client
          .from('admin_locations')
          .select()
          .eq('id', 1)
          .single()
          .maybeSingle();

      if (data != null) {
        final lat = (data['lat'] as num).toDouble();
        final lng = (data['lng'] as num).toDouble();
        final name = data['name'] as String;

        final LatLng adminLatLng = LatLng(lat, lng);

        setState(() {
          markers.add(
            Marker(
              markerId: adminMarkerId,
              position: adminLatLng,
              icon: customIcon ?? BitmapDescriptor.defaultMarker,
              infoWindow: InfoWindow(title: name),
            ),
          );
        });

        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(adminLatLng, 14),
          );

          Future.delayed(const Duration(milliseconds: 500), () {
            mapController!.showMarkerInfoWindow(adminMarkerId);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching admin location from Supabase: $e');
    }
  }

  Future<void> _getRoute() async {
    if (currentLocation == null || markers.isEmpty) return;

    final adminMarker = markers.firstWhere((m) => m.markerId == adminMarkerId);
    final adminPosition = adminMarker.position;

    // Using OSRM Routing API (free and open source)
    final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/'
        '${currentLocation!.longitude},${currentLocation!.latitude};'
        '${adminPosition.longitude},${adminPosition.latitude}'
        '?overview=full&geometries=geojson');

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['code'] == 'Ok') {
        final coordinates = data['routes'][0]['geometry']['coordinates'];
        final List<LatLng> path = coordinates.map<LatLng>((coord) {
          return LatLng(coord[1].toDouble(), coord[0].toDouble());
        }).toList();

        setState(() {
          polylines.clear();
          polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            points: path,
            color: Colors.blue,
            width: 5,
          ));
          showDirections = true;
        });

        // Adjust camera to show both locations
        final bounds = _boundsFromLatLngList([
          currentLocation!,
          adminPosition,
        ]);
        mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
      _showErrorDialog('Failed to get route');
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;

              if (user != null && currentLocation != null) {
                try {
                  await Supabase.instance.client.from('user_locations').insert({
                    'user_id': user.id,
                    'lat': currentLocation!.latitude,
                    'lng': currentLocation!.longitude,
                    'address': addressController.text,
                  });
                } catch (e) {
                  debugPrint('Error saving location to Supabase: $e');
                }
              }
              Navigator.pop(context, addressController.text);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: currentLocation ?? const LatLng(28.3949, 84.1240),
              zoom: 7.0,
            ),
            onMapCreated: (GoogleMapController controller) {
              setState(() {
                mapController = controller;
              });

              if (markers.any((m) => m.markerId == adminMarkerId)) {
                final adminMarker =
                    markers.firstWhere((m) => m.markerId == adminMarkerId);
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(adminMarker.position, 14),
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  controller.showMarkerInfoWindow(adminMarkerId);
                });
              }
            },
            markers: markers,
            polylines: polylines,
            onTap: (LatLng position) {
              _updateLocation(position);
            },
          ),
          Positioned(
            top: 16.0,
            left: 16.0,
            right: 16.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        hintText: 'Enter Address',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      _searchAddress(addressController.text);
                    },
                  ),
                ],
              ),
            ),
          ),
          if (currentLocation != null &&
              markers.any((m) => m.markerId == adminMarkerId))
            Positioned(
              bottom: 100.0,
              right: 10.0,
              child: FloatingActionButton(
                onPressed: () {
                  if (showDirections) {
                    setState(() {
                      polylines.clear();
                      showDirections = false;
                    });
                    mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(currentLocation!, 14),
                    );
                  } else {
                    _getRoute();
                  }
                },
                backgroundColor: Colors.white,
                child: Icon(
                  showDirections ? Icons.clear : Icons.directions,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _searchAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final location = locations.first;
        _updateLocation(LatLng(location.latitude, location.longitude));
      } else {
        _showErrorDialog('Location not found');
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      _showErrorDialog('Failed to search for location');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final LocationPermission permission =
          await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showErrorDialog('Location permission denied');
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final LatLng userLocation = LatLng(position.latitude, position.longitude);
      _updateLocation(userLocation);
    } catch (e) {
      debugPrint('Error getting current location: $e');
      _showErrorDialog('Failed to get current location');
    }
  }

  Future<void> _updateLocation(LatLng position) async {
    setState(() {
      currentLocation = position;
      markers.removeWhere((m) => m.markerId == userMarkerId);
      markers.add(Marker(
        markerId: userMarkerId,
        position: currentLocation!,
        icon: BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(title: 'Your Location'),
      ));
    });
    await _getAddressFromLatLng(position);
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(currentLocation!, 14.0),
    );
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String address = [
          if (place.street != null && place.street!.isNotEmpty) place.street,
          if (place.subLocality != null && place.subLocality!.isNotEmpty)
            place.subLocality,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality,
          if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.isNotEmpty)
            place.subAdministrativeArea,
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty)
            place.administrativeArea,
          if (place.country != null && place.country!.isNotEmpty) place.country,
        ].join(', ');
        setState(() {
          addressController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
      _showErrorDialog('Failed to get address from coordinates');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
