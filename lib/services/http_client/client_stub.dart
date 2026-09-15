import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as io_client;

http.Client createHttpClient() {
  final httpClient = HttpClient()
    // The real server uses a self-signed cert; native platforms (unlike
    // the browser) don't need the localhost-proxy trick to work around this,
    // but they do need to explicitly accept this specific server's cert.
    ..badCertificateCallback = (cert, host, port) => host == '116.73.243.111';
  return io_client.IOClient(httpClient);
}
