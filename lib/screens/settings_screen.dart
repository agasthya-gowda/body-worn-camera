import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

const _kBg = Color(0xFF0A1628);
const _kSurface = Color(0xFF0F172A);
const _kBorder = Color(0xFF1E293B);
const _kBlue600 = Color(0xFF2563EB);
const _kBlue400 = Color(0xFF60A5FA);
const _kRose600 = Color(0xFFE11D48);
const _kRose300 = Color(0xFFFDA4AF);

class _PillSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PillSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? _kBlue600 : const Color(0xFF334155),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 3)],
          ),
        ),
      ),
    );
  }
}

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
        backgroundColor: _kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: _kBorder),
        ),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
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
              backgroundColor: _kRose600,
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
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Settings',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Application & Telemetry Preferences',
                            style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  const SizedBox(height: 16),
                  _buildProfileCard(),
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 20),
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
                            backgroundColor: Color(0xFF1E3A5F),
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
                            backgroundColor: Color(0xFF1E3A5F),
                          ),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('About'),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kSurface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _kBorder.withOpacity(0.8)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.verified_user_outlined, size: 16, color: _kBlue400),
                            SizedBox(width: 6),
                            Text('BWC Mobile Law Enforcement Portal',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Build v1.0.0',
                            style: TextStyle(fontSize: 11, color: Colors.white38, fontFamily: 'monospace')),
                        const SizedBox(height: 6),
                        const Text(
                          'ChipScape Police Dept • Real-time Body Worn Camera Fleet Management',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: Colors.white38),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _kRose600.withOpacity(0.15),
                          foregroundColor: _kRose300,
                          side: BorderSide(color: _kRose600.withOpacity(0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.logout, color: _kRose300),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _kRose300),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _kBlue600.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _kBlue600.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                _username.isNotEmpty ? _username[0].toUpperCase() : 'O',
                style: const TextStyle(color: _kBlue400, fontWeight: FontWeight.bold, fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _username,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              const Text(
                'Field Officer',
                style: TextStyle(color: _kBlue400, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white38,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildIconBadge(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _kBlue600.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBlue600.withOpacity(0.3)),
      ),
      child: Icon(icon, color: _kBlue400, size: 18),
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
      leading: _buildIconBadge(icon),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.white38),
      ),
      trailing: _PillSwitch(value: value, onChanged: onChanged),
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
      leading: _buildIconBadge(icon),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.white38),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Colors.white38,
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
      leading: _buildIconBadge(icon),
      title: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white),
      ),
      trailing: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        dropdownColor: _kSurface,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white38),
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
    return const Divider(height: 1, indent: 68, color: _kBorder);
  }
}
