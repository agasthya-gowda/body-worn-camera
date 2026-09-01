import 'package:flutter/material.dart';
import '../services/api_service.dart';

const _kBg = Color(0xFF0A1628);
const _kSurface = Color(0xFF0F172A);
const _kBorder = Color(0xFF1E293B);
const _kInputBg = Color(0xFF020617);
const _kAmber600 = Color(0xFFD97706);
const _kAmber500 = Color(0xFFF59E0B);
const _kAmber400 = Color(0xFFFBBF24);
const _kBlue600 = Color(0xFF2563EB);
const _kBlue400 = Color(0xFF60A5FA);
const _kRose600 = Color(0xFFE11D48);
const _kRose300 = Color(0xFFFDA4AF);
const _kEmerald400 = Color(0xFF34D399);

class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;
  const _HoverIconButton({required this.icon, required this.onTap, this.isLoading = false});

  @override
  State<_HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<_HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF334155) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: widget.isLoading
              ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
              : Icon(widget.icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }
}

class _HoverAddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverAddButton({required this.onTap});

  @override
  State<_HoverAddButton> createState() => _HoverAddButtonState();
}

class _HoverAddButtonState extends State<_HoverAddButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _isHovered ? _kAmber500 : _kAmber600,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: _kAmber600.withOpacity(_isHovered ? 0.5 : 0.3), blurRadius: 10)],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white, size: 16),
              SizedBox(width: 4),
              Text('Add Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverDeviceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _HoverDeviceCard({required this.child, required this.onTap});

  @override
  State<_HoverDeviceCard> createState() => _HoverDeviceCardState();
}

