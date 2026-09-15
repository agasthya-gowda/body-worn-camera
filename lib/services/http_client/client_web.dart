import 'package:http/browser_client.dart' as browser_client;
import 'package:http/http.dart' as http;

// The IMS server lives on a different origin than the Flutter web app, so the
// browser only attaches the PHPSESSID cookie set at login if requests are made
// with credentials included. Without this, every authenticated request after
// login silently goes out unauthenticated (browsers also forbid scripts from
// manually setting a `Cookie` header, so re-attaching it by hand never works).
http.Client createHttpClient() => browser_client.BrowserClient()..withCredentials = true;
