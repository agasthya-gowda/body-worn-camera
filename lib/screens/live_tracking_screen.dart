import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import 'location_history_screen.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _locations = [];
  bool _isLoading = true;
  String? _errorMsg;
  Timer? _refreshTimer;

  static const LatLng _defaultCenter = LatLng(12.9716, 77.5946);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadDeviceList();
    await _refreshLocations();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshLocations());
  }

  Future<void> _loadDeviceList() async {
    final result = await _apiService.getOnlineDevices();
    if (result['code'] == 200) {
      final companies = List<Map<String, dynamic>>.from(result['data'] ?? []);
      List<Map<String, dynamic>> devices = [];
      for (var company in companies) {
        if (company['sub'] != null) {
          devices.addAll(List<Map<String, dynamic>>.from(company['sub']));
        }
      }
      setState(() {
        _devices = devices.where((d) => d['lineon'] == 1).toList();
      });
    }
  }

  Future<void> _refreshLocations() async {
    if (_devices.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMsg = 'No online devices to track';
      });
      return;
    }

    final ids = _devices.map((d) => d['did'].toString()).toList();
    final result = await _apiService.getRealtimeLocation(ids);

    if (!mounted) return;

    if (result['code'] == 200) {
      setState(() {
        _locations = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _isLoading = false;
        _errorMsg = null;
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMsg = result['msg']?.toString() ?? 'Failed to load locations';
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  LatLng _mapCenter() {
    if (_locations.isEmpty) return _defaultCenter;
    final lat = double.tryParse(_locations[0]['lat'].toString()) ?? _defaultCenter.latitude;
    final lng = double.tryParse(_locations[0]['lng'].toString()) ?? _defaultCenter.longitude;
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Live Tracking', style: TextStyle(color: Color(0xFF0A1628), fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A3A6B)),
            onPressed: _refreshLocations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_errorMsg != null)
                  Container(
                    width: double.infinity,
                    color: Colors.orange[50],
                    padding: const EdgeInsets.all(10),
                    child: Text(_errorMsg!, style: const TextStyle(color: Colors.orange)),
                  ),
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _mapCenter(),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.chipscape.bwc_app',
                      ),
                      MarkerLayer(
                        markers: _locations.map((loc) {
                          final lat = double.tryParse(loc['lat'].toString()) ?? 0.0;
                          final lng = double.tryParse(loc['lng'].toString()) ?? 0.0;
                          final name = loc['name']?.toString() ?? 'Unknown';
                          final deviceId = loc['id']?.toString() ?? '';
                          return Marker(
                            point: LatLng(lat, lng),
                            width: 120,
                            height: 60,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LocationHistoryScreen(
                                      hostbody: deviceId,
                                      officerName: name,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0A1628),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      name,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.location_on, color: Colors.red, size: 34),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '${_locations.length} officer(s) tracked · Tap a marker for route history · Updates every 5s',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }
}