class _HoverDeviceCardState extends State<_HoverDeviceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _isHovered ? _kAmber500.withOpacity(0.4) : Colors.transparent),
          ),
          child: widget.child,
        ),
      ),
    );
  }
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
        return _kEmerald400;
      case '1':
        return _kRose300;
      case '2':
        return Colors.white38;
      case '3':
        return _kAmber400;
      default:
        return Colors.white38;
    }
  }

  InputDecoration _sheetFieldDecoration(String label, {String? hint, bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
      filled: true,
      fillColor: _kInputBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kBorder)),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _kAmber500, width: 1.5)),
    );
  }

  Widget _sheetField(TextEditingController c, String label,
      {String? hint, TextInputType? type, bool required = false, bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        style: TextStyle(color: Colors.white, fontSize: 13, fontFamily: mono ? 'monospace' : null),
        decoration: _sheetFieldDecoration(label, hint: hint, required: required),
      ),
    );
  }

  Widget _recorderTypeToggle({required String value, required ValueChanged<String> onChanged}) {
    Widget option(String code, String label) {
      final selected = value == code;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(code),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? _kBlue600 : _kInputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? const Color(0xFF60A5FA) : _kBorder),
            ),
            child: Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      );
    }

    return Row(
      children: [
        option('1', 'Live Streaming ("1")'),
        const SizedBox(width: 8),
        option('0', 'Normal ("0")'),
      ],
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
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.9),
              decoration: BoxDecoration(
                border: Border.all(color: _kBorder),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kBorder))),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: _kAmber500.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.videocam, color: _kAmber400, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Body Camera',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text('Register new BWC hardware', style: TextStyle(fontSize: 11, color: Colors.white38)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 20, right: 20, top: 18,
                        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sheetField(hostbodyController, 'Device Number / Serial SN (hostbody)',
                              hint: 'e.g. 0300102', required: true, mono: true),
                          _sheetField(bhController, 'Assigned Unit (bh)', required: true),
                          const Text('RECORDER MODE (recorderType) *',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white38, fontSize: 11, letterSpacing: 0.6)),
                          const SizedBox(height: 8),
                          _recorderTypeToggle(value: recorderType, onChanged: (v) => setSheetState(() => recorderType = v)),
                          const SizedBox(height: 14),
                          _sheetField(typesnController, 'Hardware Model (typesn)', hint: 'e.g. 12 for G7', required: true),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _sheetField(capacityController, 'Storage (MB)', hint: 'e.g. 128000', type: TextInputType.number, mono: true)),
                              const SizedBox(width: 12),
                              Expanded(child: _sheetField(versionController, 'Firmware Version', hint: 'e.g. G7_1.02.080', mono: true)),
                            ],
                          ),
                          _sheetField(productFirmController, 'Manufacturer'),
                          _sheetField(officerNameController, 'Assigned Officer (optional)', hint: 'e.g. Agasthya Gowda'),
                          const SizedBox(height: 4),
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
                                backgroundColor: _kAmber600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isSaving
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('REGISTER CAMERA TO INVENTORY',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.4)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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

    void showDeleteConfirm(BuildContext outerContext, StateSetter setOuterState) {
      showDialog(
        context: outerContext,
        barrierColor: Colors.black87,
        builder: (dialogContext) => Dialog(
          backgroundColor: _kSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: _kBorder)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: _kRose600.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.warning_amber_rounded, color: _kRose300, size: 26),
                ),
                const SizedBox(height: 12),
                Text('Delete Device BWC-${device['hostbody']}?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 6),
                Text('This will permanently remove device hardware serial #${device['hostbody']} from inventory.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.white38)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E293B),
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          setOuterState(() => isSaving = true);
                          final result = await _apiService.deleteDevice(device['id'].toString());
                          if (!outerContext.mounted) return;
                          if (result['code'] == 200) {
                            Navigator.pop(outerContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Device Removed: BWC-${device['hostbody']} deleted.'), backgroundColor: Colors.green),
                            );
                            _loadDevices();
                          } else {
                            setOuterState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRose600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.9),
              decoration: BoxDecoration(
                border: Border.all(color: _kBorder),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _kBorder))),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(color: _kAmber500.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.videocam, color: _kAmber400, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isEditing ? 'Edit Device' : 'BWC-${device['hostbody'] ?? ''}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                              Text(isEditing ? 'Modify configuration' : 'Hardware detail & telemetry',
                                  style: const TextStyle(fontSize: 11, color: Colors.white38)),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 4),
                          decoration: BoxDecoration(
                            color: isEditing ? _kBlue600 : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isEditing ? _kBlue400 : _kBorder),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            color: isEditing ? Colors.white : Colors.white70,
                            onPressed: isSaving ? null : () => setSheetState(() => isEditing = !isEditing),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        left: 20, right: 20, top: 18,
                        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
                      ),
                      child: !isEditing
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _kSurface,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: _kBorder),
                                  ),
                                  child: Column(
                                    children: [
                                      _detailRow('Device SN:', device['hostbody'] ?? '-', valueColor: _kAmber400, mono: true, bold: true),
                                      _detailStateRow(device['state']?.toString()),
                                      _detailRow('Model Name:', device['type_name'] ?? '-', bold: true),
                                      _detailRow('Assigned Unit:', device['unitname'] ?? '-'),
                                      _detailRow('Assigned Officer:', device['hostname'] ?? 'Unassigned', valueColor: _kEmerald400, bold: true),
                                      _detailRow('Recorder Type:', device['recorder_type_name'] ?? '-', valueColor: _kBlue400),
                                      _detailRow('Manufacturer:', device['product_firm'] ?? '-'),
                                      _detailRow('Capacity:', '${device['capacity'] ?? '0'} MB', mono: true),
                                      _detailRow('Firmware:', device['version'] ?? '-', mono: true),
                                      _detailRow('Last Login:', device['last_login']?.toString() ?? 'Never', mono: true, isLast: true),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: isSaving ? null : () => showDeleteConfirm(sheetContext, setSheetState),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: _kRose600.withOpacity(0.15),
                                        side: BorderSide(color: _kRose600.withOpacity(0.4)),
                                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Icon(Icons.delete_outline, color: _kRose300),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: isSaving ? null : () => setSheetState(() => isEditing = true),
                                        icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                                        label: const Text('Edit Device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1E293B),
                                          side: BorderSide.none,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sheetField(hostbodyController, 'Device Number', hint: 'e.g. 0300100', required: true, mono: true),
                                _sheetField(bhController, 'Unit', required: true),
                                _sheetField(officerNameController, 'Assigned Officer (optional)', hint: 'e.g. Agasthya Gowda'),
                                const Text('RECORDER MODE (recorderType) *',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white38, fontSize: 11, letterSpacing: 0.6)),
                                const SizedBox(height: 8),
                                _recorderTypeToggle(value: recorderType, onChanged: (v) => setSheetState(() => recorderType = v)),
                                const SizedBox(height: 14),
                                _sheetField(typesnController, 'Device Model ID (typesn)', required: true),
                                _sheetField(productFirmController, 'Manufacturer (optional)'),
                                _sheetField(capacityController, 'Storage Capacity in MB (optional)', type: TextInputType.number, mono: true),
                                _sheetField(versionController, 'Firmware Version (optional)', mono: true),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: isSaving ? null : () => showDeleteConfirm(sheetContext, setSheetState),
                                      style: OutlinedButton.styleFrom(
                                        backgroundColor: _kRose600.withOpacity(0.15),
                                        side: BorderSide(color: _kRose600.withOpacity(0.4)),
                                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      child: const Icon(Icons.delete_outline, color: _kRose300),
                                    ),
                                    const SizedBox(width: 10),
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
                                          backgroundColor: _kBlue600,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        child: isSaving
                                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : const Text('SAVE MODIFICATIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor, bool mono = false, bool bold = false, bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white38)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? Colors.white,
                fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailStateRow(String? stateCode) {
    final color = _stateColor(stateCode);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Status State:', style: TextStyle(fontSize: 12, color: Colors.white38)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Text(_stateLabel(stateCode),
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: _kSurface,
                border: Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: Row(
                children: [
                  _HoverIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Device Inventory',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Body Worn Cameras (${_devices.length})',
                            style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _HoverIconButton(
                      icon: Icons.refresh,
                      onTap: _isLoading ? () {} : _loadDevices,
                      isLoading: _isLoading,
                    ),
                  ),
                  _HoverAddButton(onTap: _showAddDeviceSheet),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: _kSurface,
                border: Border(bottom: BorderSide(color: _kBorder)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search by SN (hostbody), officer, or unit...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kAmber500, width: 1.5),
                  ),
                  filled: true,
                  fillColor: _kInputBg,
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
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
                  ? const Center(child: CircularProgressIndicator(color: _kAmber400))
                  : _devices.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.videocam_off_outlined, size: 40, color: Colors.white24),
                              SizedBox(height: 8),
                              Text('No body cameras found.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadDevices,
                          color: _kAmber400,
                          backgroundColor: _kSurface,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: _devices.length,
                            itemBuilder: (context, index) {
                              final device = _devices[index];
                              final stateColor = _stateColor(device['state']);
                              return _HoverDeviceCard(
                                onTap: () => _showDeviceDetailSheet(device),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: _kSurface,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: _kBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: _kAmber500.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: _kAmber500.withOpacity(0.3)),
                                        ),
                                        child: const Center(
                                          child: Icon(Icons.videocam, color: _kAmber400, size: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text('BWC-${device['hostbody'] ?? 'Unknown'}',
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 13,
                                                          fontFamily: 'monospace'),
                                                      overflow: TextOverflow.ellipsis),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: stateColor.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: stateColor.withOpacity(0.4)),
                                                  ),
                                                  child: Text(
                                                    _stateLabel(device['state']),
                                                    style: TextStyle(color: stateColor, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(device['type_name'] ?? '',
                                                    style: const TextStyle(color: _kAmber400, fontSize: 11, fontWeight: FontWeight.w600)),
                                                const SizedBox(width: 6),
                                                const Text('•', style: TextStyle(color: Colors.white24, fontSize: 11)),
                                                const SizedBox(width: 6),
                                                const Icon(Icons.person_outline, size: 11, color: Colors.white38),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(device['hostname'] ?? 'Unassigned',
                                                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                                                      overflow: TextOverflow.ellipsis),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Text('${device['capacity'] ?? '0'} MB',
                                                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace')),
                                                const SizedBox(width: 6),
                                                const Text('•', style: TextStyle(color: Colors.white24, fontSize: 10)),
                                                const SizedBox(width: 6),
                                                Text(device['recorder_type']?.toString() == '1' ? 'Live Stream' : 'Normal',
                                                    style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                                const SizedBox(width: 6),
                                                const Text('•', style: TextStyle(color: Colors.white24, fontSize: 10)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(device['unitname'] ?? '',
                                                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                                                      overflow: TextOverflow.ellipsis),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.edit_outlined, size: 16, color: Colors.white38),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
