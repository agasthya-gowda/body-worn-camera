import 'package:flutter/material.dart';
import 'recording_screen.dart';
import '../services/api_service.dart';

class LiveViewScreen extends StatefulWidget {
  const LiveViewScreen({super.key});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  bool _isMuted = false;
  bool _isRecording = false;
  String _currentTime = '';
  String _location = '12.9716° N, 77.5946° E · MG Road, Bengaluru';
  final ApiService _apiService = ApiService();
  bool _isStreaming = false;
  bool _isConnecting = true;
  String? _rtspUrl;
  String? _wsIp;
  String? _wsPort;
  String _streamError = '';
  // TODO: This should come from the selected device on dashboard, hardcoded for now
  final String _hostbody = "0300098";
  final String _imei = "864156025728283";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _startStream();
  }

  Future<void> _startStream() async {
    setState(() => _isConnecting = true);
    final result = await _apiService.startVideoCall([_hostbody]);
    final streams = result['streams'] as List<Map<String, dynamic>>;

    if (result['code'] == 200 && streams.isNotEmpty) {
      final streamData = streams[0];
      setState(() {
        _rtspUrl = streamData['rtsp'];
        _wsIp = streamData['wsip'];
        _wsPort = streamData['wsport'];
        _isStreaming = true;
        _isConnecting = false;
      });
      // Start audio alongside video, per "process for audio calls is same as video calls" (doc para 13)
      await _apiService.startAudioCall([_hostbody]);
    } else {
      final failedDevices = result['failedDevices'] as List<Map<String, dynamic>>;
      String errorMsg = result['msg'] ?? 'Failed to start video call';
      if (failedDevices.isNotEmpty) {
        errorMsg = failedDevices[0]['err_msg'] ?? errorMsg;
      }
      setState(() {
        _streamError = errorMsg;
        _isConnecting = false;
      });
    }
  }

  @override
  void dispose() {
    _apiService.stopVideoCall([_hostbody]);
    _apiService.stopAudioCall([_hostbody], ["1"]);
    super.dispose();
  }

  Future<void> _toggleMute() async {
    final newMuteState = !_isMuted;
    final commandType = newMuteState ? "startmute" : "stopmute";
    final result = await _apiService.sendCommand(_imei, commandType);
    if (result['code'] == 200) {
      setState(() => _isMuted = newMuteState);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ${newMuteState ? "mute" : "unmute"}: ${result['msg']}')),
        );
      }
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Live View'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xFF111111),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.videocam_off,
                        size: 80,
                        color: Color(0xFF333333),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Camera Feed',
                        style: TextStyle(
                          color: Color(0xFF444444),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _currentTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFF0A1628),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF112240),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _location,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      label: _isMuted ? 'Unmute' : 'Mute',
                      color: _isMuted ? Colors.red : Colors.white,
                      onTap: _toggleMute,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RecordingScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 4,
                          ),
                        ),
                        child: const Icon(
                          Icons.fiber_manual_record,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    _buildControlButton(
                      icon: Icons.bookmark_outline,
                      label: 'Bookmark',
                      color: Colors.white,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bookmark added!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF112240),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}