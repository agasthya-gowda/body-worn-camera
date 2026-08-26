import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // TODO: Replace with real server IP/domain once received from CEO/vendor
  static const String baseUrl = "http://localhost:3000";

  String? _sessionCookie;

  // ---------------- LOGIN ----------------
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // Step 1: MD5 hash the password (32-char lowercase)
      String md5Password = md5.convert(utf8.encode(password)).toString();

      // Step 2: Build the inner JSON (matches vendor's actual working sample exactly)
      Map<String, String> innerJson = {
        "username": username,
        "password": md5Password,
        "key": "",
      };

      // Step 3: Base64-encode directly (vendor's own sample proves NO URL-encoding is used,
      // despite their written instructions saying otherwise)
      String jsonString = jsonEncode(innerJson);
      String loginInfo = base64Encode(utf8.encode(jsonString));

      // Step 4: Send request
      final response = await http.post(
        Uri.parse("$baseUrl/rest/index/login/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"login_info": loginInfo}),
      );

      // Step 5: Extract PHPSESSID from cookies (parse clean value, per doc para 50)
      if (response.headers['set-cookie'] != null) {
        String rawCookie = response.headers['set-cookie']!;
        // Extract only "PHPSESSID=value" part, ignoring extra attributes like path/HttpOnly
        RegExp regex = RegExp(r'PHPSESSID=[^;]+');
        Match? match = regex.firstMatch(rawCookie);
        if (match != null) {
          _sessionCookie = match.group(0);
        }
      }

      final data = jsonDecode(response.body);
      return data;
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // LOGOUT
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/index/login/logout"),
        headers: _authHeaders(),
      );
      // Also clear the platform heartbeat (per doc: /rest/other/user/del_online, GET)
      await clearHeartbeat();
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // CLEAN/CLEAR HEARTBEAT (call once on logout, per API doc)
  Future<void> clearHeartbeat() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rest/other/user/del_online"),
        headers: _authHeaders(),
      );
      final data = jsonDecode(response.body);
      if (data['code'] == 200) {
        print("Clear heartbeat succeeded: ${data['msg']}");
      } else {
        print("Clear heartbeat failed: ${data['msg']}");
      }
    } catch (e) {
      print("Clear heartbeat error: $e");
    }
  }

  // ---------------- HEARTBEAT (call every 20 seconds) ----------------
  Future<bool> sendHeartbeat() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/rest/other/user/online"),
        headers: _authHeaders(),
      );
      final data = jsonDecode(response.body);
      if (data['code'] == 200) {
        return true;
      } else {
        print("Heartbeat failed: ${data['msg']}");
        return false;
      }
    } catch (e) {
      print("Heartbeat error: $e");
      return false;
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

  // ---------------- ONLINE DEVICE LIST ----------------
  Future<Map<String, dynamic>> getOnlineDevices() async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/other/unitjson/gdlist"),
        headers: _authHeaders(),
        // Doc's 6.2 spec requires these exact fixed fields (bh="bh", text="dname")
        body: jsonEncode({"bh": "bh", "text": "dname"}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- DEVICE DETAIL INQUIRY (battery, storage, signal) ----------------
  Future<Map<String, dynamic>> getDeviceDetail(String imei, String hostbody) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismoni/get_devicedetail"),
        headers: _authHeaders(),
        body: jsonEncode({"imei": imei, "hostbody": hostbody}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- START VIDEO CALL (per doc: Realtime Streaming APIs) ----------------
  // Success response: data is a List of stream info objects
  // Error response (code 400): data is an Object with error_hostbody, error_code, err_msg, success_data
  Future<Map<String, dynamic>> startVideoCall(List<String> hostbodyList) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/live/chrome/startLive"),
        headers: _authHeaders(),
        body: jsonEncode({"hostbody_arr": hostbodyList}),
      );
      final result = jsonDecode(response.body);

      if (result['code'] == 200) {
        // Success case: data is a List
        return {
          "code": 200,
          "msg": result['msg'],
          "streams": List<Map<String, dynamic>>.from(result['data'] ?? []),
          "failedDevices": <Map<String, dynamic>>[],
        };
      } else {
        // Error case: data is an Object with partial success info
        final errorData = result['data'] ?? {};
        final successList = List<Map<String, dynamic>>.from(errorData['success_data'] ?? []);
        final errorHostbodies = List<String>.from(errorData['error_hostbody'] ?? []);
        final errorMsgs = List<String>.from(errorData['err_msg'] ?? []);
        final errorCodes = List<dynamic>.from(errorData['error_code'] ?? []);
        List<Map<String, dynamic>> failedDevices = [];
        for (int i = 0; i < errorHostbodies.length; i++) {
          failedDevices.add({
            "hostbody": errorHostbodies[i],
            "err_msg": i < errorMsgs.length ? errorMsgs[i] : "Unknown error",
            "error_code": i < errorCodes.length ? errorCodes[i] : 0,
          });
        }
        return {
          "code": result['code'],
          "msg": result['msg'],
          "streams": successList,
          "failedDevices": failedDevices,
        };
      }
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e", "streams": [], "failedDevices": []};
    }
  }

  // ---------------- STOP VIDEO CALL ----------------
  Future<Map<String, dynamic>> stopVideoCall(List<String> hostbodyList) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/live/chrome/stopLive"),
        headers: _authHeaders(),
        body: jsonEncode({"hostbody_arr": hostbodyList}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- START AUDIO CALL ----------------
  // Same success/error response shape as Start Video Call
  Future<Map<String, dynamic>> startAudioCall(List<String> hostbodyList) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/live/chrome/startAudio"),
        headers: _authHeaders(),
        body: jsonEncode({"hostbody_arr": hostbodyList}),
      );
      final result = jsonDecode(response.body);

      if (result['code'] == 200) {
        return {
          "code": 200,
          "msg": result['msg'],
          "streams": List<Map<String, dynamic>>.from(result['data'] ?? []),
          "failedDevices": <Map<String, dynamic>>[],
        };
      } else {
        final errorData = result['data'] ?? {};
        final successList = List<Map<String, dynamic>>.from(errorData['success_data'] ?? []);
        final errorHostbodies = List<String>.from(errorData['error_hostbody'] ?? []);
        final errorMsgs = List<String>.from(errorData['err_msg'] ?? []);
        final errorCodes = List<dynamic>.from(errorData['error_code'] ?? []);
        List<Map<String, dynamic>> failedDevices = [];
        for (int i = 0; i < errorHostbodies.length; i++) {
          failedDevices.add({
            "hostbody": errorHostbodies[i],
            "err_msg": i < errorMsgs.length ? errorMsgs[i] : "Unknown error",
            "error_code": i < errorCodes.length ? errorCodes[i] : 0,
          });
        }
        return {
          "code": result['code'],
          "msg": result['msg'],
          "streams": successList,
          "failedDevices": failedDevices,
        };
      }
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e", "streams": [], "failedDevices": []};
    }
  }

  // ---------------- STOP AUDIO CALL ----------------
  Future<Map<String, dynamic>> stopAudioCall(List<String> hostbodyList, List<String> wsChannelIdList) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/live/chrome/stopAudio"),
        headers: _authHeaders(),
        body: jsonEncode({"hostbody_arr": hostbodyList, "wsChannelId_arr": wsChannelIdList}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- SEND COMMAND (mute/unmute, and later photo/video/restart) ----------------
  // Per doc: /rest/gis/gismoni/send_cmd - generic command endpoint, "type" determines action
  Future<Map<String, dynamic>> sendCommand(String imei, String type) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismoni/send_cmd"),
        headers: _authHeaders(),
        body: jsonEncode({"imei": imei, "type": type}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- REGISTER NEW USER (multipart/form-data per doc) ----------------
  // Note: pe_signals omitted per vendor's confirmation - it's for internal use only
  Future<Map<String, dynamic>> registerUser({
    required String hostcode,
    required String realname,
    required String bh,
    required String type,
    String? mobile,
    String? tel,
    String? sort,
    String? note,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/rest/user/police/add"),
      );
      request.headers.addAll(_authHeaders());
      request.fields['hostcode'] = hostcode;
      request.fields['realname'] = realname;
      request.fields['bh'] = bh;
      request.fields['type'] = type;
      if (mobile != null) request.fields['mobile'] = mobile;
      if (tel != null) request.fields['tel'] = tel;
      if (sort != null) request.fields['sort'] = sort;
      if (note != null) request.fields['note'] = note;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Connection error: $e"};
    }
  }

  // ---------------- REMOTE CONTROL APIS (Section 5) ----------------

  // 5.1 Remote Take Photo
  Future<Map<String, dynamic>> takePhoto(String imei) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismoni/send_cmd"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": _sessionCookie ?? '',
        },
        body: jsonEncode({
          "imei": imei,
          "type": "takephoto",
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Error: $e"};
    }
  }

  // 5.1 Remote Start Video Recording
  Future<Map<String, dynamic>> startRemoteVideo(String imei) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismoni/send_cmd"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": _sessionCookie ?? '',
        },
        body: jsonEncode({
          "imei": imei,
          "type": "startvideo",
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Error: $e"};
    }
  }

  // 5.2 Remote Restart Device
  Future<Map<String, dynamic>> remoteRestart({
    required String imei,
    required String hostbody,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismoni/send_restart"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": _sessionCookie ?? '',
        },
        body: jsonEncode({
          "imei": imei,
          "hostbody": hostbody,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Error: $e"};
    }
  }

  // 5.3 User Info Inquiry (Bulk - matches doc's array-based format exactly)
  Future<Map<String, dynamic>> getDeviceDetailsBulk(List<String> ids) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/gis/gismoni/get_devicedetail"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": _sessionCookie ?? '',
        },
        body: jsonEncode({"ids": ids}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Error: $e"};
    }
  }

  // ---------------- DEVICE APIS (Section 6) ----------------

  // 6.1 Add New Device
  Future<Map<String, dynamic>> addDevice({
    required String bh,
    required String hostbody,
    required String recorderType,
    required String typesn,
    String? productFirm,
    String? capacity,
    String? version,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/device/device/add"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": _sessionCookie ?? '',
        },
        body: jsonEncode({
          "bh": bh,
          "hostbody": hostbody,
          "recorder_type": recorderType,
          "typesn": typesn,
          if (productFirm != null) "product_firm": productFirm,
          if (capacity != null) "capacity": capacity,
          if (version != null) "version": version,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Error: $e"};
    }
  }

  // 6.3 All Device List (search/filter all devices)
  Future<Map<String, dynamic>> getAllDeviceList({
    String? hostkey,
    String? hostbody,
    String? bh,
    String? state,
    String? devicetype,
    int pageSize = 20,
    int curPage = 1,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/device/device/devicelist"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": _sessionCookie ?? '',
        },
        body: jsonEncode({
          if (hostkey != null) "hostkey": hostkey,
          if (hostbody != null) "hostbody": hostbody,
          if (bh != null) "bh": bh,
          if (state != null) "state": state,
          if (devicetype != null) "devicetype": devicetype,
          "page_size": pageSize,
          "cur_page": curPage,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Error: $e"};
    }
  }

  // 6.4 Modify Device
  Future<Map<String, dynamic>> modifyDevice({
    required String id,
    required String bh,
    required String recorderType,
    required String typesn,
    String? productFirm,
    String? capacity,
    String? version,
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/device/device/saveedit"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": _sessionCookie ?? '',
        },
        body: jsonEncode({
          "id": id,
          "bh": bh,
          "recorder_type": recorderType,
          "typesn": typesn,
          if (productFirm != null) "product_firm": productFirm,
          if (capacity != null) "capacity": capacity,
          if (version != null) "version": version,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Error: $e"};
    }
  }

  // 6.5 Delete Device
  Future<Map<String, dynamic>> deleteDevice(String id) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/rest/device/device/del"),
        headers: {
          "Content-Type": "application/json",
          "Cookie": _sessionCookie ?? '',
        },
        body: jsonEncode({"id": id}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"code": 500, "msg": "Error: $e"};
    }
  }

  bool get isLoggedIn => _sessionCookie != null;
}