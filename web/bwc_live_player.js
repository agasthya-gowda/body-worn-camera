// Real-time BWC video player: connects to the IMS media gateway's WebSocket
// and feeds fragmented-MP4 (fMP4) frames straight into a <video> element via
// MediaSource Extensions (MSE).
//
// Protocol reverse-engineered from the vendor's own IMS web frontend
// (chunk-common.*.js under /var/www/html/web/assets/js on the real server):
//   - Connect to ws(s)://<server>:<port>/RTSP/H264_AAC
//   - Each binary WebSocket message IS a raw ISO-BMFF (MP4) box - the vendor's
//     own code checks bytes[4..7] against the ASCII "moof" signature to find
//     media-fragment boxes, and appends every message directly into MSE's
//     SourceBuffer with no unwrapping.
//   - The very first message is the init segment (ftyp+moov, containing an
//     "avcC" box with the real H.264 profile/compatibility/level bytes). We
//     parse those three bytes out of it to build an exact
//     'video/mp4; codecs="avc1.PPCCLL, mp4a.40.2"' string instead of guessing,
//     since MediaSource.isTypeSupported() must match the stream exactly.

window.BwcPlayer = (function () {
  function findAvcCCodec(bytes) {
    // Look for the literal ASCII bytes "avcC" (box type marker) anywhere in
    // the init segment, then read the 3 profile/compat/level bytes that
    // immediately follow the fixed avcC header (version+flags(4) + config
    // version(1) = 5 bytes after the 4-byte type tag).
    const marker = [0x61, 0x76, 0x63, 0x43]; // "avcC"
    for (let i = 0; i + 4 + 5 + 3 <= bytes.length; i++) {
      if (
        bytes[i] === marker[0] &&
        bytes[i + 1] === marker[1] &&
        bytes[i + 2] === marker[2] &&
        bytes[i + 3] === marker[3]
      ) {
        const profile = bytes[i + 5];
        const compat = bytes[i + 6];
        const level = bytes[i + 7];
        const hex = (n) => n.toString(16).padStart(2, "0");
        return "avc1." + hex(profile) + hex(compat) + hex(level);
      }
    }
    return null;
  }

  function create(videoEl, wsUrl, callbacks) {
    callbacks = callbacks || {};
    let mediaSource = null;
    let sourceBuffer = null;
    let mimeType = null;
    const queue = [];
    let firstChunk = true;
    let closed = false;

    const ws = new WebSocket(wsUrl);
    ws.binaryType = "arraybuffer";

    function pump() {
      if (!sourceBuffer || sourceBuffer.updating || queue.length === 0) return;
      try {
        sourceBuffer.appendBuffer(queue.shift());
      } catch (e) {
        callbacks.onError && callbacks.onError("appendBuffer failed: " + e);
      }
    }

    ws.onopen = function () {
      callbacks.onStatus && callbacks.onStatus("connected");
    };

    ws.onmessage = function (evt) {
      if (closed) return;
      if (typeof evt.data === "string") {
        // Control/JSON message on the same socket - not video data.
        return;
      }
      const bytes = new Uint8Array(evt.data);

      if (firstChunk) {
        firstChunk = false;
        const codec = findAvcCCodec(bytes);
        mimeType = codec
          ? 'video/mp4; codecs="' + codec + ', mp4a.40.2"'
          : 'video/mp4; codecs="avc1.640028, mp4a.40.2"'; // fallback guess

        if (!MediaSource.isTypeSupported(mimeType)) {
          callbacks.onError && callbacks.onError("Unsupported codec: " + mimeType);
          return;
        }

        mediaSource = new MediaSource();
        videoEl.src = URL.createObjectURL(mediaSource);
        mediaSource.addEventListener("sourceopen", function () {
          sourceBuffer = mediaSource.addSourceBuffer(mimeType);
          sourceBuffer.mode = "sequence";
          sourceBuffer.addEventListener("updateend", pump);
          queue.push(bytes.buffer);
          pump();
          videoEl.play().catch(() => {});
          callbacks.onStatus && callbacks.onStatus("streaming");
        });
      } else {
        queue.push(bytes.buffer);
        pump();
      }
    };

    ws.onerror = function () {
      callbacks.onError && callbacks.onError("WebSocket error");
    };

    ws.onclose = function (evt) {
      callbacks.onStatus && callbacks.onStatus("closed: " + evt.code);
    };

    return {
      stop: function () {
        closed = true;
        try {
          ws.close();
        } catch (e) {}
        try {
          if (mediaSource && mediaSource.readyState === "open") {
            mediaSource.endOfStream();
          }
        } catch (e) {}
      },
    };
  }

  return { create: create };
})();
