// Bridges the real-time BWC video stream into Flutter Web.
//
// The actual WebSocket connection, MSE (MediaSource Extensions) setup, and
// fMP4 parsing all live in web/bwc_live_player.js - browsers have no built-in
// way to decode this vendor's H.264/AAC-over-WebSocket stream, and Flutter/Dart
// has no video decoder of its own either, so the real work happens in JS via
// the standard browser APIs and we just bridge into it.
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

@JS('BwcPlayer.create')
external JSObject _createPlayer(
  web.HTMLVideoElement videoEl,
  JSString wsUrl,
  JSObject callbacks,
);

class BwcVideoController {
  JSObject? _handle;

  void start(web.HTMLVideoElement videoEl, String wsUrl, {
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) {
    final callbacks = <String, JSFunction>{
      if (onStatus != null) 'onStatus': ((JSString s) => onStatus(s.toDart)).toJS,
      if (onError != null) 'onError': ((JSString e) => onError(e.toDart)).toJS,
    };
    final jsCallbacks = callbacks.jsify() as JSObject;
    _handle = _createPlayer(videoEl, wsUrl.toJS, jsCallbacks);
  }

  void stop() {
    _handle?.callMethod<JSAny?>('stop'.toJS);
    _handle = null;
  }
}

/// Embeds a real <video> element into the Flutter widget tree and drives it
/// via [BwcVideoController.start] once the WebSocket stream URL is known.
class BwcVideoView extends StatefulWidget {
  final String viewType;
  final void Function(web.HTMLVideoElement videoEl) onElementCreated;

  const BwcVideoView({
    super.key,
    required this.viewType,
    required this.onElementCreated,
  });

  @override
  State<BwcVideoView> createState() => _BwcVideoViewState();
}

class _BwcVideoViewState extends State<BwcVideoView> {
  @override
  void initState() {
    super.initState();
    ui_web.platformViewRegistry.registerViewFactory(widget.viewType, (int viewId) {
      final video = web.HTMLVideoElement()
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      widget.onElementCreated(video);
      return video;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: widget.viewType);
  }
}
