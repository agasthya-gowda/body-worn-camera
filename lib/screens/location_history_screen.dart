import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class LocationHistoryScreen extends StatefulWidget {
  final String hostbody; // device SN, e.g. "0300098"
  final String officerName;

  const LocationHistoryScreen({super.key, required this.hostbody, required this.officerName});

  @override
  State<LocationHistoryScreen> createState() => _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends State<LocationHistoryScreen> {
  final ApiService _apiService = ApiService();
  final MapController _mapController = MapController();

  DateTime _startTime = DateTime.now().subtract(const Duration(hours: 2));
  DateTime _endTime = DateTime.now();

  List<Map<String, dynamic>> _points = [];
  Map<String, dynamic> _measure = {};
  bool _isLoading = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    final startTs = (_startTime.millisecondsSinceEpoch ~/ 1000).toString();
    final endTs = (_endTime.millisecondsSinceEpoch ~/ 1000).toString();

    final result = await _apiService.getGpsHistory(
      historyHostbody: widget.hostbody,
      startIn: startTs,
      endIn: endTs,
    );

    if (!mounted) return;

    if (result['code'] == 200) {
      final data = result['data'] ?? {};
      setState(() {
        _points = List<Map<String, dynamic>>.from(data['gpsarray'] ?? []);
        _measure = Map<String, dynamic>.from(data['measure'] ?? {});
        _isLoading = false;
      });
      if (_points.isNotEmpty) {
        final last = _points.last;
        final lat = double.tryParse(last['lat'].toString()) ?? 12.9716;
        final lng = double.tryParse(last['lng'].toString()) ?? 77.5946;
        // Delay until after the current frame so FlutterMap has finished
        // its first build before we try to move it (fixes "widget not
        // rendered yet" crash when history loads during initState)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapController.move(LatLng(lat, lng), 15);
          }
        });
      }
    } else {
      setState(() {
        _isLoading = false;
        _errorMsg = result['msg']?.toString() ?? 'Failed to load history';
      });
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startTime = combined;
      } else {
        _endTime = combined;
      }
    });
  }

  List<LatLng> get _routePoints {
    return _points.map((p) {
      final lat = double.tryParse(p['lat'].toString()) ?? 0.0;
      final lng = double.tryParse(p['lng'].toString()) ?? 0.0;
      return LatLng(lat, lng);
    }).toList();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('${widget.officerName} — Route History',
            style: const TextStyle(color: Color(0xFF0A1628), fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDateTime(isStart: true),
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text('From: ${_formatDateTime(_startTime)}', style: const TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDateTime(isStart: false),
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text('To: ${_formatDateTime(_endTime)}', style: const TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadHistory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A3A6B),
                    foregroundColor: Colors.white,
                  ),
                  child: const Icon(Icons.search, size: 18),
                ),
              ],
            ),
          ),
          if (_errorMsg != null)
            Container(
              width: double.infinity,
              color: Colors.orange[50],
              padding: const EdgeInsets.all(10),
              child: Text(_errorMsg!, style: const TextStyle(color: Colors.orange)),
            ),
          Expanded(
            flex: 3,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _points.isEmpty
                    ? const Center(child: Text('No GPS history in this time range'))
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _routePoints.isNotEmpty ? _routePoints.last : const LatLng(12.9716, 77.5946),
                          initialZoom: 15,
                          minZoom: 5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.chipscape.bwc_app',
                          ),
                          PolylineLayer(
                            polylines: [
                              Polyline(points: _routePoints, strokeWidth: 4, color: const Color(0xFF1A3A6B)),
                            ],
                          ),
                          MarkerLayer(
                            markers: [
                              if (_routePoints.isNotEmpty)
                                Marker(
                                  point: _routePoints.first,
                                  width: 30,
                                  height: 30,
                                  child: const Icon(Icons.flag, color: Colors.green, size: 28),
                                ),
                              if (_routePoints.isNotEmpty)
                                Marker(
                                  point: _routePoints.last,
                                  width: 30,
                                  height: 30,
                                  child: const Icon(Icons.location_on, color: Colors.red, size: 32),
                                ),
                            ],
                          ),
                        ],
                      ),
          ),
          if (_measure.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Speed thresholds (km/h) — Walk: <${_measure['walk']} · Bike: <${_measure['bike']} · Car: >${_measure['car']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ),
          Expanded(
            flex: 2,
            child: _points.isEmpty
                ? const SizedBox.shrink()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _points.length,
                    itemBuilder: (context, index) {
                      final p = _points[index];
                      final isLbs = p['islbs'] == '1';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            isLbs ? Icons.cell_tower : Icons.gps_fixed,
                            color: isLbs ? Colors.orange : Colors.green,
                            size: 20,
                          ),
                          title: Text(p['gpstime']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
                          subtitle: Text(
                            'Lat: ${p['lat']}, Lng: ${p['lng']} · ${isLbs ? "Estimated (cell)" : "GPS fix"}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text('${p['speed']} km/h', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
