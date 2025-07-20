import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

class AdminOrderMapPanel extends StatefulWidget {
  final String userId;

  const AdminOrderMapPanel({super.key, required this.userId});

  @override
  State<AdminOrderMapPanel> createState() => _AdminOrderMapPanelState();
}

class _AdminOrderMapPanelState extends State<AdminOrderMapPanel> {
  GoogleMapController? _controller;
  LatLng? adminLocation;
  LatLng? userLocation;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  BitmapDescriptor? companyIcon;

  final MarkerId adminMarkerId = const MarkerId('admin_location');
  final MarkerId userMarkerId = const MarkerId('user_location');

  String? distanceText;
  String? durationText;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker().then((_) => _loadLocations());
  }

  Future<void> _loadCustomMarker() async {
    final ByteData data =
        await rootBundle.load('assets/restaurant_location.png');
    final Uint8List bytes = data.buffer.asUint8List();
    final img.Image original = img.decodeImage(bytes)!;
    final img.Image resized = img.copyResize(original, width: 80, height: 80);
    final Uint8List resizedBytes = Uint8List.fromList(img.encodePng(resized));

    companyIcon = BitmapDescriptor.fromBytes(resizedBytes);
  }

  Future<void> _loadLocations() async {
    try {
      // Admin Location
      final admin = await Supabase.instance.client
          .from('admin_locations')
          .select()
          .eq('id', 1)
          .maybeSingle();

      // Latest User Location
      final userLoc = await Supabase.instance.client
          .from('user_locations')
          .select()
          .eq('user_id', widget.userId)
          .order('inserted_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (admin != null && userLoc != null) {
        adminLocation = LatLng(admin['lat'], admin['lng']);
        userLocation = LatLng(userLoc['lat'], userLoc['lng']);

        markers.add(Marker(
          markerId: adminMarkerId,
          position: adminLocation!,
          icon: companyIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: admin['name'] ?? 'Company'),
        ));

        markers.add(Marker(
          markerId: userMarkerId,
          position: userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Customer'),
        ));

        await _drawRoute();
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error loading map data: $e");
    }
  }

  Future<void> _drawRoute() async {
    if (adminLocation == null || userLocation == null) return;

    final url = Uri.parse('http://router.project-osrm.org/route/v1/driving/'
        '${adminLocation!.longitude},${adminLocation!.latitude};'
        '${userLocation!.longitude},${userLocation!.latitude}'
        '?overview=full&geometries=geojson');

    try {
      final res = await http.get(url);
      final data = json.decode(res.body);

      if (data['code'] == 'Ok') {
        final route = data['routes'][0];

        final distanceMeters = route['distance']; // in meters
        final durationSeconds = route['duration']; // in seconds

        final coords = route['geometry']['coordinates'];
        final List<LatLng> path = coords.map<LatLng>((c) {
          return LatLng(c[1].toDouble(), c[0].toDouble());
        }).toList();

        setState(() {
          distanceText = (distanceMeters / 1000).toStringAsFixed(2) + ' km';
          durationText = (durationSeconds / 60).toStringAsFixed(0) + ' min';

          polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            points: path,
            color: Colors.blue,
            width: 5,
          ));
        });

        final bounds = _boundsFromLatLngList([adminLocation!, userLocation!]);
        _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      }
    } catch (e) {
      debugPrint("Route draw error: $e");
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude;
    double x1 = list.first.latitude;
    double y0 = list.first.longitude;
    double y1 = list.first.longitude;

    for (var latLng in list) {
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Route'),
      ),
      body: adminLocation == null || userLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: adminLocation!,
                    zoom: 13,
                  ),
                  markers: markers,
                  polylines: polylines,
                  onMapCreated: (controller) {
                    _controller = controller;
                  },
                ),
                if (distanceText != null && durationText != null)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time,
                              size: 20, color: Colors.blue),
                          const SizedBox(width: 6),
                          Text(durationText!,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 16),
                          const Icon(Icons.place,
                              size: 20, color: Colors.redAccent),
                          const SizedBox(width: 6),
                          Text(distanceText!,
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
