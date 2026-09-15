#!/usr/bin/env python3
"""Local reverse proxy for the real IMS server.

The Flutter web app talks to this proxy on localhost instead of the real
server directly. Because both the app and this proxy are served from
"localhost" (only the port differs), the browser treats the session cookie
as same-site - Chrome's SameSite policy is scheme+host based, not port based.
That avoids needing SameSite=None/Secure (and therefore HTTPS + a trusted
cert) on the real server just to keep the app logged in across requests.

Run: python3 tools/ims_proxy.py
"""
import http.server
import socket
import ssl
import threading
import urllib.request
import urllib.error

UPSTREAM_HOST = "116.73.243.111"
UPSTREAM_PORT = 8443
UPSTREAM_SCHEME = "https"
LISTEN_PORT = 9090
ALLOWED_ORIGIN = "http://localhost:8765"

# Upstream uses a self-signed cert; we already know which server we're
# talking to (fixed IP above), so skip verification for this local dev proxy.
_ctx = ssl.create_default_context()
_ctx.check_hostname = False
_ctx.verify_mode = ssl.CERT_NONE


class ProxyHandler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def _proxy(self):
        upstream_url = f"{UPSTREAM_SCHEME}://{UPSTREAM_HOST}:{UPSTREAM_PORT}{self.path}"
        length = int(self.headers.get("Content-Length", 0) or 0)
        body = self.rfile.read(length) if length else None

        headers = {}
        for key in ("Content-Type", "Cookie"):
            if key in self.headers:
                headers[key] = self.headers[key]

        req = urllib.request.Request(upstream_url, data=body, headers=headers, method=self.command)
        try:
            with urllib.request.urlopen(req, context=_ctx, timeout=15) as resp:
                self._send(resp.status, resp.getheaders(), resp.read())
        except urllib.error.HTTPError as e:
            self._send(e.code, e.headers.items() if e.headers else [], e.read())
        except Exception as e:  # noqa: BLE001
            self._send(502, [], f'{{"code":502,"msg":"proxy error: {e}"}}'.encode())

    def _send(self, status, upstream_headers, body):
        self.send_response(status)
        skip = {"transfer-encoding", "connection", "content-length",
                "access-control-allow-origin", "access-control-allow-credentials",
                "access-control-allow-methods", "access-control-allow-headers"}
        for k, v in upstream_headers:
            if k.lower() not in skip:
                self.send_header(k, v)
        self.send_header("Access-Control-Allow-Origin", ALLOWED_ORIGIN)
        self.send_header("Access-Control-Allow-Credentials", "true")
        self.send_header("Access-Control-Allow-Methods", "*")
        self.send_header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", ALLOWED_ORIGIN)
        self.send_header("Access-Control-Allow-Credentials", "true")
        self.send_header("Access-Control-Allow-Methods", "*")
        self.send_header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_GET(self):
        if self.headers.get("Upgrade", "").lower() == "websocket":
            self._proxy_websocket()
        else:
            self._proxy()

    def do_POST(self):
        self._proxy()

    def _proxy_websocket(self):
        # The video/audio media gateway (RTSP/H264_AAC over WebSocket) only
        # runs on the real server's TLS port (8443, self-signed cert). Relaying
        # it here means the browser only ever talks to plain localhost - no
        # certificate-trust prompt needed, same reasoning as the REST proxying
        # above. This is a raw byte pipe once both WS handshakes complete;
        # WebSocket framing is untouched, so video data passes through as-is.
        try:
            raw_sock = socket.create_connection((UPSTREAM_HOST, UPSTREAM_PORT), timeout=10)
            upstream = _ctx.wrap_socket(raw_sock, server_hostname=UPSTREAM_HOST)
        except OSError as e:
            self.send_error(502, f"Cannot reach upstream: {e}")
            return

        req_lines = [f"{self.command} {self.path} HTTP/1.1", f"Host: {UPSTREAM_HOST}:{UPSTREAM_PORT}"]
        for key in ("Upgrade", "Connection", "Sec-WebSocket-Key", "Sec-WebSocket-Version",
                    "Sec-WebSocket-Protocol", "Sec-WebSocket-Extensions", "Origin"):
            if key in self.headers:
                req_lines.append(f"{key}: {self.headers[key]}")
        req_lines.append("")
        req_lines.append("")
        upstream.sendall("\r\n".join(req_lines).encode())

        resp_data = b""
        while b"\r\n\r\n" not in resp_data:
            chunk = upstream.recv(4096)
            if not chunk:
                break
            resp_data += chunk
        header_part, _, leftover = resp_data.partition(b"\r\n\r\n")
        status_line = header_part.split(b"\r\n")[0] if header_part else b""
        if b"101" not in status_line:
            self.send_error(502, "Upstream WebSocket handshake failed")
            upstream.close()
            return

        self.send_response_only(101, "Switching Protocols")
        for line in header_part.split(b"\r\n")[1:]:
            if line:
                k, _, v = line.decode(errors="replace").partition(":")
                self.send_header(k.strip(), v.strip())
        self.end_headers()
        self.wfile.flush()

        client_sock = self.connection
        if leftover:
            client_sock.sendall(leftover)

        def pipe(src, dst):
            try:
                while True:
                    data = src.recv(65536)
                    if not data:
                        break
                    dst.sendall(data)
            except OSError:
                pass
            finally:
                try:
                    dst.shutdown(socket.SHUT_WR)
                except OSError:
                    pass

        t1 = threading.Thread(target=pipe, args=(client_sock, upstream), daemon=True)
        t2 = threading.Thread(target=pipe, args=(upstream, client_sock), daemon=True)
        t1.start()
        t2.start()
        t1.join()
        t2.join()
        upstream.close()
        self.close_connection = True

    def log_message(self, fmt, *args):
        print(f"[ims_proxy] {self.command} {self.path} -> {args[1] if len(args) > 1 else ''}")


if __name__ == "__main__":
    server = http.server.ThreadingHTTPServer(("127.0.0.1", LISTEN_PORT), ProxyHandler)
    print(f"IMS local proxy listening on http://127.0.0.1:{LISTEN_PORT} -> {UPSTREAM_SCHEME}://{UPSTREAM_HOST}:{UPSTREAM_PORT}")
    server.serve_forever()
