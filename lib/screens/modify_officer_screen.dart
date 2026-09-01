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
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
              ),
              const SizedBox(height: 12),
              const Text('Delete Officer Record?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Are you sure you want to remove ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    TextSpan(
                        text: widget.officer['realname'] ?? 'this officer',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    TextSpan(
                        text: ' (#${widget.officer['hostcode']}) from the active registry?',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  InputDecoration _fieldDecoration(String label, IconData icon, {bool required = false, bool enabled = true}) {
    return InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: TextStyle(color: enabled ? Colors.white54 : Colors.white24, fontSize: 12),
      prefixIcon: Icon(icon, color: enabled ? Colors.white38 : Colors.white24, size: 18),
      filled: true,
      fillColor: enabled ? const Color(0xFF020617) : const Color(0xFF0F172A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
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
            // ---- Top App Bar ----
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Modify Officer',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('ID: ${widget.officer['id']} • #${widget.officer['hostcode']}',
                            style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  _HoverDeleteButton(onTap: _isSubmitting ? () {} : _deleteOfficer),
                ],
              ),
            ),

            // ---- Form ----
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      initialValue: widget.officer['hostcode'] ?? '',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                      decoration: _fieldDecoration('Badge Code (cannot be changed)', Icons.tag, enabled: false),
                      enabled: false,
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
                            decoration: _fieldDecoration('Mobile', Icons.phone_iphone),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _telController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            decoration: _fieldDecoration('Tel', Icons.call),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _sortController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _fieldDecoration('Sort Order', Icons.sort),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _noteController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: _fieldDecoration('Notes', Icons.notes),
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
                            : const Icon(Icons.save, size: 18),
                        label: Text(
                          _isSubmitting ? 'Saving Changes...' : 'SAVE OFFICER MODIFICATIONS',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.4),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 6,
                          shadowColor: Colors.blue.withOpacity(0.4),
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
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFF334155) : const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Icon(widget.icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }
}

class _HoverDeleteButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HoverDeleteButton({required this.onTap});

  @override
  State<_HoverDeleteButton> createState() => _HoverDeleteButtonState();
}

class _HoverDeleteButtonState extends State<_HoverDeleteButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _isHovered ? Colors.redAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
              SizedBox(width: 4),
              Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}