import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddOfficerScreen extends StatefulWidget {
  final Map<String, dynamic> userTypes;

  const AddOfficerScreen({super.key, required this.userTypes});

  @override
  State<AddOfficerScreen> createState() => _AddOfficerScreenState();
}

class _HoverIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HoverIconButton({required this.icon, required this.onTap});

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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF334155) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _AddOfficerScreenState extends State<AddOfficerScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _hostcodeController = TextEditingController();
  final _realnameController = TextEditingController();
  final _bhController = TextEditingController();
  final _mobileController = TextEditingController();
  final _telController = TextEditingController();
  final _sortController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedType;
  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await _apiService.registerUser(
      hostcode: _hostcodeController.text.trim(),
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
      final newUserId = result['data']?['id'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Officer registered successfully (ID: $newUserId)'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, newUserId);
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
    _mobileController.dispose();
    _telController.dispose();
    _sortController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label, IconData icon, {bool required = false}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      prefixIcon: Icon(icon, color: Colors.white38, size: 18),
      filled: true,
      fillColor: const Color(0xFF020617),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Row(
                children: [
                  _HoverIconButton(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Add New Officer',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Personnel Enrollment (Multipart Form)',
                          style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _hostcodeController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _fieldDecoration('Badge / Hostcode', Icons.tag, required: true),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _realnameController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _fieldDecoration('Full Name (realname)', Icons.person_outline, required: true),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _bhController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _fieldDecoration('Unit Name (bh)', Icons.apartment, required: true),
                      validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _fieldDecoration('Police Rank (type)', Icons.shield_outlined, required: true),
                      items: widget.userTypes.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value.toString())))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedType = value),
                      validator: (value) => (value == null) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _mobileController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _fieldDecoration('Mobile (optional)', Icons.phone_iphone),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _telController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _fieldDecoration('Tel (optional)', Icons.call),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _sortController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _fieldDecoration('Display Sort Order', Icons.sort),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _noteController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _fieldDecoration('Officer Notes (optional)', Icons.notes),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitForm,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          _isSubmitting ? 'Submitting Registration...' : 'ENROLL OFFICER TO DEPARTMENT',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.4),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 6,
                          shadowColor: Colors.green.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}