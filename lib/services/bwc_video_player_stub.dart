// Non-web platforms (Android/iOS) don't have the browser's MediaSource/WS
// video pipeline that bwc_video_player_web.dart drives, so this stub keeps
// the same public API without pulling in package:web / dart:js_interop
// (which fail to compile outside a web target).
import 'package:flutter/material.dart';

class BwcVideoController {
  void start(dynamic videoEl, String wsUrl, {
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) {
    onError?.call('Live video is only supported on Web for now');
  }

  void stop() {}
}

class BwcVideoView extends StatelessWidget {
  final String viewType;
  final void Function(dynamic videoEl) onElementCreated;

  const BwcVideoView({
    super.key,
    required this.viewType,
    required this.onElementCreated,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Live video is only supported on Web for now',
        style: TextStyle(color: Colors.white70),
      ),
    );
  }
}
