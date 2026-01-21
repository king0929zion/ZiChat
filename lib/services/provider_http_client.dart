import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:zichat/models/api_config.dart';

class ProviderHttpClient {
  static http.Client create(ApiConfig config) {
    final proxy = config.proxy;
    if (!proxy.enabled) return http.Client();

    final ioClient = HttpClient()
      ..findProxy = (_) => 'PROXY ${proxy.address}:${proxy.port}';

    final username = (proxy.username ?? '').trim();
    final password = (proxy.password ?? '').trim();
    if (username.isNotEmpty && password.isNotEmpty) {
      ioClient.authenticateProxy = (host, port, scheme, realm) async {
        ioClient.addProxyCredentials(
          host,
          port,
          realm ?? '',
          HttpClientBasicCredentials(username, password),
        );
        return true;
      };
    }

    return IOClient(ioClient);
  }
}
