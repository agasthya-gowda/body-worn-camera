import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic> _deviceStates = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    final searchText = _searchController.text.trim();
    final result = await _apiService.getAllDevices(
      hostkey: searchText.isEmpty ? null : searchText,
    );
    if (result['code'] == 200) {
      final data = result['data'];
      setState(() {
        _devices = List<Map<String, dynamic>>.from(data['devicelist'] ?? []);
        _deviceStates = Map<String, dynamic>.from(data['device_state'] ?? {});
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load devices: ${result['msg']}')),
        );
      }
    }
  }

  String _stateLabel(String? stateCode) => _deviceStates[stateCode]?.toString() ?? 'Unknown';

  Color _stateColor(String? stateCode) {
    switch (stateCode) {
      case '0':
        return Colors.green;
      case '1':
        return Colors.red;
      case '2':
        return Colors.grey;
      case '3':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _sheetField(TextEditingController c, String label, {String? hint, TextInputType? type, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  // ---------------- ADD DEVICE BOTTOM SHEET ----------------
  void _showAddDeviceSheet() {
    final bhController = TextEditingController(text: 'ChipScape Police Dept');
    final hostbodyController = TextEditingController();
    final officerNameController = TextEditingController();
    final productFirmController = TextEditingController();
    final capacityController = TextEditingController();
    final typesnController = TextEditingController(text: '12');
    final versionController = TextEditingController();
    String recorderType = '1';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Add Device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1628))),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(sheetContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sheetField(hostbodyController, 'Device Number (hostbody)', hint: 'e.g. 0300100', required: true),
                    _sheetField(bhController, 'Unit', required: true),
                    _sheetField(officerNameController, 'Assigned Officer (optional)', hint: 'Enter officer name'),
                    Text('Recorder Type *', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Normal'),
                            selected: recorderType == '0',
                            onSelected: (_) => setSheetState(() => recorderType = '0'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Live Streaming'),
                            selected: recorderType == '1',
                            onSelected: (_) => setSheetState(() => recorderType = '1'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _sheetField(typesnController, 'Device Model ID (typesn)', hint: 'e.g. 12 for G7', required: true),
                    _sheetField(productFirmController, 'Manufacturer (optional)'),
                    _sheetField(capacityController, 'Storage Capacity in MB (optional)', hint: 'e.g. 128000', type: TextInputType.number),
                    _sheetField(versionController, 'Firmware Version (optional)', hint: 'e.g. G7_1.02.080'),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (hostbodyController.text.trim().isEmpty ||
                                    bhController.text.trim().isEmpty ||
                                    typesnController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(content: Text('Please fill all required fields')),
                                  );
                                  return;
                                }
                                setSheetState(() => isSaving = true);
                                final result = await _apiService.addDevice(
                                  bh: bhController.text.trim(),
                                  hostbody: hostbodyController.text.trim(),
                                  recorderType: recorderType,
                                  typesn: typesnController.text.trim(),
                                  productFirm: productFirmController.text.trim().isEmpty ? null : productFirmController.text.trim(),
                                  capacity: capacityController.text.trim().isEmpty ? null : capacityController.text.trim(),
                                  version: versionController.text.trim().isEmpty ? null : versionController.text.trim(),
                                  officerName: officerNameController.text.trim().isEmpty ? null : officerNameController.text.trim(),
                                );
                                if (!sheetContext.mounted) return;
                                if (result['code'] == 200) {
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Device added successfully'), backgroundColor: Colors.green),
                                  );
                                  _loadDevices();
                                } else {
                                  setSheetState(() => isSaving = false);
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A3A6B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isSaving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Add Device'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- DEVICE DETAILS / MODIFY / DELETE BOTTOM SHEET ----------------
  void _showDeviceDetailSheet(Map<String, dynamic> device) {
    final bhController = TextEditingController(text: device['unitname']?.toString() ?? '');
    final officerNameController = TextEditingController(text: device['hostname'] == 'Unassigned' ? '' : (device['hostname']?.toString() ?? ''));
    final hostbodyController = TextEditingController(text: device['hostbody']?.toString() ?? '');
    final productFirmController = TextEditingController(text: device['product_firm']?.toString() ?? '');
    final capacityController = TextEditingController(text: device['capacity']?.toString() ?? '');
    final typesnController = TextEditingController(text: device['typesn']?.toString() ?? '');
    final versionController = TextEditingController(text: device['version']?.toString() ?? '');
    String recorderType = device['recorder_type']?.toString() ?? '1';
    bool isSaving = false;
    bool isEditing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(device['hostbody'] ?? 'Device',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0A1628))),
                        Row(
                          children: [
                            if (!isEditing)
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Color(0xFF1A3A6B)),
                                onPressed: () => setSheetState(() => isEditing = true),
                              ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(sheetContext),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!isEditing) ...[
                      _detailRow(Icons.badge_outlined, 'Officer', device['hostname'] ?? 'Unassigned'),
                      _detailRow(Icons.apartment_outlined, 'Unit', device['unitname'] ?? '-'),
                      _detailRow(Icons.videocam_outlined, 'Model', device['type_name'] ?? '-'),
                      _detailRow(Icons.settings_outlined, 'Recorder Type', device['recorder_type_name'] ?? '-'),
                      _detailRow(Icons.factory_outlined, 'Manufacturer', device['product_firm'] ?? '-'),
                      _detailRow(Icons.sd_storage_outlined, 'Capacity', '${device['capacity'] ?? '0'} MB'),
                      _detailRow(Icons.system_update_outlined, 'Firmware', device['version'] ?? '-'),
                      _detailRow(Icons.login_outlined, 'Last Login', device['last_login']?.toString() ?? 'Never'),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final confirmed = await showDialog<bool>(
                                    context: sheetContext,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Device'),
                                      content: Text('Remove ${device['hostbody']} from the registry? This cannot be undone.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  setSheetState(() => isSaving = true);
                                  final result = await _apiService.deleteDevice(device['id'].toString());
                                  if (!sheetContext.mounted) return;
                                  if (result['code'] == 200) {
                                    Navigator.pop(sheetContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Device deleted'), backgroundColor: Colors.green),
                                    );
                                    _loadDevices();
                                  } else {
                                    setSheetState(() => isSaving = false);
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          label: const Text('Delete Device', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ] else ...[
                      _sheetField(bhController, 'Unit', required: true),
                      _sheetField(hostbodyController, 'Device Number', hint: 'e.g. 0300100', required: true),
                      _sheetField(officerNameController, 'Assigned Officer (optional)', hint: 'e.g. Agasthya Gowda'),
                      Text('Recorder Type *', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700], fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Normal'),
                              selected: recorderType == '0',
                              onSelected: (_) => setSheetState(() => recorderType = '0'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('Live Streaming'),
                              selected: recorderType == '1',
                              onSelected: (_) => setSheetState(() => recorderType = '1'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _sheetField(typesnController, 'Device Model ID (typesn)', required: true),
                      _sheetField(productFirmController, 'Manufacturer (optional)'),
                      _sheetField(capacityController, 'Storage Capacity in MB (optional)', type: TextInputType.number),
                      _sheetField(versionController, 'Firmware Version (optional)'),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setSheetState(() => isEditing = false),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (bhController.text.trim().isEmpty || typesnController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                                          const SnackBar(content: Text('Please fill all required fields')),
                                        );
                                        return;
                                      }
                                      setSheetState(() => isSaving = true);
                                      final result = await _apiService.modifyDevice(
                                        id: device['id'].toString(),
                                        bh: bhController.text.trim(),
                                        recorderType: recorderType,
                                        typesn: typesnController.text.trim(),
                                        productFirm: productFirmController.text.trim().isEmpty ? null : productFirmController.text.trim(),
                                        capacity: capacityController.text.trim().isEmpty ? null : capacityController.text.trim(),
                                        version: versionController.text.trim().isEmpty ? null : versionController.text.trim(),
                                        officerName: officerNameController.text.trim().isEmpty ? 'Unassigned' : officerNameController.text.trim(),
                                        hostbody: hostbodyController.text.trim(),
                                      );
                                      if (!sheetContext.mounted) return;
                                      if (result['code'] == 200) {
                                        Navigator.pop(sheetContext);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Device updated'), backgroundColor: Colors.green),
                                        );
                                        _loadDevices();
                                      } else {
                                        setSheetState(() => isSaving = false);
                                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                                          SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A3A6B),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isSaving
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0A1628))),
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
        backgroundColor: Colors.white,
        title: const Text('Devices', style: TextStyle(color: Color(0xFF0A1628), fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF1A3A6B)),
            onPressed: _showAddDeviceSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or device ID',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadDevices();
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _loadDevices(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _devices.isEmpty
                    ? const Center(child: Text('No devices found'))
                    : RefreshIndicator(
                        onRefresh: _loadDevices,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF1A3A6B),
                                  child: Icon(Icons.videocam, color: Colors.white, size: 20),
                                ),
                                title: Text(device['hostbody'] ?? 'Unknown Device'),
                                subtitle: Text(
                                  '${device['hostname'] ?? 'Unassigned'} · ${device['type_name'] ?? ''} · ${device['capacity'] ?? '0'} MB',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _stateColor(device['state']).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _stateLabel(device['state']),
                                        style: TextStyle(color: _stateColor(device['state']), fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                onTap: () => _showDeviceDetailSheet(device),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}