import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ModifyOfficerScreen extends StatefulWidget {
  final Map<String, dynamic> officer;
  final Map<String, dynamic> userTypes;

  const ModifyOfficerScreen({super.key, required this.officer, required this.userTypes});

  @override
  State<ModifyOfficerScreen> createState() => _ModifyOfficerScreenState();
}

class _ModifyOfficerScreenState extends State<ModifyOfficerScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _realnameController;
  late TextEditingController _bhController;
  String? _selectedType;
  late TextEditingController _mobileController;
  late TextEditingController _telController;
  late TextEditingController _sortController;
  late TextEditingController _noteController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _realnameController = TextEditingController(text: widget.officer['realname'] ?? '');
    _bhController = TextEditingController(text: widget.officer['dbh'] ?? widget.officer['bh'] ?? '');
    _selectedType = widget.officer['type']?.toString();
    _mobileController = TextEditingController(text: widget.officer['mobile'] ?? '');
    _telController = TextEditingController(text: widget.officer['tel'] ?? '');
    _sortController = TextEditingController(text: widget.officer['sort'] ?? '');
    _noteController = TextEditingController(text: widget.officer['note'] ?? '');
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await _apiService.modifyUser(
      id: widget.officer['id'].toString(),
      realname: _realnameController.text.trim(),
      bh: _bhController.text.trim(),
      type: _selectedType ?? '',
      mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
      tel: _telController.text.trim().isEmpty ? null : _telController.text.trim(),
      sort: _sortController.text.trim().isEmpty ? null : _sortController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['code'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Officer updated successfully'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteOfficer() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Officer'),
        content: Text('Are you sure you want to delete ${widget.officer['realname']}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    final result = await _apiService.deleteUser(widget.officer['id'].toString());
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['code'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Officer deleted'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: ${result['msg']}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _realnameController.dispose();
    _bhController.dispose();
    _mobileController.dispose();
    _telController.dispose();
    _sortController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Edit Officer', style: TextStyle(color: Color(0xFF0A1628), fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              initialValue: widget.officer['hostcode'] ?? '',
              decoration: const InputDecoration(labelText: 'Badge ID (cannot be changed)', border: OutlineInputBorder()),
              enabled: false,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _realnameController,
              decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bhController,
              decoration: const InputDecoration(labelText: 'Unit Name *', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(labelText: 'Type *', border: OutlineInputBorder()),
              items: widget.userTypes.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.toString())))
                  .toList(),
              onChanged: (value) => setState(() => _selectedType = value),
              validator: (value) => (value == null) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileController,
              decoration: const InputDecoration(labelText: 'Mobile Number', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _telController,
              decoration: const InputDecoration(labelText: 'Telephone', border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sortController,
              decoration: const InputDecoration(labelText: 'Sort Order', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Update Officer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _isSubmitting ? null : _deleteOfficer,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Delete Officer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}