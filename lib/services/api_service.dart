import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: Replace with real server IP/domain once received from CEO/vendor
  static const String baseUrl = "http://[ip]:[port]";

  String? _sessionCookie;

  // ---------------- LOGIN ----------------
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Step 1: MD5 hash the password (32-char lowercase)
      String md5Password = md5.convert(utf8.encode(password)).toString();

      // Step 2: Build the inner JSON
      Map<String, String> innerJson = {
        "username": username,
        "password": md5Password,
      };

      // Step 3: URL-encode then Base64-encode
      String jsonString = jsonEncode(innerJson);
      String urlEncoded = Uri.encodeComponent(jsonString);
      String loginInfo = base64Encode(utf8.encode(urlEncoded));

      // Step 4: Send request
      final response = await http.post(
        Uri.parse("$baseUrl/rest/index/login/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"login_info": loginInfo}),
      );

      // Step 5: Extract PHPSESSID from cookies
      if (response.headers['set-cookie'] != null) {
        _sessionCookie = response.headers['set-cookie'];
      }

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- LOGOUT ----------------
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/index/login/logout"),
        headers: _authHeaders(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- HEARTBEAT (call every 20 seconds) ----------------
  Future<void> sendHeartbeat() async {
    try {
      await http.post(
        Uri.parse("$baseUrl/rest/other/user/online"),
        headers: _authHeaders(),
      );
    } catch (e) {
      print("Heartbeat error: $e");
    }
  }

  // ---------------- Helper: attach session cookie ----------------
  Map<String, String> _authHeaders() {
    Map<String, String> headers = {"Content-Type": "application/json"};
    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }
    return headers;
  }

  bool get isLoggedIn => _sessionCookie != null;
}