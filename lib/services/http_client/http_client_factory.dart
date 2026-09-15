import 'package:http/http.dart' as http;

import 'client_stub.dart' if (dart.library.js_interop) 'client_web.dart' as impl;

http.Client createHttpClient() => impl.createHttpClient();
