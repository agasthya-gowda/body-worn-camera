import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddOfficerScreen extends StatefulWidget {
  const AddOfficerScreen({super.key});

  @override
  State<AddOfficerScreen> createState() => _AddOfficerScreenState();
}

class _AddOfficerScreenState extends State<AddOfficerScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _hostcodeController = TextEditingController();
  final _realnameController = TextEditingController();
  final _bhController = TextEditingController();
  final _mobileController = TextEditingController();
  final _telController = TextEditingController();
  final _noteController = TextEditingController();

  final _typeController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await _apiService.registerUser(
      hostcode: _hostcodeController.text.trim(),
      realname: _realnameController.text.trim(),
      bh: _bhController.text.trim(),
      type: _typeController.text.trim(),
      mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
      tel: _telController.text.trim().isEmpty ? null : _telController.text.trim(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result['code'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Officer registered successfully'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${result['msg']}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _hostcodeController.dispose();
    _realnameController.dispose();
    _bhController.dispose();
    _typeController.dispose();
    _mobileController.dispose();
    _telController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Add Officer', style: TextStyle(color: Color(0xFF0A1628), fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _hostcodeController,
              decoration: const InputDecoration(labelText: 'Badge ID / Hostcode *', border: OutlineInputBorder()),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
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
            TextFormField(
              controller: _typeController,
              decoration: const InputDecoration(
                labelText: 'Type *',
                hintText: 'Enter type code (ask supervisor if unsure)',
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
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
                  : const Text('Register Officer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}