import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HastaneHaritaEkrani extends StatefulWidget {
  @override
  _HastaneHaritaEkraniState createState() => _HastaneHaritaEkraniState();
}

class _HastaneHaritaEkraniState extends State<HastaneHaritaEkrani> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<Marker> _hospitalMarkers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Konum servisleri kapalı.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });

    _fetchHospitals(position.latitude, position.longitude);
  }

  Future<void> _fetchHospitals(double lat, double lon) async {
    // Switch to Overpass API for reliable "nearby" search
    // Search hospitals (amenity=hospital) and clinics (amenity=clinic) within 5km (5000m)
    // Also including doctors for broader coverage if hospitals are sparse
    final query = '''
      [out:json][timeout:25];
      (
        node(around:5000,$lat,$lon)["amenity"="hospital"];
        node(around:5000,$lat,$lon)["amenity"="clinic"];
        node(around:5000,$lat,$lon)["healthcare"="hospital"];
        node(around:5000,$lat,$lon)["healthcare"="clinic"];
      );
      out body;
      >;
      out skel qt;
    ''';
    
    // We need to encode the query properly or just pass it as data
    final url = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeQueryComponent(query)}');
    
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List elements = data['elements'] as List;
        final List<Marker> markers = [];
        final Set<String> addedNames = {}; // To prevent duplicates slightly

        for (var item in elements) {
          final hLat = item['lat'];
          final hLon = item['lon'];
          if (hLat == null || hLon == null) continue;

          // Use name if available, else 'Sağlık Kurumu'
          final tags = item['tags'] ?? {};
          final name = tags['name'] ?? tags['amenity'] ?? 'Bilinmeyen Sağlık Kurumu';
          
          // Simple dedup based on name
          if (addedNames.contains(name)) continue;
          addedNames.add(name);

          markers.add(
            Marker(
              point: LatLng(hLat, hLon),
              width: 50,
              height: 50,
              child: GestureDetector(
                onTap: () => _showHospitalDetails(name, hLat, hLon),
                child: Container(
                   decoration: const BoxDecoration(
                     color: Colors.white,
                     shape: BoxShape.circle,
                     boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                   ),
                   child: const Icon(Icons.local_hospital, color: Colors.red, size: 30),
                ),
              ),
            ),
          );
        }

        if (mounted) {
          setState(() {
            _hospitalMarkers = markers;
            _isLoading = false;
          });
          if (markers.isEmpty) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yakınınızda hastane veya klinik bulunamadı.')));
          }
        }
      } else {
        throw Exception('Overpass API Error: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching hospitals: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: Hastaneler yüklenemedi. ($e)')));
      }
    }
  }

  void _showHospitalDetails(String name, double lat, double lon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: const Color(0xFFE8F5E9),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: const Icon(Icons.local_hospital, color: Color(0xFF6BAA75), size: 30),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3436),
                      ),
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis,
                                     ),
                   ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                     final uri = Uri.parse("google.navigation:q=$lat,$lon");
                     if (await canLaunchUrl(uri)) {
                       await launchUrl(uri);
                     } else {
                       // Fallback to web map
                       await launchUrl(Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$lat,$lon"));
                     }
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text("Yol Tarifi Al", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6BAA75),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            ],
          ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          _currentLocation == null 
           ? const Center(child: CircularProgressIndicator())
           : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                 initialCenter: _currentLocation!,
                 initialZoom: 14.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.recovery.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 60,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                          ),
                        ),
                      ),
                    ),
                    ..._hospitalMarkers,
                  ],
                ),
              ],
            ),
            
            // Back Button
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF2D3436)),
                ),
              ),
            ),

            // Loading Overlay
            if (_isLoading)
               Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: Row(
                    children: const [
                       SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                       SizedBox(width: 8),
                       Text("Aranıyor...", style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
               ),
               
            // Recenter Button
            Positioned(
              bottom: 32,
              right: 16,
              child: FloatingActionButton(
                onPressed: () {
                  if (_currentLocation != null) {
                    _mapController.move(_currentLocation!, 15);
                  }
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.my_location, color: Color(0xFF2D3436)),
              ),
            ),
        ],
      ),
    );
  }
}
