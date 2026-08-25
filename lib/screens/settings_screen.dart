import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import 'add_officer_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _recordingIndicator = true;
  bool _autoUpload = true;
  bool _uploadOnWifiOnly = true;
  bool _gpsEnabled = true;
  String _recordingQuality = '1080p';
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Officer';
      _recordingIndicator = prefs.getBool('recordingIndicator') ?? true;
      _autoUpload = prefs.getBool('autoUpload') ?? true;
      _uploadOnWifiOnly = prefs.getBool('uploadOnWifiOnly') ?? true;
      _gpsEnabled = prefs.getBool('gpsEnabled') ?? true;
      _recordingQuality = prefs.getString('recordingQuality') ?? '1080p';
    });
  }



  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
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
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0A1628),
          ),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildProfileCard(),
          const SizedBox(height: 16),
          _buildSectionTitle('Camera'),
          _buildSettingsCard([
            _buildDropdownTile(
              icon: Icons.high_quality,
              label: 'Recording quality',
              value: _recordingQuality,
              options: ['576p', '720p', '1080p'],
              onChanged: (value) {
                setState(() => _recordingQuality = value!);
                _saveSetting('recordingQuality', value!);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.lightbulb_outline,
              label: 'Recording indicator',
              subtitle: 'LED light on while recording',
              value: _recordingIndicator,
              onChanged: (value) {
                setState(() => _recordingIndicator = value);
                _saveSetting('recordingIndicator', value);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.gps_fixed,
              label: 'GPS tracking',
              subtitle: 'Track location during recording',
              value: _gpsEnabled,
              onChanged: (value) {
                setState(() => _gpsEnabled = value);
                _saveSetting('gpsEnabled', value);
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('Upload'),
          _buildSettingsCard([
            _buildSwitchTile(
              icon: Icons.cloud_upload_outlined,
              label: 'Auto-upload',
              subtitle: 'Automatically upload recordings',
              value: _autoUpload,
              onChanged: (value) {
                setState(() => _autoUpload = value);
                _saveSetting('autoUpload', value);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.wifi,
              label: 'Upload on WiFi only',
              subtitle: 'Save mobile data',
              value: _uploadOnWifiOnly,
              onChanged: (value) {
                setState(() => _uploadOnWifiOnly = value);
                _saveSetting('uploadOnWifiOnly', value);
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('Connection'),
          _buildSettingsCard([
            _buildNavigationTile(
              icon: Icons.bluetooth,
              label: 'Bluetooth pairing',
              subtitle: 'Connect to BWC device',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Scanning for BWC devices...'),
                    backgroundColor: Color(0xFF1A3A6B),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildNavigationTile(
              icon: Icons.usb,
              label: 'USB connection',
              subtitle: 'Connect via USB cable',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Connect USB cable to BWC device'),
                    backgroundColor: Color(0xFF1A3A6B),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('Admin'),
          _buildSettingsCard([
            _buildNavigationTile(
              icon: Icons.person_add,
              label: 'Add Officer',
              subtitle: 'Register a new officer account',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddOfficerScreen()),
                );
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionTitle('About'),
          _buildSettingsCard([
            _buildNavigationTile(
              icon: Icons.info_outline,
              label: 'App version',
              subtitle: 'BWC Mobile v1.0.0',
              onTap: () {},
            ),
            _buildDivider(),
            _buildNavigationTile(
              icon: Icons.history,
              label: 'Audit log',
              subtitle: 'View activity history',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Audit log coming soon'),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.logout),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF1A3A6B),
            child: Text(
              _username.isNotEmpty ? _username[0].toUpperCase() : 'O',
              style: const TextStyle(
                color: Color(0xFF4A9EFF),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _username,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'Field Officer',
                style: TextStyle(
                  color: Color(0xFF4A9EFF),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1A3A6B), size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0A1628),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1A3A6B),
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1A3A6B), size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0A1628),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1A3A6B), size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0A1628),
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(option),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 68);
  }
}