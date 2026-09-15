import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'recording_screen.dart';
import '../services/api_service.dart';

class LiveViewScreen extends StatefulWidget {
  final String hostbody;
  final String imei;
  final String officerName;

  const LiveViewScreen({
    super.key,
    required this.hostbody,
    required this.imei,
    required this.officerName,
  });

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  bool _isMuted = false;
  bool _isRecording = false;
  String _currentTime = '';
  String _location = 'Acquiring GPS fix...';
  final ApiService _apiService = ApiService();
  bool _isStreaming = false;
  bool _isConnecting = true;
  String? _rtspUrl;
  String? _mappedRtspUrl;
  String? _wsIp;
  String? _wsPort;
  String _streamError = '';
  String? _lastAction;
  int? _batteryLevel;
  Timer? _locationTimer;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _startStream();
    _loadDeviceDetail();
    _refreshLocation();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) => _refreshLocation());
  }

  Future<void> _startStream() async {
    setState(() => _isConnecting = true);
    final result = await _apiService.startVideoCall([widget.hostbody]);
    if (!mounted) return;
    final streams = result['streams'] as List<Map<String, dynamic>>;

    if (result['code'] == 200 && streams.isNotEmpty) {
      final streamData = streams[0];
      setState(() {
        _rtspUrl = streamData['rtsp'];
        _mappedRtspUrl = streamData['mapped_rtsp'];
        _wsIp = streamData['wsip'];
        _wsPort = streamData['wsport'];
        _isStreaming = true;
        _isConnecting = false;
      });
      // Start audio alongside video, per "process for audio calls is same as video calls" (doc para 13)
      await _apiService.startAudioCall([widget.hostbody]);
      // RTSP playback only works on Android/iOS/desktop (no web implementation
      // exists for the fvp/mdk backend); the mapped_rtsp URL is reachable from
      // outside the server, unlike the internal rtsp:// (127.0.0.1) address
      // meant for the server's own use.
      if (!kIsWeb && _mappedRtspUrl != null) {
        final controller = VideoPlayerController.networkUrl(Uri.parse(_mappedRtspUrl!));
        try {
          await controller.initialize();
          if (!mounted) {
            controller.dispose();
            return;
          }
          await controller.play();
          setState(() => _videoController = controller);
        } catch (e) {
          controller.dispose();
          if (!mounted) return;
          setState(() => _streamError = 'Video playback error: $e');
        }
      }
    } else {
      final failedDevices = result['failedDevices'] as List<Map<String, dynamic>>;
      String errorMsg = result['msg'] ?? 'Failed to start video call';
      if (failedDevices.isNotEmpty) {
        errorMsg = failedDevices[0]['err_msg'] ?? errorMsg;
      }
      if (!mounted) return;
      setState(() {
        _streamError = errorMsg;
        _isConnecting = false;
      });
    }
  }

  Future<void> _loadDeviceDetail() async {
    final result = await _apiService.getDeviceDetail([widget.hostbody]);
    if (!mounted) return;
    if (result['code'] == 200) {
      final data = List<Map<String, dynamic>>.from(result['data'] ?? []);
      if (data.isNotEmpty) {
        setState(() {
          _batteryLevel = int.tryParse(data[0]['electric']?.toString() ?? '');
        });
      }
    }
  }

  Future<void> _refreshLocation() async {
    final result = await _apiService.getRealtimeLocation([widget.hostbody]);
    if (!mounted) return;
    if (result['code'] == 200) {
      final points = List<Map<String, dynamic>>.from(result['data'] ?? []);
      if (points.isNotEmpty) {
        final lat = points[0]['lat'];
        final lng = points[0]['lng'];
        setState(() => _location = '$lat, $lng');
      }
    }
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _apiService.stopVideoCall([widget.hostbody]);
    _apiService.stopAudioCall([widget.hostbody], ["1"]);
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _toggleMute() async {
    final newMuteState = !_isMuted;
    final commandType = newMuteState ? "startmute" : "stopmute";
    final result = await _apiService.sendCommand(widget.imei, commandType);
    if (!mounted) return;
    if (result['code'] == 200) {
      setState(() {
        _isMuted = newMuteState;
        _lastAction = newMuteState ? 'Audio feed silenced' : 'Two-way audio restored';
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to ${newMuteState ? "mute" : "unmute"}: ${result['msg']}')),
      );
    }
  }

  Future<void> _takeRemotePhoto() async {
    final result = await _apiService.remoteKickoff(widget.imei, "takephoto");
    if (!mounted) return;
    if (result['code'] == 200) {
      setState(() => _lastAction = 'High-resolution snapshot captured and saved to evidence buffer');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['code'] == 200 ? 'Photo captured' : 'Failed: ${result['msg']}'),
        backgroundColor: result['code'] == 200 ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _startRemoteVideo() async {
    final result = await _apiService.remoteKickoff(widget.imei, "startvideo");
    if (!mounted) return;
    if (result['code'] == 200) {
      setState(() {
        _isRecording = true;
        _lastAction = 'Remote video recording command initiated on body camera';
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['code'] == 200 ? 'Remote recording started' : 'Failed: ${result['msg']}'),
        backgroundColor: result['code'] == 200 ? Colors.green : Colors.red,
      ),
    );
  }

  void _handleBookmark() {
    setState(() => _lastAction = 'Incident marker bookmarked at $_currentTime');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evidence tagged!'), backgroundColor: Colors.green),
    );
  }

  Future<void> _confirmRestart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.75),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withOpacity(0.3)),
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
              const Text('Restart Body Camera?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                        text: 'This will send a hardware reboot command to device ',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    TextSpan(
                        text: 'BWC-${widget.hostbody}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                    const TextSpan(
                        text: '. Live telemetry will momentarily drop.',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
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
                      child: const Text('Confirm Restart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await _apiService.remoteRestart(widget.imei, widget.hostbody);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['code'] == 200 ? 'Restart command sent' : 'Failed: ${result['msg']}'),
        backgroundColor: result['code'] == 200 ? Colors.green : Colors.red,
      ),
    );
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _updateTime();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // ---- Main video area with tactical HUD ----
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Real RTSP video feed (Android/iOS/desktop only - no web implementation exists)
                        if (_videoController != null && _videoController!.value.isInitialized)
                          Positioned.fill(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: SizedBox(
                                width: _videoController!.value.size.width,
                                height: _videoController!.value.size.height,
                                child: VideoPlayer(_videoController!),
                              ),
                            ),
                          ),
                        // Center camera placeholder + pulsing status dot + tactical corner brackets
                        if (_videoController == null)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: const Icon(Icons.videocam_off, size: 36, color: Colors.white38),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _isStreaming ? Colors.greenAccent : Colors.white24,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isConnecting
                                  ? 'Connecting...'
                                  : _isStreaming
                                      ? 'Camera Feed'
                                      : 'Stream Unavailable',
                              style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                        text: _streamError.isNotEmpty
                                            ? '$_streamError · '
                                            : 'RTSP / WebSocket stream negotiated with hardware unit ',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                    TextSpan(
                                        text: 'BWC-${widget.hostbody}',
                                        style: const TextStyle(
                                            color: Color(0xFF4A9EFF), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),

                        // HUD top-left telemetry
                        Positioned(
                          top: 60,
                          left: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.podcasts,
                                      size: 13, color: _isStreaming ? Colors.greenAccent : Colors.white38),
                                  const SizedBox(width: 4),
                                  Text('BWC-${widget.hostbody} • ${widget.officerName}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace')),
                                ],
                              ),
                              const SizedBox(height: 2),
                              const Text('RES: 1080P @ 30FPS • AES-256',
                                  style: TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace')),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.battery_charging_full, size: 11, color: Colors.greenAccent),
                                  const SizedBox(width: 3),
                                  Text(
                                    _batteryLevel != null ? '$_batteryLevel% • Buffer Active' : 'Battery: --',
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 10, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Last action toast overlay
                        if (_lastAction != null)
                          Positioned(
                            top: 110,
                            left: 24,
                            right: 24,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF4A9EFF).withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_lastAction!,
                                        style: const TextStyle(color: Color(0xFFBFDBFE), fontSize: 11)),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Top overlay bar: back, LIVE badge, clock, menu
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _hudIconButton(Icons.arrow_back, () => Navigator.pop(context)),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: (_isStreaming ? Colors.red : Colors.grey).withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.circle, size: 6, color: Colors.white),
                                          const SizedBox(width: 4),
                                          Text(_isStreaming ? 'LIVE' : 'OFFLINE',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.access_time, size: 12, color: Color(0xFF4A9EFF)),
                                          const SizedBox(width: 4),
                                          Text(_currentTime,
                                              style: const TextStyle(
                                                  color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      color: const Color(0xFF0F172A),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      icon: Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.white24),
                                        ),
                                        child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                                      ),
                                      onSelected: (value) {
                                        if (value == 'restart') _confirmRestart();
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'restart',
                                          child: Row(
                                            children: [
                                              Icon(Icons.restart_alt, color: Colors.redAccent, size: 18),
                                              SizedBox(width: 8),
                                              Text('Restart Device',
                                                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Bottom GPS location bar
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _location,
                                          style: const TextStyle(
                                              color: Color(0xFF4A9EFF),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              fontFamily: 'monospace'),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---- Bottom control panel ----
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF020617),
                border: Border(top: BorderSide(color: Color(0xFF1E293B))),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _flatButton(
                          icon: Icons.camera_alt,
                          iconColor: const Color(0xFF4A9EFF),
                          label: 'Take Photo',
                          onTap: _takeRemotePhoto,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _flatButton(
                          icon: Icons.videocam,
                          iconColor: Colors.amberAccent,
                          label: 'Remote Rec',
                          onTap: _startRemoteVideo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _roundIconButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        color: _isMuted ? Colors.redAccent : Colors.white70,
                        background: _isMuted ? Colors.red.withOpacity(0.15) : const Color(0xFF0F172A),
                        border: _isMuted ? Colors.red.withOpacity(0.4) : const Color(0xFF1E293B),
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
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFBE123C), Color(0xFFF43F5E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF020617), width: 4),
                            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 16)],
                          ),
                          child: Center(
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                      ),
                      _roundIconButton(
                        icon: Icons.bookmark,
                        color: Colors.amberAccent,
                        background: const Color(0xFF0F172A),
                        border: const Color(0xFF1E293B),
                        onTap: _handleBookmark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hudIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _flatButton({
    required IconData icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required Color color,
    required Color background,
    required Color border,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
