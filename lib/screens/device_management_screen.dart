import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _devices = [];
  bool _isLoading = true;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    final result = await _apiService.getAllDeviceList();
    if (result['code'] == 200) {
      setState(() {
        _devices = result['data']['devicelist'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMsg = result['msg'] ?? 'Failed to load devices';
        _isLoading = false;
      });
    }
  }

  void _showAddDeviceDialog() {
    final bhController = TextEditingController();
    final hostbodyController = TextEditingController();
    final typesnController = TextEditingController(text: '12');
    String recorderType = '1';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Device'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bhController,
                decoration: const InputDecoration(labelText: 'Unit ID (bh)'),
              ),
              TextField(
                controller: hostbodyController,
                decoration: const InputDecoration(labelText: 'Device Number (hostbody)'),
              ),
              TextField(
                controller: typesnController,
                decoration: const InputDecoration(labelText: 'Type SN (model code)'),
              ),
              DropdownButtonFormField<String>(
                initialValue: recorderType,
                decoration: const InputDecoration(labelText: 'Recorder Type'),
                items: const [
                  DropdownMenuItem(value: '0', child: Text('Normal')),
                  DropdownMenuItem(value: '1', child: Text('Live Streaming')),
                ],
                onChanged: (v) => recorderType = v ?? '1',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _apiService.addDevice(
                bh: bhController.text,
                hostbody: hostbodyController.text,
                recorderType: recorderType,
                typesn: typesnController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['code'] == 200 ? 'Device added!' : 'Failed: ${result['msg']}'),
                    backgroundColor: result['code'] == 200 ? Colors.green : Colors.red,
                  ),
                );
              }
              _loadDevices();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDeviceDialog(Map<String, dynamic> device) {
    final bhController = TextEditingController(text: device['danwei']?.toString() ?? '');
    final typesnController = TextEditingController(text: device['typesn']?.toString() ?? '12');
    String recorderType = device['recorder_type']?.toString() ?? '1';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Device'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Device: ${device['hostbody']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: bhController,
                decoration: const InputDecoration(labelText: 'Unit ID (bh)'),
              ),
              TextField(
                controller: typesnController,
                decoration: const InputDecoration(labelText: 'Type SN'),
              ),
              DropdownButtonFormField<String>(
                initialValue: recorderType,
                decoration: const InputDecoration(labelText: 'Recorder Type'),
                items: const [
                  DropdownMenuItem(value: '0', child: Text('Normal')),
                  DropdownMenuItem(value: '1', child: Text('Live Streaming')),
                ],
                onChanged: (v) => recorderType = v ?? '1',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _apiService.modifyDevice(
                id: device['id'].toString(),
                bh: bhController.text,
                recorderType: recorderType,
                typesn: typesnController.text,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['code'] == 200 ? 'Device updated!' : 'Failed: ${result['msg']}'),
                    backgroundColor: result['code'] == 200 ? Colors.green : Colors.red,
                  ),
                );
              }
              _loadDevices();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device?'),
        content: Text('Are you sure you want to delete ${device['hostbody']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await _apiService.deleteDevice(device['id'].toString());
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['code'] == 200 ? 'Device deleted!' : 'Failed: ${result['msg']}'),
                    backgroundColor: result['code'] == 200 ? Colors.green : Colors.red,
                  ),
                );
              }
              _loadDevices();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Device Management'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0A1628),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeviceDialog,
        backgroundColor: const Color(0xFF1A3A6B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMsg.isNotEmpty
              ? Center(child: Text(_errorMsg))
              : _devices.isEmpty
                  ? const Center(child: Text('No devices found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F0FE),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.videocam, color: Color(0xFF1A3A6B)),
                            ),
                            title: Text(
                              device['hostbody']?.toString() ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Officer: ${device['hostname'] ?? '-'} • Type: ${device['type_name'] ?? '-'}',
                            ),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditDeviceDialog(device);
                                } else if (value == 'delete') {
                                  _confirmDelete(device);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
